variable "region" {
  description = "AWS region where ressources will be created"
  type        = string
  default     = "eu-west-3"  
}

variable "instance_type" {
  description = "EC2 instance type to launch"
  type        = string
  default     = "t3.micro"  
}

variable "project_name" {
  description = "Name used to prefix and tag all resources"
  type        = string
  default     = "devsecops"  
}

variable "my_ip" {
  description = "Operator's public IP (CIDR format) allowed to SSH into the instance"
  type        = string
}
