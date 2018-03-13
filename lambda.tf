locals {
  lambda_path    = "${var.lambda_path == "false" ? "${path.module}/lambda" : var.lambda_path}"
}

resource "aws_lambda_function" "s3_mail_handling" {
  filename      = "${data.archive_file.ses_handler_zip.output_path}"
  function_name = "${replace(aws_ses_domain_identity.reports_domain.domain, ".", "-")}-ses_handler"
  handler       = "index.handler"
  role          = "${aws_iam_role.lambda_s3_mail.arn}"
  kms_key_arn   = "${aws_kms_key.reports.arn}"

  environment {
    variables = {
      AWS_S3_BUCKET       = "${aws_s3_bucket.reports.id}"
    }
  }

  source_code_hash = "${data.archive_file.ses_handler_zip.output_base64sha256}"

  runtime = "nodejs6.10"
  timeout = "10"

  lifecycle {
    create_before_destroy = "true"
  }
}
