resource "aws_lb_target_group" "haproxy" {
  name     = "alroma-haproxy"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
  }
}

resource "aws_lb" "haproxy" {
  name               = "alroma-haproxy"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "haproxy" {
  load_balancer_arn = aws_lb.haproxy.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.haproxy.arn
  }
}
