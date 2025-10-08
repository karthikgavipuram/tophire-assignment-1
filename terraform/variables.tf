# terraform/variables.tf
variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in."
  default     = "us-east-1"
}

variable "ami_id" {
  description = "The AMI ID for the Ubuntu 22.04 server."
  default     = "ami-053b0d53c27927909" # Example for us-east-1, verify latest Ubuntu 22.04 AMI
}

variable "instance_type" {
  description = "The instance type for the Kubernetes master node."
  default     = "t2.medium"
}

variable "key_name" {
  description = "The name of the pre-existing AWS Key Pair for SSH access."
  default     = "k8s-ssh-key" # Must match your key name
}

variable "public_key_path" {
  description = "Local path to the public SSH key."
  default     = "~/.ssh/id_rsa.pub"
}