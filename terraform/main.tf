
resource "aws_s3_bucket" "terraform_demo" {
  bucket = "terraform-floci-demo"
}

output "bucket_name" {
  value = aws_s3_bucket.terraform_demo.bucket
}
