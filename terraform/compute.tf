resource "aws_launch_template" "haproxy" {
  name_prefix   = "alroma-haproxy-"
  image_id      = "ami-04e3e03e5a1a6a017"
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.haproxy.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    HOSTNAME=$(hostname)

    cat > /etc/haproxy/haproxy.cfg <<HAPROXY
    global
        daemon
        maxconn 256

    defaults
        mode http
        timeout connect 5s
        timeout client  10s
        timeout server  10s

    frontend http_front
        bind *:80
        http-request return status 200 content-type "text/plain" lf-string "Hello from HAProxy node: $HOSTNAME"
    HAPROXY

    systemctl restart haproxy
  EOF
  )
}

resource "aws_autoscaling_group" "haproxy" {
  name                = "alroma-haproxy"
  min_size            = var.node_count
  desired_capacity    = var.node_count
  max_size            = var.node_count
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [
    aws_lb_target_group.haproxy.arn
  ]

  launch_template {
    id      = aws_launch_template.haproxy.id
    version = "$Latest"
  }
}
