# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region

  # Point the provider at Floci (local AWS emulator) instead of real AWS.
  # Floci accepts any credentials; "test"/"test" is the convention.
  access_key = "test"
  secret_key = "test"

  # Skip calls that only make sense against real AWS.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Floci serves S3 at localhost:4566/<bucket>, not <bucket>.localhost:4566
  s3_use_path_style = true

  endpoints {
    s3  = var.aws_endpoint
    ec2 = var.aws_endpoint
    sts = var.aws_endpoint
    iam = var.aws_endpoint
  }
}

provider "random" {}

provider "time" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "random_pet" "instance" {
  length = 2
}

resource "aws_instance" "main" {
  count = 3

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name  = "${random_pet.instance.id}-${count.index}"
    Owner = "${var.project_name}-tutorial"
  }
}

resource "aws_s3_bucket" "firstbucket" {
  tags = {
    Name  = "Example S3 Bucket"
    Owner = "${var.project_name}-tutorial"
  }
}

# Renamed aws_s3_bucket.bucket -> aws_s3_bucket.firstbucket.
# Tells Terraform it's the same bucket, so it updates the state address
# instead of destroying and recreating the bucket.
# # moved {
#   from = aws_s3_bucket.bucket
#   to   = aws_s3_bucket.firstbucket
# }

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.firstbucket.bucket

  key    = "README.md"
  source = "./README.md"

  etag = filemd5("./README.md")
}

module "ec2-instance" {
  source = "./modules/aws-ec2-instance"

  ami_id        = data.aws_ami.ubuntu.id
  instance_name = random_pet.instance.id
}

module "hello" {
  source  = "joatmon08/hello/random"
  version = "6.0.0"

  hellos = {
    hello = random_pet.instance.id
    second_hello = "World"
  }

  some_key = var.secret_key
}
