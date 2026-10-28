terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5.1"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "voting_app" {
  name           = "voting-app-tf"
  wait_for_ready = true
}
