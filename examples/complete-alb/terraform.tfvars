region = "us-east-1"

namespace = "eg"

stage = "test"

name = "alb"

vpc_id  = ""

load_balancer_name = ""

enabled_target_group = true

target_group_name   = "test"

security_group_name = ""


security_group_ids = [""]

public_subnet_ids  = [""]

internal = false

http_enabled = true

enable = true

access_logs_s3_bucket_name = ""

http_redirect = false

access_logs_enabled = true

alb_access_logs_s3_bucket_force_destroy = true

alb_access_logs_s3_bucket_force_destroy_enabled = true

cross_zone_load_balancing_enabled = false

http2_enabled = true

idle_timeout = 60

ip_address_type = "ipv4"

deletion_protection_enabled = false

deregistration_delay = 15

health_check_path = "/"

health_check_timeout = 10

health_check_healthy_threshold = 2

health_check_unhealthy_threshold = 2

health_check_interval = 15

health_check_matcher = "200-399"

target_group_port = 80

target_group_target_type = "ip"

stickiness = {
  cookie_duration = 60
  enabled         = true
}