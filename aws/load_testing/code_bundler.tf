resource "terraform_data" "load_testing_lambda_package_dependencies" {
  triggers_replace = [
    filesha256("${path.module}/lambda-code/requirements.txt")
  ]

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf "${path.module}/load-testing-lambda-package-dependencies"
      mkdir -p "${path.module}/load-testing-lambda-package-dependencies/python"

      docker run --rm \
        --platform linux/amd64 \
        --entrypoint /bin/sh \
        -v "${path.module}/load-testing-lambda-package-dependencies/python:/opt/python" \
        -v "${path.module}/lambda-code/requirements.txt:/tmp/requirements.txt" \
        public.ecr.aws/lambda/python:3.12 \
        -c "pip install -r /tmp/requirements.txt -t /opt/python"
    EOT
  }
}

data "archive_file" "load_testing_lambda_package_dependencies" {
  depends_on = [terraform_data.load_testing_lambda_package_dependencies]

  source_dir  = "${path.module}/load-testing-lambda-package-dependencies"
  output_path = "${path.module}/load-testing-lambda-package-dependencies.zip"
  type        = "zip"
}

resource "terraform_data" "load_testing_lambda_package" {
  triggers_replace = [
    sha256(join("", [
      for file in sort(fileset("${path.module}/lambda-code/tests", "**")) :
      filesha256("${path.module}/lambda-code/tests/${file}")
    ])),
    filesha256("${path.module}/lambda-code/main.py"),
    filesha256("${path.module}/lambda-code/custom_create_settings.py")
  ]

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf "${path.module}/load-testing-lambda-package"
      mkdir -p "${path.module}/load-testing-lambda-package"

      cp -R ${path.module}/lambda-code/tests ${path.module}/load-testing-lambda-package/
      cp ${path.module}/lambda-code/custom_create_settings.py ${path.module}/load-testing-lambda-package/
      cp ${path.module}/lambda-code/main.py ${path.module}/load-testing-lambda-package/
    EOT
  }
}

data "archive_file" "load_testing_lambda_package" {
  depends_on = [terraform_data.load_testing_lambda_package]

  source_dir  = "${path.module}/load-testing-lambda-package"
  output_path = "${path.module}/load-testing-lambda-package.zip"
  type        = "zip"
}
