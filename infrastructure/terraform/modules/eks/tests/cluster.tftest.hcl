################################################################################
# EKS Module Tests — IAM Roles, Autoscaler, LB Controller, ESO
################################################################################

mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.cluster_autoscaler_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::oidc-provider/test\"},\"Action\":\"sts:AssumeRoleWithWebIdentity\"}]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.lb_controller_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::oidc-provider/test\"},\"Action\":\"sts:AssumeRoleWithWebIdentity\"}]}"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.eso_assume
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::oidc-provider/test\"},\"Action\":\"sts:AssumeRoleWithWebIdentity\"}]}"
    }
  }
}

mock_provider "helm" {}

override_resource {
  target = helm_release.cluster_autoscaler
  values = {}
}

override_resource {
  target = helm_release.external_secrets
  values = {}
}

override_module {
  target = module.eks
  outputs = {
    cluster_name              = "cobalt-dev"
    cluster_version           = "1.28"
    cluster_endpoint          = "https://eks.example.com"
    oidc_provider_arn         = "arn:aws:iam::oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/TEST"
    cluster_oidc_issuer_url   = "https://oidc.eks.us-east-1.amazonaws.com/id/TEST"
    cluster_security_group_id = "sg-mock123"
    eks_managed_node_groups = {
      default = {
        iam_role_arn   = "arn:aws:iam::123456789012:role/cobalt-dev-node-group"
        instance_types = ["t3.medium"]
        tags = {
          "k8s.io/cluster-autoscaler/enabled"    = "true"
          "k8s.io/cluster-autoscaler/cobalt-dev" = "owned"
        }
      }
    }
  }
}

variables {
  environment               = "dev"
  vpc_id                    = "vpc-test123"
  subnet_ids                = ["subnet-a", "subnet-b", "subnet-c"]
  cluster_name              = "cobalt-dev"
  secrets_access_policy_arn = "arn:aws:iam::123456789012:policy/test-secrets-access"
}

run "cluster_autoscaler_role_created" {
  command = plan

  assert {
    condition     = aws_iam_role.cluster_autoscaler.name == "cobalt-dev-cluster-autoscaler"
    error_message = "Cluster autoscaler IAM role should be created"
  }
}

run "lb_controller_role_created" {
  command = plan

  assert {
    condition     = aws_iam_role.lb_controller.name == "cobalt-dev-lb-controller"
    error_message = "LB controller IAM role should be created"
  }
}

run "eso_role_created" {
  command = plan

  assert {
    condition     = aws_iam_role.eso.name == "cobalt-dev-external-secrets"
    error_message = "External Secrets Operator IAM role should be created"
  }
}

run "lb_controller_policy_created" {
  command = plan

  assert {
    condition     = aws_iam_policy.lb_controller.name == "cobalt-dev-lb-controller"
    error_message = "LB controller IAM policy should be created"
  }
}
