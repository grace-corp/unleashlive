provider "aws" {
  alias  = "us"
  region = var.primary_region
}

provider "aws" {
  alias  = "eu"
  region = var.secondary_region
}
