# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  type        = string
  description = "AWS region for all resources."

  default = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the example project."

  default = "terraform-init"
}

variable "aws_endpoint" {
  type        = string
  description = "Endpoint for AWS API calls (Floci local emulator)."

  default = "http://localhost:4566"
}

variable "secret_key" {
  type        = string
  sensitive   = true
  description = "A secret key for the hello module."
}
