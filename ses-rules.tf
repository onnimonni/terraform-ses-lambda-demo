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
    position = "1"
    object_key_prefix = "emails/"
  }

  stop_action {
    scope    = "RuleSet"
    position = "2"
  }

  # Wait until we have the bucket that this rule needs
  depends_on = ["aws_s3_bucket.reports","aws_s3_bucket_policy.reports"]
}
