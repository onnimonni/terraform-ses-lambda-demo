# This lets us operate on behalf of the lambda service, it is not a standard IAM policy document.
data "template_file" "policy_allow_lambda_json" {
  template = "${file("${path.module}/iam-policies/allow-lambda.json")}"
}

# This allows attached lambda role to write logs
data "template_file" "policy_allow_lambda_logging_json" {
  template = "${file("${path.module}/iam-policies/allow-lambda-logging.json")}"
}
