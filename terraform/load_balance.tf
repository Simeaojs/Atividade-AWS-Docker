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