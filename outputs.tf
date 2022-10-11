output "load_balancer" {
  value = merge({for k, v in ncloud_lb.lb: k => v if k != "listener_no_list"},
    {listeners = ncloud_lb_listener.lb_listeners}
  )
}