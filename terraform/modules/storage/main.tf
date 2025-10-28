locals { access_log_prefix = "accesslog/orthbucket/" }

data "aws_caller_identity" "current" {}

data "aws_region" "this" {}

resource "aws_s3_bucket" "orthbucket" {
  bucket = "${var.resource_prefix}-orthbucket"

  force_destroy = !var.is_prod # remaining object does not stop bucket from being deleted when force_destroy is true
  tags          = { Name = "${var.resource_prefix}-orthbucket" }
}

resource "aws_s3_bucket_versioning" "orthbucket_versioning" {
  bucket = aws_s3_bucket.orthbucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test" {
  bucket = aws_s3_bucket.orthbucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.custom_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "orthbucketblockpublicaccess" {
  bucket                  = aws_s3_bucket.orthbucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.orthbucket] # explicit dependency to avoid errors on conflicting conditional operation
}

# Ref https://aws.amazon.com/blogs/security/how-to-restrict-amazon-s3-bucket-access-to-a-specific-iam-role/
# Each IAM entity (user or role) has a defined aws:userid variable. 

resource "aws_s3_bucket_policy" "orthbucketpolicy" {
  bucket = aws_s3_bucket.orthbucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.resource_prefix}-OrthBucketPolicy"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.orthbucket.arn,
          "${aws_s3_bucket.orthbucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Sid    = "AllowAccountRoot"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:Put*",
          "s3:Get*",
          "s3:List*",
          "s3:Delete*"
        ]
        Resource = [
          aws_s3_bucket.orthbucket.arn,
          "${aws_s3_bucket.orthbucket.arn}/*",
        ]
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.orthbucketblockpublicaccess]
}

resource "aws_s3_bucket" "orthanc_config" {
  bucket        = "ctx-orthanc-config"
  force_destroy = true
  tags          = {
    Name = "ctx-orthanc-config"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "orthanc_config_sse" {
  bucket = aws_s3_bucket.orthanc_config.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.custom_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "orthanc_config_blockpublicaccess" {
  bucket                  = aws_s3_bucket.orthanc_config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.orthanc_config]
}

# Upload orthanc-config files to S3
resource "aws_s3_object" "orthanc_config_files" {
  for_each = fileset("${path.root}/../orthanc-config", "**")
  bucket   = aws_s3_bucket.orthanc_config.bucket
  key      = each.value
  source   = "${path.root}/../orthanc-config/${each.value}"
  etag     = filemd5("${path.root}/../orthanc-config/${each.value}")
  
  # Ignore changes to prevent unnecessary re-uploads
  lifecycle {
    ignore_changes = [etag, source]
  }
  
  depends_on = [
    aws_s3_bucket.orthanc_config,
    aws_s3_bucket_server_side_encryption_configuration.orthanc_config_sse,
    aws_s3_bucket_public_access_block.orthanc_config_blockpublicaccess
  ]
}

resource "aws_s3_bucket" "logging_bucket" {
  bucket        = "${var.resource_prefix}-orthweb-logging"
  force_destroy = true
  tags          = { Name = "${var.resource_prefix}-logging" }
}
resource "aws_s3_bucket_versioning" "orthweb_logging_versioning" {
  bucket = aws_s3_bucket.logging_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_policy" "vpc_flow_logs_policy" {
  name        = "${var.resource_prefix}-vpc-flow-logs-policy"
  description = "IAM policy for VPC flow logs to write logs to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:PutObjectAcl"
        ],
        Resource = [
          aws_s3_bucket.logging_bucket.arn,
          "${aws_s3_bucket.logging_bucket.arn}/*"
        ]
      }
    ]
  })
}

# IAM role for VPC flow logs to assume and write logs to the S3 bucket
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.resource_prefix}-vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "vpc_flow_logs_policy_attachment" {
  role       = aws_iam_role.vpc_flow_logs_role.name
  policy_arn = aws_iam_policy.vpc_flow_logs_policy.arn
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging_sse" {
  bucket = aws_s3_bucket.logging_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.custom_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "orthweb_loggingbucket_blockpublicaccess" {
  bucket                  = aws_s3_bucket.logging_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.logging_bucket] # explicit dependency to avoid errors on conflicting conditional operation
}

resource "aws_s3_bucket_policy" "orthweb_logging_policy" {
  bucket = aws_s3_bucket.logging_bucket.id
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.resource_prefix}-OrthwebLoggingBucketPolicy"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy",
        Effect = "Allow",
        Principal = {
          Service = "logging.s3.amazonaws.com"
        },
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.logging_bucket.arn}/${local.access_log_prefix}*",
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "${aws_s3_bucket.orthbucket.arn}"
          },
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryWrite",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.logging_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${data.aws_region.this.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = [
          "s3:GetBucketAcl"
        ],
        Resource = "${aws_s3_bucket.logging_bucket.arn}",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:${data.aws_region.this.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.orthweb_loggingbucket_blockpublicaccess]
}

resource "aws_s3_bucket_logging" "bucket_logging_target_association" {
  bucket = aws_s3_bucket.orthbucket.id

  target_bucket = aws_s3_bucket.logging_bucket.id
  target_prefix = local.access_log_prefix
}
