terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws        = { source = "hashicorp/aws",        version = "~> 5.50" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.29" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.13" }
    null       = { source = "hashicorp/null",       version = "~> 3.2" }
  }
}
