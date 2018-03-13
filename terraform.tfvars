root_domain = "playground.vuola.io"

default_tags = {
  who-knows-about-this = "onni.hakala@checkout.fi"
  description = "SES setup to send attachments from emails to s3"
  managed-by = "terraform"
}

# Name for the email bucket
aws_reports_bucket_name = "co-partner-reports"

# SES only works here in Europe
aws_region = "eu-west-1"
