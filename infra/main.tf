# aws s3 bucket for terraform state
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}