resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "code-pipeline-${local.region}-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_s3_sse" {
  bucket = aws_s3_bucket.codepipeline_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cpl_bkt_block_public_access" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_codepipeline" "t223306781sit722week10_codepipeline" {
  name     = var.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]


      configuration = {
        RepositoryName       = aws_codecommit_repository.t223306781sit722week10_codecommit_repo.repository_name
        BranchName           = var.codecommit_repo_branch_name
        PollForSourceChanges = false
      }
    }
  }


  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      #output_artifacts = ["combined-artifact"] #["awsstorage","gateway","history","metadata","videostreaming"] 
      configuration = {
        ProjectName = aws_codebuild_project.t223306781sit722week10_codebuild_project.name
        BatchEnabled = "true"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      #output_artifacts = ["deploy_output"]
      configuration = {
        ProjectName = aws_codebuild_project.t223306781sit722week10_codebuild_deploy_project.name

      }
    }
  }

}