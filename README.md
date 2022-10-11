# Multiple Load Balancer Module

This document describes the Terraform module that creates multiple Ncloud Load Balancers.

Before use `Load Balancer module`, you need create `VPC module`, `Server module` and `Target Group module`.

- [VPC module](https://registry.terraform.io/modules/terraform-ncloud-modules/vpc/ncloud/latest)
- [Server module](https://registry.terraform.io/modules/terraform-ncloud-modules/server/ncloud/latest)
- [Target Group module](https://registry.terraform.io/modules/terraform-ncloud-modules/target-group/ncloud/latest)


## Variable Declaration

### `variable.tf`

You need to create `variable.tf` and declare the VPC variable to recognize VPC variable in `terraform.tfvars`. You can change the variable name to whatever you want.

``` hcl
variable "load_balancers" { default = [] }
```

### `terraform.tfvars`

You can create `terraform.tfvars` and refer to the sample below to write variable declarations.
File name can be `terraform.tfvars` or anything ending in `.auto.tfvars`

#### Structure

``` hcl
load_balancers = [
  {
    name         = string                 // (Required)
    description  = string                 // (Required)
    type         = string                 // (Required) NETWORK | NETWORK_PROXY | APPLICATION
    network_type = string                 // (Optional) PUBLIC (default) | PRIVATE

    vpc_name     = string                 // (Required)
    subnet_names = [string]               // (Required)

    throughput_type = string              // (Optional) SMALL (default) | MEDUIM | LARGE
                                          // Only SMALL can be selected when type is NETWORK and network_type is PRIVATE
    idle_timeout    = number              // (Optional) 60 (default)

    listeners = [
      {
        protocol             = string     // (Required) TCP | TLS | HTTP | HTTPS
                                          // TCP when type is NETWORK, TCP/TLS when type is NETWORK_PROXY
                                          // HTTP/HTTPS when type is APPLICATION
        port                 = number     // (Required)
        target_group_name    = string     // (Required)
        ssl_certificate_no   = string     // (Required if listener protocol is HTTPS or TLS)
        tls_min_version_type = string     // (Optional if listener protocol is HTTPS or TLS) TLSV10 (default) | TLSV11 | TLSV12
        use_http2            = bool       // (Optional if listener protocol is HTTPS or TLS) false (default)
      }
    ]
  }
]
```

#### Example

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
        tls_min_version_type = "TLSV12"
        use_http2            = true
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
        protocol           = "HTTPS"
        port               = 443
        target_group_name  = "tg-foo-https"
        ssl_certificate_no = "7589"
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

Also, the `Load Balancer module` is designed to be used with `VPC module`, and `Target Group module` together. So the `VPC module`, and `Target Group module` must also be specified as `local VPC module variable` and `local Target Group module variable`.

``` hcl
locals {
  load_balancers       = var.load_balancers
  module_vpcs          = module.vpcs
  module_target_groups = module.target_groups
}
```

Then just copy and paste the module declaration below.

``` hcl

module "load_balancers" {
  source = "terraform-ncloud-modules/load-balancer/ncloud"

  for_each = { for lb in local.load_balancers : lb.name => lb }

  name        = each.value.name
  description = lookup(each.value, "description", "")
  type        = each.value.type

  network_type   = lookup(each.value, "network_type", "PUBLIC")
  subnet_no_list = [for subnet_name in each.value.subnet_names : local.module_vpcs[each.value.vpc_name].subnets[subnet_name].id]

  throughput_type = lookup(each.value, "throughput_type", "SMALL")
  idle_timeout    = lookup(each.value, "idle_timeout", 60)

  listeners = [for listener in each.value.listeners : {
    protocol             = listener.protocol
    port                 = listener.port
    target_group_no      = local.module_target_groups[listener.target_group_name].target_group.id
    ssl_certificate_no   = lookup(listener, "ssl_certificate_no", null)
    tls_min_version_type = ((listener.protocol == "TLS") || (listener.protocol == "HTTPS") ? lookup(listener, "tls_min_version_type", "TLSV10") : null)
    use_http2 = listener.protocol == "HTTPS" ? lookup(listener, "use_http2", false) : null
  }]
}


```
