# Role for s3 mail attachment lambda
resource "aws_iam_role" "lambda_s3_mail" {
  description = "AssumeRole and Execution permissions for the SES lambda function"
  path = "/service-role/"
  name = "${replace(aws_ses_domain_identity.reports_domain.domain, ".", "-")}-lambda_s3_mail"
  assume_role_policy = "${data.template_file.policy_allow_lambda_json.rendered}"
}

# Attach logging policy to lambda role
resource "aws_iam_role_policy" "lambda_write_logs_policy" {
  name = "lambda_write_logs_policy"
  role = "${aws_iam_role.lambda_s3_mail.id}"
  policy = "${data.template_file.policy_allow_lambda_logging_json.rendered}"
}
