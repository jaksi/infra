terraform {
  required_providers {
    namecheap = {
      source = "namecheap/namecheap"
    }
  }
}

provider "namecheap" {
  user_name = local.namecheap_user
  api_user  = local.namecheap_user
  api_key   = local.namecheap_key
}
