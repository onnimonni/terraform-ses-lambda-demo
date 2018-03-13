##
# This file builds the zip archive which is deployed into lambda service
##

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
    # FIXME: Force out/ directory for tsc no matter the tsconfig
    # FIXME: Do this in a module and a different script file which takes the lambda path as a parameter
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
  output_path = "${path.root}/tmp/ses-lambda.zip"
  source_dir  = "${local.lambda_path}/out"

  depends_on = ["null_resource.npm"]
}
