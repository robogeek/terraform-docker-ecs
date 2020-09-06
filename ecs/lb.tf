# alb.tf

resource "aws_lb" "example" {
  name            = "${data.terraform_remote_state.vpc.outputs.project_name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets         = [ 
      data.terraform_remote_state.vpc.outputs.subnet_public1_id, 
      data.terraform_remote_state.vpc.outputs.subnet_public2_id ]
  security_groups = [ aws_security_group.lb.id ]
}

/* resource "aws_alb_target_group" "notes" {
  name        = "${data.terraform_remote_state.vpc.outputs.project_name}-target-group"
  port        = var.notes_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id 
  target_type = "ip"

  /* health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  } * /
} */

/*

This error is confusing.  The `docker compose up` proceeds until
CloudMap says it failed at which time everything gets deleted, as so:

[+] Running 10/10
 ⠿ nginxcomposesimple                       DELETE_COMPLETE                                                  114.0s
 ⠿ LogGroup                                 DELETE_COMPLETE                                                  108.0s
 ⠿ Cluster                                  DELETE_COMPLETE                                                  105.0s
 ⠿ NginxTaskExecutionRole                   DELETE_COMPLETE                                                  109.0s
 ⠿ NginxcomposesimpleDefaultNetwork         DELETE_COMPLETE                                                  107.0s
 ⠿ NginxTCP80TargetGroup                    DELETE_COMPLETE                                                  105.0s
 ⠿ CloudMap                                 DELETE_COMPLETE                                                  106.0s
 ⠿ NginxTCP80Listener                       DELETE_COMPLETE                                                  101.0s
 ⠿ NginxcomposesimpleDefaultNetworkIngress  DELETE_COMPLETE                                                   97.0s
 ⠿ NginxTaskDefinition                      DELETE_COMPLETE                                                   88.0s
The VPC vpc-09c034a9fa6822106 in region us-west-2 has already been associated with the hosted zone Z05400872H500XXEPLD0D with the same domain name. (Service: AmazonRoute53; Status Code: 400; Error Code: ConflictingDomainExists; Request ID: 0ec590ea-9a57-4287-a61e-92099634eab3; Proxy: null)

*/

# Redirect all traffic from the ALB to the target group
/* resource "aws_alb_listener" "notes" {
  load_balancer_arn = aws_lb.notes.id
  port              = var.notes_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.notes.id
    type             = "forward"
  }
} */

/*
* Commenting out the aws_alb_listener avoids this problem:

A listener already exists on this port for this load balancer 'arn:aws:elasticloadbalancing:us-west-2:098106984154:loadbalancer/app/notes-load-balancer/eeb0be21613b6ace' (Service: AmazonElasticLoadBalancing; Status Code: 400; Error Code: DuplicateListener; Request ID: b2a13dc9-c72c-4414-8c6f-5c6448f87dd6; Proxy: null)

*/

resource "aws_security_group" "lb" {
  name        = "${data.terraform_remote_state.vpc.outputs.project_name}-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id 

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = var.service_port
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
