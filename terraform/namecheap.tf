resource "namecheap_domain_records" "jaksi-dev" {
  domain     = "jaksi.dev"
  mode       = "OVERWRITE"
  email_type = "MX"

  record {
    type     = "MX"
    hostname = "@"
    address  = "in1-smtp.messagingengine.com."
    mx_pref  = "10"
  }
  record {
    type     = "MX"
    hostname = "@"
    address  = "in2-smtp.messagingengine.com."
    mx_pref  = "20"
  }
  record {
    type     = "CNAME"
    hostname = "fm1._domainkey"
    address  = "fm1.jaksi.dev.dkim.fmhosted.com."
  }
  record {
    type     = "CNAME"
    hostname = "fm2._domainkey"
    address  = "fm2.jaksi.dev.dkim.fmhosted.com."
  }
  record {
    type     = "CNAME"
    hostname = "fm3._domainkey"
    address  = "fm3.jaksi.dev.dkim.fmhosted.com."
  }
  record {
    type     = "TXT"
    hostname = "@"
    address  = "v=spf1 include:spf.messagingengine.com ?all"
  }

  record {
    type     = "A"
    hostname = "home"
    address  = "109.255.138.52"
  }
  record {
    type     = "A"
    hostname = "vps"
    address  = "185.92.220.229"
  }

  record {
    type     = "CNAME"
    hostname = "infra"
    address  = "vps.jaksi.dev."
  }
  record {
    type     = "CNAME"
    hostname = "*.infra"
    address  = "vps.jaksi.dev."
  }
}
