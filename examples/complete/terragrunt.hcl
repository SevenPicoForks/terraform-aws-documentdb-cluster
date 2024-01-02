locals {
  account_id = get_aws_account_id()
  tenant     = "Brim"

  region      = get_env("AWS_REGION")
  root_domain = "modules.thebrim.io"

  namespace   = "brim"
  project     = "ddb-events"
  environment = ""
  stage       = basename(get_terragrunt_dir()) //
  domain_name = "${local.stage}.${local.project}.${local.root_domain}"

  tags                = { Source = "Managed by Terraform" }
  regex_replace_chars = "/[^-a-zA-Z0-9]/"
  delimiter           = "-"
  replacement         = ""
  id_length_limit     = 0
  id_hash_length      = 5
  label_key_case      = "title"
  label_value_case    = "lower"
  label_order         = ["namespace", "project", "environment", "stage", "name", "attributes"]
  dns_name_format     = "$${name}.$${domain_name}"
}

inputs = {
  root_domain = local.root_domain

  # Standard Context
  region              = local.region
  tenant              = local.tenant
  project             = local.project
  domain_name         = local.domain_name
  project             = local.project
  namespace           = local.namespace
  environment         = local.environment
  stage               = local.stage
  tags                = local.tags
  regex_replace_chars = local.regex_replace_chars
  delimiter           = local.delimiter
  replacement         = local.replacement
  id_length_limit     = local.id_length_limit
  id_hash_length      = local.id_hash_length
  label_key_case      = local.label_key_case
  label_value_case    = local.label_value_case
  label_order         = local.label_order
  dns_name_format     = local.dns_name_format

  # Module / Example Specific
  enabled                 = true
  region                  = "us-east-2"
  availability_zones      = ["us-east-2a", "us-east-2b"]
  namespace               = "eg"
  stage                   = "test"
  name                    = "documentdb-cluster"
  vpc_cidr_block          = "172.16.0.0/16"
  instance_class          = "db.r4.large"
  cluster_size            = 1
  db_port                 = 27017
  master_username         = "admin1"
  master_password         = "password1"
  retention_period        = 5
  preferred_backup_window = "07:00-09:00"
  cluster_family          = "docdb3.6"
  engine                  = "docdb"
  storage_encrypted       = true
  skip_final_snapshot     = true
  apply_immediately       = true
}

remote_state {
  backend      = "s3"
  disable_init = false
  config = {
    bucket                = "brim-sandbox-tfstate"
    disable_bucket_update = true
    dynamodb_table        = "brim-sandbox-tfstate-lock"
    encrypt               = true
    key                   = "${local.account_id}/${local.project}/${local.stage}/terraform.tfstate"
    region                = local.region
  }
  generate = {
    path      = "generated-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "providers" {
  path      = "generated-providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 4"
      }
      awscc = {
        source  = "hashicorp/awscc"
        version = "0.67.0"
      }
      local = {
        source  = "hashicorp/local"
      }
      acme = {
        source  = "vancluever/acme"
        version = "~> 2.8.0"
      }
    }
  }

  provider "aws" {
    region  = "${local.region}"
  }

  provider "awscc" {
      region  = "${local.region}"
    }

  provider "acme" {
    server_url = "https://acme-v02.api.letsencrypt.org/directory"
  }
  EOF
}
