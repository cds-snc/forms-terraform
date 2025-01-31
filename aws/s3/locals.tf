locals {
  # Remove all objects after expiry
  lifecycle_expire_all = {
    id      = "expire_all"
    enabled = true
    expiration = {
      days = "30"
    }
  }
  # Cleanup old versions and incomplete uploads
  lifecycle_remove_noncurrent_versions = {
    id                                     = "remove_noncurrent_versions"
    enabled                                = true
    abort_incomplete_multipart_upload_days = "7"
    noncurrent_version_expiration = {
      days = "30"
    }
  }
  # Transition objects to cheaper storage classes over time
  lifecycle_transition_storage = {
    id      = "transition_storage"
    enabled = true
    transition = [
      {
        days          = "90"
        storage_class = "STANDARD_IA"
      },
      {
        days          = "180"
        storage_class = "GLACIER"
      }
    ]
  }
}