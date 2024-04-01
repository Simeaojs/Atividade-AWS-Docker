resource "aws_autoscaling_group" "asg" {
  name                      = "project-docker"
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 2
  force_delete              = true
  depends_on                = [aws_lb.alb-tf]
  target_group_arns         = [aws_lb_target_group.target_group.arn]
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.wp-launch-config.name
  vpc_zone_identifier       = [aws_subnet.subnet-private-a.id, aws_subnet.subnet-private-b.id]

  tag {
    key                 = "Name"
    value               = "project-docker"
    propagate_at_launch = true
  }

}
# Target Tracking Scaling Policies

resource "aws_autoscaling_policy" "asg_cpu_policy" {
  name                   = "asg_cpu_policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }

}