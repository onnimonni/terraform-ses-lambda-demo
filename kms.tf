data "aws_iam_policy_document" "allow_ses_to_use_reports_kms"{

  # Allow aws root to modify this key
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }

  # Allows our SES service to use the kms key when our account uses this
  statement {
    sid = "AllowSESToUseKms"
    principals {
      type = "Service"
      identifiers = [
        "ses.amazonaws.com"
      ]
    }
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
    "*"
    ]
   # These were copied from: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/receiving-email-permissions.html
   condition {
     test     = "Null"
     variable = "kms:EncryptionContext:aws:ses:rule-name"
     values = [ "false" ]
   }
   condition {
     test     = "Null"
     variable = "kms:EncryptionContext:aws:ses:message-id"
     values = [ "false" ]
   }
   condition {
     test     = "StringEquals"
     variable = "kms:EncryptionContext:aws:ses:source-account"
     values = [ "${data.aws_caller_identity.current.account_id}" ]
   }
  }
}

resource "aws_kms_key" "reports" {
  provider = "aws.for_ses"
  description = "This key is used to encrypt '${var.aws_reports_bucket_name}' bucket"

  # Give SES access to this kms key
  policy = "${data.aws_iam_policy_document.allow_ses_to_use_reports_kms.json}"

  # If this kms key is deleted, wait 30 days until it's really deleted in aws
  deletion_window_in_days = 30

  tags = "${var.default_tags}"
}

resource "aws_kms_alias" "reports" {
  name          = "alias/${var.aws_reports_bucket_name}-bucket-encryption"
  target_key_id = "${aws_kms_key.reports.key_id}"
}
