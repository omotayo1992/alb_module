provider "aws" {
  region = var.region
}


module "alb" {
  source                            = "../.."
  vpc_id                            = var.vpc_id
  enable                            = var.enable
  security_group_ids                = var.security_group_ids
  subnet_ids                        = var.public_subnet_ids
  enabled_target_group              = var.enabled_target_group
  internal                          = var.internal
  http_enabled                      = var.http_enabled
  target_group_name                 = var.target_group_name
  http_redirect                     = var.http_redirect
  security_group_name               = var.security_group_name
  access_logs_enabled               = var.access_logs_enabled
  cross_zone_load_balancing_enabled = var.cross_zone_load_balancing_enabled
  http2_enabled                     = var.http2_enabled
  idle_timeout                      = var.idle_timeout
  ip_address_type                   = var.ip_address_type
  deletion_protection_enabled       = var.deletion_protection_enabled
  deregistration_delay              = var.deregistration_delay
  health_check_path                 = var.health_check_path
  health_check_timeout              = var.health_check_timeout
  health_check_healthy_threshold    = var.health_check_healthy_threshold
  health_check_unhealthy_threshold  = var.health_check_unhealthy_threshold
  health_check_interval             = var.health_check_interval
  health_check_matcher              = var.health_check_matcher
  target_group_port                 = var.target_group_port
  target_group_target_type          = var.target_group_target_type
  stickiness                        = var.stickiness
  access_logs_s3_bucket_name        = var.access_logs_s3_bucket_name

  alb_access_logs_s3_bucket_force_destroy = var.alb_access_logs_s3_bucket_force_destroy


}