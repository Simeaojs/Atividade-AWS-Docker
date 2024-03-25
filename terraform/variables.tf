variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"

}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-07761f3ae34c4478d"

}

variable "keyname" {
  default = "devops"
}