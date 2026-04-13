terraform {
  backend "s3" {
    bucket         = "lesson-5-terraform-state-bucket-1488"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    use_lockfile   = true
    encrypt        = true
    profile        = "default"
  }
}

