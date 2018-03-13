locals {
  lambda_path    = "${var.lambda_path == "false" ? "${path.module}/lambda" : var.lambda_path}"
}

# Create a zip from lambda folder
provider "archive" {
  version = "~> 1.0"
}

# This is used to trigger builds from local changes
provider "null" {
  version = "~> 1.0"
}

resource "null_resource" "npm" {
  triggers {
    index_js     = "${base64sha256(file("${local.lambda_path}/src/index.ts"))}"
    package_json = "${base64sha256(file("${local.lambda_path}/package.json"))}"
  }

  provisioner "local-exec" {
  command = <<EOT
    pushd ${local.lambda_path} && \
    npm install && \
    ./node_modules/.bin/tsc && \
    cp package*.json out/ && \
    cd out && \
    npm install --production && \
    popd
EOT
  }
}

data "archive_file" "ses_handler_zip" {
  type        = "zip"
  output_path = "${path.root}/ses-lambda.zip"
  source_dir  = "${local.lambda_path}/out"

  depends_on = ["null_resource.npm"]
}

# This is the bucket policy document, not an IAM policy document
data "aws_iam_policy_document" "ses_s3_action_doc" {
  policy_id = "SESActionS3"

  statement {
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reports.id}/*"]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:Referer"

      values = [
        "${data.aws_caller_identity.current.account_id}",
      ]
    }
  }
}

resource "aws_lambda_function" "ses_handling" {
  filename      = "${data.archive_file.ses_handler_zip.output_path}"
  function_name = "${replace(aws_ses_domain_identity.reports_domain.domain, ".", "_")}-ses_handler"
  handler       = "index.handler"
  role          = "${aws_iam_role.ses_reports_lambda_role.arn}"
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

# Aside from the assume_role_policy document execution permissions
# are defined and attached in their respective *_perms.tf
resource "aws_iam_role" "ses_reports_lambda_role" {
  description           = "AssumeRole and Execution permissions for the SES lambda function"
  name                  = "ReportsSESLambdaRole"
  path                  = "/service-role/"
  assume_role_policy    = "${data.aws_iam_policy_document.assume_lambda_role_doc.json}"
}

# The assume role policy document referenced above.
# This lets us operate on behalf of the lambda service, it is not a standard
# IAM policy document.
data "aws_iam_policy_document" "assume_lambda_role_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Attach logging policy to lambda role
resource "aws_iam_role_policy" "lambda_write_logs_policy" {
  name = "lambda_write_logs_policy"
  role = "${aws_iam_role.ses_reports_lambda_role.id}"
  policy = "${data.aws_iam_policy_document.lambda_logging_role_doc.json}"
}

# This gives access for lambda to write into logs
data "aws_iam_policy_document" "lambda_logging_role_doc" {

  # Allow Lambda to create logging group and write logs to the group
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}
