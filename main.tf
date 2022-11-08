
data "ncloud_vpc" "vpc" {
  count = var.vpc_name != null ? 1 : 0

  filter {
    name   = "name"
    values = [var.vpc_name]
  }
}

data "ncloud_subnet" "subnets" {
  for_each = toset(coalesce(var.subnet_names, []))

  vpc_no = one(data.ncloud_vpc.vpc.*.id)
  filter {
    name   = "name"
    values = [each.key]
  }
}

resource "ncloud_lb" "lb" {
  name            = var.name
  description     = var.description
  type            = var.type
  network_type    = var.network_type
  subnet_no_list  = coalesce(var.subnet_no_list, coalesce(var.subnet_ids, values(data.ncloud_subnet.subnets).*.id))
  throughput_type = var.throughput_type
  idle_timeout    = var.idle_timeout
}


data "ncloud_lb_target_group" "target_groups" {
  for_each = toset([for listener in var.listeners : listener.target_group_name if can(listener.target_group_name)])

  filter {
    name   = "name"
    values = [each.key]
  }
}


resource "ncloud_lb_listener" "lb_listeners" {
  count = length(var.listeners)

  load_balancer_no = ncloud_lb.lb.id
  protocol         = var.listeners[count.index].protocol
  port             = var.listeners[count.index].port
  target_group_no = (
    try(var.listeners[count.index].target_group_no,
      try(var.listeners[count.index].target_group_id,
        data.ncloud_lb_target_group.target_groups[var.listeners[count.index].target_group_name].id
  )))

  tls_min_version_type = (var.listeners[count.index].protocol == "TLS") || (var.listeners[count.index].protocol == "HTTPS") ? var.listeners[count.index].tls_min_version_type : null
  ssl_certificate_no   = (var.listeners[count.index].protocol == "TLS") || (var.listeners[count.index].protocol == "HTTPS") ? var.listeners[count.index].ssl_certificate_no : null
  use_http2            = (var.listeners[count.index].protocol == "HTTPS") ? var.listeners[count.index].use_http2 : null
}
