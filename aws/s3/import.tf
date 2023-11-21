import {
  to = aws_s3_bucket.reliability_file_storage
  id = "forms-${var.env}-reliability-file-storage"
}

import {
  to = aws_s3_bucket.archive_storage
  id = "forms-${var.env}-archive-storage"
}

import {
  to = aws_s3_bucket.vault_file_storage
  id = "forms-${var.env}-vault-file-storage"
}