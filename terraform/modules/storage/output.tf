output "s3_info" {
  value = {
    bucket_domain_name = aws_s3_bucket.orthbucket.bucket_domain_name
    bucket_name        = aws_s3_bucket.orthbucket.bucket
    logging_bucket_arn = aws_s3_bucket.logging_bucket.arn
    orthanc_config_bucket = aws_s3_bucket.orthanc_config.bucket
  }
}

output "orthanc_config_files_uploaded" {
  value = aws_s3_object.orthanc_config_files
  description = "S3 objects for orthanc-config files"
}
