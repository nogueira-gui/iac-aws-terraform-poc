# aws s3 bucket for terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
}