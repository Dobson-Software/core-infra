terraform {
  backend "s3" {
    bucket         = "cobalt-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cobalt-terraform-locks"
    encrypt        = true
  }
}
