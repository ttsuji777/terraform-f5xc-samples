Samples for F5 Distributed Cloud (F5XC) Deployments using Terraform
===========================================================================

This repository contains Terraform manifest example to deploy F5 Disbributed Cloud.

Repository Structure
--------------------------------

Each directory contains manifest file ("main.tf") and Variables file ("terraform.tfvars").

- ce-vmware: Deploy Customer Edge on vCenter with vApp properties
- http-waap: Deploy Healtcheck, Origin Pool, Application Firewall and HTTP Load Balancer with WAAP functions (WAF, DDoS Protection, Bot Protection and API Discovery)
- http-waap-vk8s: Deploy Healtcheck, Origin Pool, Application Firewall and HTTP Load Balancer with WAAP functions for vK8s (WAF, DDoS Protection, Bot Protection and API Discovery)
- vk8s: Deploy Virtual Site and vK8s in F5XC