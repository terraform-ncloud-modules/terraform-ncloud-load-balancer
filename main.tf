resource "ncloud_lb" "lb" {
  name            = var.name
  description     = var.description
  type            = var.type
  network_type    = var.network_type
  subnet_no_list  = var.subnet_no_list
  throughput_type = var.throughput_type
  idle_timeout    = var.idle_timeout
}

resource "ncloud_lb_listener" "lb_listeners" {
  count = length(var.listeners)

  load_balancer_no     = ncloud_lb.lb.id
  protocol             = var.listeners[count.index].protocol
  port                 = var.listeners[count.index].port
  target_group_no      = var.listeners[count.index].target_group_no
  tls_min_version_type = var.listeners[count.index].tls_min_version_type
  ssl_certificate_no   = var.listeners[count.index].ssl_certificate_no
  use_http2            = var.listeners[count.index].use_http2
}
