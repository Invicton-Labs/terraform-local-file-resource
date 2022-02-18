terraform {
  required_version = ">= 1.1.5"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
  }
}
