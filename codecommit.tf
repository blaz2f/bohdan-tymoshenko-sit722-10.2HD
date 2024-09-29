resource "aws_codecommit_repository" "t223306781sit722week10_codecommit_repo" {
  repository_name = var.codecommit_repo_name
  description     = "Code Repo"
}