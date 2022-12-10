variable "region" {
  description = "AWS region"
  type        = string
  nullable    = false
  default     = "us-west-2"
}

variable "email" {
  description = "Email which will get a report from Lambda function"
  type        = string
  nullable    = false
  default     = ""
}

variable "compliant_amis" {
  description = "List of compliant AMI"
  type        = list(string)
  nullable    = false
  default     = []
}
