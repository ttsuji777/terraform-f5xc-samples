api_p12_file     = ""                        // Path for p12 file downloaded from VoltConsole
api_url          = ""                        // API URL for your tenant
healthcheck_name = "healthcheck"             // Name of Health Check  
myns             = "namespace"               // Name of your namespace
op_name          = "originpool"              // Name of Origin Pool
pool_port        = "80"                      // Port Number
wafpolicy        = ""                        // Application Firewall assgined to HTTP Load Balancer
k8s_svc_name     = ""                        // Name of Kubernetes Service
vsite_name       = ""                        // Name of Virtual Site
httplb_name      = "httplb"                  // Name of HTTP LoadBalancer
mydomain         = ["host.namespace.domain"] // Domain name to be exposed
bot_ep           = ""                        // Name of Bot Defense Endpoint
bot_ep_prefix    = ""                        // Path for Bot Defense Endpoint