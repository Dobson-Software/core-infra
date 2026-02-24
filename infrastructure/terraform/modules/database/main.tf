terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.us_west_2]
    }
  }
}

################################################################################
# Database Module — RDS PostgreSQL Primary + Read Replica
################################################################################

resource "aws_db_subnet_group" "cobalt" {
  name       = "cobalt-${var.environment}"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "cobalt-${var.environment}-db-subnet"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "cobalt-rds-${var.environment}-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  tags = {
    Name        = "cobalt-rds-${var.environment}"
    Environment = var.environment
  }
}

################################################################################
# Enhanced Monitoring IAM Role
################################################################################

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "cobalt-${var.environment}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

################################################################################
# Parameter Group
################################################################################

resource "aws_db_parameter_group" "cobalt" {
  name   = "cobalt-${var.environment}-pg15"
  family = "postgres15"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "pg_stat_statements.track"
    value = "all"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Environment = var.environment
  }
}

################################################################################
# Primary RDS Instance
################################################################################

resource "aws_db_instance" "primary" {
  identifier = "cobalt-${var.environment}"

  engine         = "postgres"
  engine_version = "15"
  instance_class = coalesce(var.instance_class, var.environment == "prod" ? "db.r6g.large" : "db.t4g.micro")

  allocated_storage     = 20
  max_allocated_storage = var.environment == "prod" ? 500 : 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn != "" ? var.kms_key_arn : null

  db_name  = "cobalt"
  username = "cobalt"
  manage_master_user_password = true
  master_user_secret_kms_key_id = var.kms_key_arn

  multi_az               = var.enable_multi_az != null ? var.enable_multi_az : (var.environment == "prod")
  db_subnet_group_name   = aws_db_subnet_group.cobalt.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.cobalt.name

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  performance_insights_enabled = true
  backup_retention_period      = var.environment == "prod" ? 30 : 7
  preferred_backup_window      = var.preferred_backup_window
  skip_final_snapshot          = var.environment != "prod"
  final_snapshot_identifier    = var.environment == "prod" ? "cobalt-${var.environment}-final" : null
  deletion_protection          = var.environment == "prod"

  ca_cert_identifier = "rds-ca-rsa2048-g1"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Environment = var.environment
    Module      = "database"
  }
}

################################################################################
# Read Replica (prod only)
################################################################################

resource "aws_db_instance" "read_replica" {
  count = (var.enable_read_replica != null ? var.enable_read_replica : (var.environment == "prod")) ? 1 : 0

  identifier          = "cobalt-${var.environment}-replica"
  replicate_source_db = aws_db_instance.primary.identifier

  instance_class    = "db.r6g.large"
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.cobalt.name
  ca_cert_identifier     = "rds-ca-rsa2048-g1"

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_enhanced_monitoring.arn
  performance_insights_enabled = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = true

  tags = {
    Environment = var.environment
    Module      = "database"
    Role        = "read-replica"
  }
}

################################################################################
# Cross-Region Snapshot Copy (prod only)
################################################################################

resource "aws_db_instance_automated_backups_replication" "cross_region" {
  count = var.environment == "prod" ? 1 : 0

  source_db_instance_arn = aws_db_instance.primary.arn
  kms_key_id             = var.kms_key_arn != "" ? var.kms_key_arn : null
  retention_period       = 14

  provider = aws.us_west_2
}
