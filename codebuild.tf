resource "aws_s3_bucket" "codebuild_logs_bucket" {
  bucket = "codebuild-logs-${local.region}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild_logs_s3_sse" {
  bucket = aws_s3_bucket.codebuild_logs_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.codebuild_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#################### CODEBUILD PROJECT CONTAINER IMAGE BUILD #############################

resource "aws_codebuild_project" "t223306781sit722week10_codebuild_project" {
  name          = var.codebuild_project_name
  description   = "t223306781sit722week10 build project"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn
  build_batch_config {
    service_role  = aws_iam_role.codebuild_role.arn
  }

  artifacts {
    type = var.source_type
    packaging = "ZIP"            # Combine outputs into a single ZIP file
    name      = "combined-artifact"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_logs_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = local.region
    }

    #environment_variable {
    #  name  = "AWS_DEFAULT_REGION"
    #  value = "video-storage-${local.region}"
    #}

    #environment_variable {
    #  name  = "STORAGE_FOLDER"
    #  value = "videos"
    #}

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }
    #  environment_variable {
    #    name  = "AWS_ACCESS_KEY_ID"
    #    value = local.access_key_id
    #  }

    #   environment_variable {
    #    name  = "AWS_SECRET_ACCESS_KEY"
    #    value = local.secret_access_key
    #  }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.t223306781sit722week10_ecr_repo.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = var.image_tag
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-log-group"
      stream_name = "codebuild-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_logs_bucket.id}/build-log"
    }
  }

  source {
    type = var.source_type
    buildspec = var.buildspec
  }
}


#################### CODEBUILD PROJECT DEPLOY#############################
resource "aws_codebuild_project" "t223306781sit722week10_codebuild_deploy_project" {
  name          = var.codebuild_deploy_project_name
  description   = "t223306781sit722week10 codebuild deploy project"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn
  build_batch_config {
    service_role  = aws_iam_role.codebuild_role.arn
  }

  artifacts {
    type = var.source_type
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_logs_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "false"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = local.region
    }
    #environment_variable {
    #  name  = "AWS_DEFAULT_REGION"
    #  value = "video-storage-${local.region}"
    #}

    #environment_variable {
    #  name  = "STORAGE_FOLDER"
    #  value = "videos"
    #}

    environment_variable {
      name  = "AWS_CLUSTER_NAME"
      value = var.eks_cluster_name
    }

  #  environment_variable {
  #    name  = "AWS_ACCESS_KEY_ID"
  #    value = local.access_key_id
  #  }

  #   environment_variable {
  #    name  = "AWS_SECRET_ACCESS_KEY"
  #    value = local.secret_access_key
  #  }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.t223306781sit722week10_ecr_repo.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = var.image_tag
    }

    environment_variable {
      name  = "APP_NAME"
      value = var.app_name
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-deploy-log-group"
      stream_name = "codebuild-deploy-log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_logs_bucket.id}/build-log"
    }
  }

  source {
    type = var.source_type
    buildspec = var.deployspec
  }
}