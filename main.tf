resource "aws_security_group" "default" {
  count       = var.enable && var.security_group_enabled ? 1 : 0
  description = "Controls access to the ALB (HTTP/HTTPS)"
  vpc_id      = var.vpc_id
  name        = var.security_group_name
  tags        = var.security_group_tags
}

resource "aws_security_group_rule" "egress" {
  count             = var.enable && var.security_group_enabled ? 1 : 0
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = one(aws_security_group.default[*].id)
}

resource "aws_security_group_rule" "http_ingress" {
  count             = var.enable && var.security_group_enabled && var.http_enabled ? 1 : 0
  type              = "ingress"
  from_port         = var.http_port
  to_port           = var.http_port
  protocol          = "tcp"
  cidr_blocks       = var.http_ingress_cidr_blocks
  prefix_list_ids   = var.http_ingress_prefix_list_ids
  security_group_id = one(aws_security_group.default[*].id)
}

resource "aws_security_group_rule" "https_ingress" {
  count             = var.enable && var.security_group_enabled && var.https_enabled ? 1 : 0
  type              = "ingress"
  from_port         = var.https_port
  to_port           = var.https_port
  protocol          = "tcp"
  cidr_blocks       = var.https_ingress_cidr_blocks
  prefix_list_ids   = var.https_ingress_prefix_list_ids
  security_group_id = one(aws_security_group.default[*].id)
}



resource "aws_lb" "default" {
  #bridgecrew:skip=BC_AWS_NETWORKING_41 - Skipping Ensure that ALB Drops HTTP Headers
  #bridgecrew:skip=BC_AWS_LOGGING_22 - Skipping Ensure ELBv2 has Access Logging Enabled
  count              = var.enable ? 1 : 0
  name               = var.load_balancer_name
  tags               = var.lb_tags
  internal           = var.internal
  load_balancer_type = "application"

  security_groups = compact(
    concat(var.security_group_ids, [one(aws_security_group.default[*].id)]),
  )

  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled
  enable_http2                     = var.http2_enabled
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = var.deletion_protection_enabled
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  preserve_host_header             = var.preserve_host_header
  xff_header_processing_mode       = var.xff_header_processing_mode

  access_logs {
    bucket  = var.access_logs_s3_bucket_name
    prefix  = var.access_logs_prefix
    enabled = var.access_logs_enabled
  }
}


resource "aws_lb_target_group" "default" {
  count                         = var.enabled_target_group ? 1 : 0
  name                          = var.target_group_name
  port                          = var.target_group_port
  protocol                      = var.target_group_protocol
  protocol_version              = var.target_group_protocol_version
  vpc_id                        = var.vpc_id
  target_type                   = var.target_group_target_type
  load_balancing_algorithm_type = var.load_balancing_algorithm_type
  deregistration_delay          = var.deregistration_delay
  slow_start                    = var.slow_start

  health_check {
    protocol            = var.health_check_protocol != null ? var.health_check_protocol : var.target_group_protocol
    path                = var.health_check_path
    port                = var.health_check_port
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
  }

  dynamic "stickiness" {
    for_each = var.stickiness == null ? [] : [var.stickiness]
    content {
      type            = "lb_cookie"
      cookie_duration = stickiness.value.cookie_duration
      enabled         = var.target_group_protocol == "TCP" ? false : stickiness.value.enabled
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.target_group_additional_tags

}

resource "aws_lb_listener" "http_forward" {
  #bridgecrew:skip=BC_AWS_GENERAL_43 - Skipping Ensure that load balancer is using TLS 1.2.
  #bridgecrew:skip=BC_AWS_NETWORKING_29 - Skipping Ensure ALB Protocol is HTTPS
  count             = var.enable && var.http_enabled && var.http_redirect != true ? 1 : 0
  load_balancer_arn = one(aws_lb.default[*].arn)
  port              = var.http_port
  protocol          = "HTTP"
  tags              = var.listener_additional_tags

  default_action {
    target_group_arn = var.listener_http_fixed_response != null ? null : one(aws_lb_target_group.default[*].arn)
    type             = var.listener_http_fixed_response != null ? "fixed-response" : "forward"

    dynamic "fixed_response" {
      for_each = var.listener_http_fixed_response != null ? [var.listener_http_fixed_response] : []
      content {
        content_type = fixed_response.value["content_type"]
        message_body = fixed_response.value["message_body"]
        status_code  = fixed_response.value["status_code"]
      }
    }
  }
}

resource "aws_lb_listener" "http_redirect" {
  count             = var.enable && var.http_enabled && var.http_redirect == true ? 1 : 0
  load_balancer_arn = one(aws_lb.default[*].arn)
  port              = var.http_port
  protocol          = "HTTP"
  tags              = var.listener_additional_tags

  default_action {
    target_group_arn = one(aws_lb_target_group.default[*].arn)
    type             = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  #bridgecrew:skip=BC_AWS_GENERAL_43 - Skipping Ensure that load balancer is using TLS 1.2.
  count             = var.enable && var.https_enabled ? 1 : 0
  load_balancer_arn = one(aws_lb.default[*].arn)

  port            = var.https_port
  protocol        = "HTTPS"
  ssl_policy      = var.https_ssl_policy
  certificate_arn = var.certificate_arn
  tags            = var.listener_additional_tags

  default_action {
    target_group_arn = var.listener_https_fixed_response != null ? null : one(aws_lb_target_group.default[*].arn)
    type             = var.listener_https_fixed_response != null ? "fixed-response" : "forward"

    dynamic "fixed_response" {
      for_each = var.listener_https_fixed_response != null ? [var.listener_https_fixed_response] : []
      content {
        content_type = fixed_response.value["content_type"]
        message_body = fixed_response.value["message_body"]
        status_code  = fixed_response.value["status_code"]
      }
    }
  }
}

resource "aws_lb_listener_certificate" "https_sni" {
  count           = var.enable && var.https_enabled && length(var.additional_certs) > 0 ? length(var.additional_certs) : 0
  listener_arn    = one(aws_lb_listener.https[*].arn)
  certificate_arn = var.additional_certs[count.index]
}