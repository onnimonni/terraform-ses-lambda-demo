variable "aws_region" {
  default = "eu-west-1"
}

provider "aws" {
  alias  = "for_ses"
  region = "${var.aws_region}"
}

# You can use this to get current AWS account id
data "aws_caller_identity" "current" {}

output "aws_account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}
output "aws_region" {
  value = "${var.aws_region}"
}

