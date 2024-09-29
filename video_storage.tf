resource "aws_s3_bucket" "video-storage" {
  bucket = "video-storage-${local.region}"
  force_destroy = true
  acl     = "private"

}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.video-storage.id
  key    = "videos/"
}