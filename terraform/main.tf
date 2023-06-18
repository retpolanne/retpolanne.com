resource "cloudflare_account" "retpolanne" {
  name = "retpolanne"
}

resource "cloudflare_zone" "retpolannedotcom" {
  account_id = cloudflare_account.retpolanne.id
  zone       = "retpolanne.com"
}

resource "cloudflare_record" "blog" {
  zone_id = cloudflare_zone.retpolannedotcom.id
  name    = "blog"
  value   = "retpolanne.github.io."
  type    = "CNAME"
}

resource "github_repository" "retpolannedotcom" {
  name        = "retpolanne.com"
  description = "My website"
  private      = false

  pages {
    cname = "blog.retpolanne.com"
    build_type = "workflow"
  }
}
