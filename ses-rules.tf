# Store email in S3
resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = "report-email-rules"
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = "report-email-rules"
  depends_on    = ["aws_ses_receipt_rule_set.main"]
}

resource "aws_ses_receipt_rule" "main" {
  name          = "store-to-s3"
  rule_set_name = "report-email-rules"
  #recipients    = ["karen@example.com"]
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name = "${aws_s3_bucket.reports.bucket}"
    # If you some wanted to encrypt
    #kms_key_arn = "${aws_kms_key.reports.arn}"
    position = "1"
    object_key_prefix = "emails/"
  }

  lambda_action {
    function_arn    = "${aws_lambda_function.ses_handling.arn}"
    invocation_type = "Event"
    position        = "3"
  }

  bounce_action {
    message         = "This is an unattended mailbox, your message has been discarded."
    sender          = "postmaster@reports.playground.vuola.io"
    smtp_reply_code = "550"
    status_code     = "5.5.1"
    position        = "3"
  }

  stop_action {
    scope    = "RuleSet"
    position = "4"
  }

  # Wait until we have the bucket that this rule needs
  depends_on = ["aws_s3_bucket.reports","aws_s3_bucket_policy.reports","aws_lambda_permission.allow_ses"]
}

# Allow SES to start this lambda
resource "aws_lambda_permission" "allow_ses" {
  statement_id   = "AllowExecutionFromSES"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.ses_handling.function_name}"
  source_account = "${data.aws_caller_identity.current.account_id}"
  principal      = "ses.amazonaws.com"
}
