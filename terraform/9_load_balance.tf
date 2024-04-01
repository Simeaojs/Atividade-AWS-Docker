# Create ALB

resource "aws_lb" "alb-tf" {
  name                             = "alb-project-docker"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.sg_alb.id]
  enable_cross_zone_load_balancing = true
  subnets                          = [aws_subnet.subnet-public-a.id, aws_subnet.subnet-public-b.id]


  tags = {
    name = "alb-project-docker"

  }
}

# Create Target group

resource "aws_lb_target_group" "target_group" {
  name        = "target-group-project-docker"
  depends_on  = [aws_vpc.vpc]
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"

  health_check {
    interval            = 30
    path                = "/wp-admin/install.php"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200,202"

  }

}

# Create ALB Listener 

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb-tf.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

}

output "elb_dns" {
  value = aws_lb.alb-tf.dns_name

}