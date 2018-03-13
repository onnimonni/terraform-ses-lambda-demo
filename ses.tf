##
# Variables which can be changed in terraform.tfvars
##

# Zone which we use to create reports ses system
variable "root_domain" {
  type = "string"
}

# Tags which we use to notify others of this project
variable "default_tags" {
  type = "map"
  default = {}
}

##
# Create the domain
##
data "aws_route53_zone" "main" {
  name = "${var.root_domain}." # The last dot is here on purpose

  # Example for tags:
  #tags = "${merge(var.default_tags, map("Name", "my resource"))}"
}

##
# Enable SES and verify the domain
##
resource "aws_ses_domain_identity" "reports_domain" {
  provider = "aws.for_ses"
  domain = "reports.${var.root_domain}"
}

# FIXME: Point this into static page which documents the mail attachments feature
resource "aws_route53_record" "reports_domain" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${aws_ses_domain_identity.reports_domain.domain}"
  type    = "A"
  ttl     = "300"
  records = ["127.0.0.1"]
}

# FIXME: Currently there's no better way to define MX records for SES
# Source: https://github.com/terraform-providers/terraform-provider-aws/issues/1627
resource "aws_route53_record" "reports_amazonses_mx_record" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name = "${aws_ses_domain_identity.reports_domain.domain}"
  type = "MX"
  ttl = "1800"
  records = ["10 inbound-smtp.${var.aws_region}.amazonaws.com"]
}

resource "aws_route53_record" "reports_amazonses_verification_record" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "_amazonses.${aws_route53_record.reports_domain.name}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.reports_domain.verification_token}"]
}

##
# DKIM: Generate keys and add them into domain dkim records
##
resource "aws_ses_domain_dkim" "reports_domain" {
  domain = "${aws_ses_domain_identity.reports_domain.domain}"
}

resource "aws_route53_record" "report_domain_dkim_record" {
  count   = 3
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${element(aws_ses_domain_dkim.reports_domain.dkim_tokens, count.index)}._domainkey.${aws_route53_record.reports_domain.name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.reports_domain.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

##
# SPF: Add record which allows our domain as sender from spf
##
resource "aws_route53_record" "reports_ses_domain_mail_from_txt" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${aws_route53_record.reports_domain.name}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}


