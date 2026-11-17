variable "container_name" {
  description = "Value of the name for the Docker container"
  type        = string
  default     = "ExampleNginxContainer"
}

variable "external_port" {
  description = "Value of the port number; Used for port forwarding"
  type        = number
  default     = 8000
}

