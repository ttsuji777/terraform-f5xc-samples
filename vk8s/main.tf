variable "api_p12_file" {}
variable "api_url" {}
variable "mysites" {}
variable "sitelabel" {}
variable "vsite_ce" {}
variable "vsite_re" {}
variable "vk8s_name" {}
variable "myns" {}

terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.6"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}

// Modify site labels to include the sites into Virtual Site
resource "volterra_modify_site" "this" {
  count     = length(var.mysites)
  name      = element(var.mysites, count.index)
  namespace = "system"
  labels = {
    "ves.io/siteName" = var.sitelabel
  }
}

// Manage Virtual Site (Customer Edge)
resource "volterra_virtual_site" "CE" {
  name      = var.vsite_ce
  namespace = var.myns
  site_type = "CUSTOMER_EDGE"
  site_selector {
    expressions = [ "ves.io/siteName = ${var.sitelabel}" ]
  }
  depends_on = [ volterra_modify_site.this ]
}

/* Manage Virtual Site (Regional Edge: Seattle)
resource "volterra_virtual_site" "RE" {
  name      = var.vsite_re
  namespace = var.myns
  site_type = "REGIONAL_EDGE"
  site_selector {
    expressions = ["ves.io/siteName = ves-io-wes-sea"]
  }
}
*/

// Manage Virtual K8s
resource "volterra_virtual_k8s" "this" {
  name      = var.vk8s_name
  namespace = var.myns
  vsite_refs {
    name      = var.vsite_ce
    namespace = var.myns
  }
  /*
  vsite_refs {
    name      = var.vsite_re
    namespace = var.myns
  }
  */
  provisioner "local-exec" {
    command = "sleep 80s"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 20s"
  }
  // depends_on = [ volterra_virtual_site.CE, volterra_virtual_site.RE ]
  depends_on = [ volterra_virtual_site.CE ]
}