# Multiple Load Balancer Module

## **This version of the module requires Terraform version 1.3.0 or later.**

This document describes the Terraform module that creates multiple Ncloud Load Balancers.

## Variable Declaration

### Structure : `variable.tf`

You need to create `variable.tf` and copy & paste the variable declaration below.

**You can change the variable name to whatever you want.**

``` hcl
variable "load_balancers" {
  type = list(object({
    name         = string
    description  = optional(string, "")
    type         = string                          // NETWORK | NETWORK_PROXY | APPLICATION
    network_type = optional(string, "PUBLIC")      // PUBLIC (default) | PRIVATE

    vpc_name     = string
    subnet_names = list(string)

    throughput_type = optional(string, "SMALL")    // SMALL (default) | MEDUIM | LARGE
                                                   // Only SMALL can be selected when type is NETWORK and network_type is PRIVATE
    idle_timeout = optional(number, 60)            // 60 (default)

    listeners = optional(list(object({
      protocol          = string                   // TCP (when type is NETWORK), TCP/TLS (when type is NETWORK_PROXY), HTTP/HTTPS (when type is APPLICATION)
      port              = number
      target_group_name = string

      // The properties below are valid only when the listener protocol is HTTPS or TLS.
      ssl_certificate_no   = optional(string, null)
      tls_min_version_type = optional(string, "TLSV10")     // TLSV10 (default) | TLSV11 | TLSV12

      // The property below are valid only when the listener protocol is HTTPS
      use_http2            = optional(bool, false)          // false (default)
    })), [])
  }))
  default = []
}
```

### Example : `terraform.tfvars`

You can create a `terraform.tfvars` and refer to the sample below to write the variable specification you want.
File name can be `terraform.tfvars` or anything ending in `.auto.tfvars`

**It must exactly match the variable name above.**

``` hcl
load_balancers = [

  {
    name         = "nplb-foo-public"
    description  = "Internet-facing network-proxy load balancer for foo"
    type         = "NETWORK_PROXY"
    network_type = "PUBLIC"

    vpc_name     = "vpc-foo"
    subnet_names = ["sbn-foo-lb-1", "sbn-foo-lb-2"]

    throughput_type = "SMALL"
    idle_timeout    = 60

    listeners = [
      {
        protocol          = "TCP"
        port              = 80
        target_group_name = "tg-foo-proxy-tcp"
      },
      {
        protocol             = "TLS"
        port                 = 443
        target_group_name    = "tg-foo-proxy-tcp"
        ssl_certificate_no   = "7589"
      }
    ]
  },
  {
    name         = "alb-foo-public"
    description  = "Internal application load balancer for foo"
    type         = "APPLICATION"
    network_type = "PRIVATE"

    vpc_name     = "vpc-foo"
    subnet_names = ["sbn-foo-lb-1", "sbn-foo-lb-2"]

    throughput_type = "LARGE"

    listeners = [
      {
        protocol          = "HTTP"
        port              = 80
        target_group_name = "tg-foo-http"
      },
      {
        protocol             = "HTTPS"
        port                 = 443
        target_group_name    = "tg-foo-https"
        ssl_certificate_no   = "7589"
        tls_min_version_type = "TLSV12"
        use_http2            = true
      }
    ]
  },
  {
    name        = "nlb-foo-public"
    description = "Internet-facing network load balancer for foo"
    type        = "NETWORK"

    vpc_name     = "vpc-foo"
    subnet_names = ["sbn-foo-lb-1"]

    listeners = [
      {
        protocol          = "TCP"
        port              = 80
        target_group_name = "tg-foo-tcp"
      }
    ]
  }
]
```

## Module Declaration

### `main.tf`

Map your `Load Balancer variable name` to a `local Load Balancer variable`. `Load Balancer module` are created using `local Load Balancer variables`. This eliminates the need to change the variable name reference structure in the `Load Balancer module`.

``` hcl
locals {
  load_balancers       = var.load_balancers
}
```

Then just copy and paste the module declaration below.

``` hcl

module "load_balancers" {
  source = "terraform-ncloud-modules/load-balancer/ncloud"

  for_each = { for lb in local.load_balancers : lb.name => lb }

  name            = each.value.name
  description     = each.value.description
  type            = each.value.type
  network_type    = each.value.network_type
  
  // you can use "vpc_name" & "subnet_name". Then module will find "subnet_id" from "DataSource: ncloud_subnet".
  vpc_name        = each.value.vpc_name
  subnet_names    = each.value.subnet_names1
  // or "subnet_id" instead
  # subnet_ids      = [ for subnet_name in each.value.subnet_names : module.vpcs[each.value.vpc_name].subnets[subnet_name].id ] 
  
  throughput_type = each.value.throughput_type
  idle_timeout    = each.value.idle_timeout
  
  // you can use "listeners" with "target_group_name" as object attribute.
  listeners       = each.value.listeners
  // or "listeners" with "target_group_id" instead.
  # listeners       = [for listener in each.value.listeners : merge(
  #   { for k, v in listener : k => v if k != "target_group_name" },
  #   { target_group_id = module.target_groups[listener.target_group_name].target_group.id }
  # )]
}


```
