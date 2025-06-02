provider "aws" {
  for_each = toset(var.regions)
  alias    = each.value
  region   = each.value
}
