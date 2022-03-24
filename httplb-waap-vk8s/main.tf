variable "api_p12_file" {}
variable "api_url" {}
variable "healthcheck_name" {}
variable "myns" {}
variable "op_name" {}
variable "pool_port" {}
variable "k8s_svc_name" {}
variable "vsite_name" {}
variable "wafpolicy" {}
variable "httplb_name" {}
variable "mydomain" {}
variable "bot_ep" {}
variable "bot_ep_prefix" {}

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

// Manage Health Check
resource "volterra_healthcheck" "this" {
  name                = var.healthcheck_name
  namespace           = var.myns
  timeout             = 3
  interval            = 15
  unhealthy_threshold = 1
  healthy_threshold   = 3
  http_health_check {
    use_origin_server_name = true
    path                   = "/"
    use_http2              = false
  }
}

// Manage Origin Pool
resource "volterra_origin_pool" "this" {
  name                   = var.op_name
  namespace              = var.myns
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = var.pool_port
  no_tls                 = true
  healthcheck {
    name = var.healthcheck_name
  }
  origin_servers {
    k8s_service {
      service_name  = "${var.k8s_svc_name}.${var.myns}"
      vk8s_networks = true
      site_locator {
        virtual_site {
          name  = var.vsite_name
        }
      }
    }
  }
  depends_on = [ volterra_healthcheck.this ]
}

// Manage Application Firewall (WAF and Signature-Based Bot Protection)
resource "volterra_app_firewall" "this" {
  name                       = var.wafpolicy
  namespace                  = var.myns
  allow_all_response_codes   = true
  default_anonymization      = true
  use_default_blocking_page  = true
  use_loadbalancer_setting   = true
  blocking                   = true
  detection_settings {
    disable_suppression        = true 
    enable_threat_campaigns    = true
    default_violation_settings = true
    signature_selection_setting {
      default_attack_type_settings    = true
      high_medium_accuracy_signatures = true
    }
  }
  bot_protection_setting {
    malicious_bot_action  = "BLOCK"
    suspicious_bot_action = "BLOCK"
    good_bot_action       = "REPORT"
  }
}

// Manage HTTP LoadBalancer with API Discovery, Bot Defense
resource "volterra_http_loadbalancer" "this" {
  name                            = var.httplb_name
  namespace                       = var.myns
  domains                         = var.mydomain
  advertise_on_public_default_vip = true
  no_challenge                    = true
  round_robin                     = true
  disable_rate_limit              = true
  no_service_policies             = true
  http {
    dns_volterra_managed = true
  }
  /*
  [Note] When you use HTTPS Auto Cert, please be careful for rate limit of Let's Encrypt
  https://f5cloud.zendesk.com/hc/en-us/articles/4405934918167-Issue-My-certificate-is-not-generated-for-my-domain
  
  https_auto_cert {
    http_redirect = true
    no_mtls       = true
    tls_config {
      default_security = true
    }
  }
  */
  default_route_pools {
    pool {
      name      = var.op_name
      namespace = var.myns
    }
  }
  app_firewall {
    name      = var.wafpolicy
    namespace = var.myns
  }
  single_lb_app {
    enable_ddos_detection           = true
    enable_malicious_user_detection = true
    enable_discovery {
      enable_learn_from_redirect_traffic = true
    }
  }
  bot_defense {
    regional_endpoint = "ASIA"
    timeout           = "1000"
    policy {
      js_download_path = "/common.js"
      protected_app_endpoints {
        metadata {
          name    = var.bot_ep
          disable = false
        }
        http_methods = [ "POST" ]
        path {
          prefix = var.bot_ep_prefix
        }
        mitigation {
          block {
            status = "OK"
            body   = "string:///VGhlIHJlcXVlc3RlZCBVUkwgd2FzIHJlamVjdGVkLiBQbGVhc2UgY29uc3VsdCB3aXRoIHlvdXIgYWRtaW5pc3RyYXRvci4="
            // "The requested URL was rejected. Please consult with your administrator." (Base64 encoded string)
          }
        }
      }
      js_insert_all_pages {
        javascript_location = "AFTER_HEAD"
      }
    }
  }
  depends_on = [ volterra_origin_pool.this, volterra_app_firewall.this ]
}