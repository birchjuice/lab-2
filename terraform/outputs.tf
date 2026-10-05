output "load_balancer_dns" {
  value = aws_lb.haproxy.dns_name
}
