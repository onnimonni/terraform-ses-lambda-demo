##
# This file defines the s3 buckets used for reports
##

variable "aws_reports_bucket_name" {}

resource "aws_s3_bucket" "reports" {
    provider = "aws.for_ses"
    bucket   = "${var.aws_reports_bucket_name}"
    region   = "eu-west-1"
    acl      = "private"

    # When objects are overwritten don't preserve the earlier versions just in case
    versioning {
      enabled = true
    }

    # Enable encryption with KMS key
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = "${aws_kms_key.reports.arn}"
          sse_algorithm     = "aws:kms"
        }
      }
    }

    # Never expire/delete anything from these buckets
    lifecycle_rule {
      prefix = ""
      enabled = false

      # Move old reports to cheaper storage after they are not needed
      transition {
        # 5 years
        days = 1825
        storage_class = "GLACIER"
      }
      noncurrent_version_transition {
        # 5 years
        days = 1825
        storage_class = "GLACIER"
      }
    }
}

data "aws_iam_policy_document" "allow_ses_to_write_s3" {

  # Allow ses to write into s3 bucket
  statement {
    sid = "AllowSESToWriteIntoReportsBucket"
    principals {
      type = "Service"
      identifiers = [
        "ses.amazonaws.com"
      ]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.reports.id}/emails/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:Referer"
      values = [ "${data.aws_caller_identity.current.account_id}" ]
    }
  }
}

resource "aws_s3_bucket_policy" "reports" {
  bucket ="${aws_s3_bucket.reports.id}"
  policy   = "${data.aws_iam_policy_document.allow_ses_to_write_s3.json}"
}
