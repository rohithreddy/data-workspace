resource "aws_security_group" "dnsmasq" {
  name        = "${var.prefix}-dnsmasq"
  description = "${var.prefix}-dnsmasq"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-dnsmasq"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "dnsmasq_egress_https" {
  description = "egress-dns-tcp"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "dnsmasq_ingress_dns_tcp_notebooks" {
  description = "ingress-dns-tcp"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "dnsmasq_ingress_dns_udp_notebooks" {
  description = "ingress-dns-udp-notebooks"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

resource "aws_security_group_rule" "dnsmasq_ingress_dns_udp_gitlab_runner" {
  description = "ingress-dns-udp-gitlab-runner"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  source_security_group_id = "${aws_security_group.gitlab_runner.id}"

  type        = "ingress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

resource "aws_security_group_rule" "dnsmasq_ingress_dns_udp_superset_multiuser_service" {
  description = "ingress-dns-udp-superset-multiuser-service"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  source_security_group_id = "${aws_security_group.superset_multiuser_service.id}"

  type        = "ingress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

resource "aws_security_group" "sentryproxy_service" {
  name        = "${var.prefix}-sentryproxy"
  description = "${var.prefix}-sentryproxy"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-sentryproxy"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sentryproxy_egress_https" {
  description = "egress-https"

  security_group_id = "${aws_security_group.sentryproxy_service.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "sentryproxy_ingress_http_notebooks" {
  description = "ingress-http"

  security_group_id = "${aws_security_group.sentryproxy_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "registry_alb" {
  name        = "${var.prefix}-registry-alb"
  description = "${var.prefix}-registry-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-registry-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "registry_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "registry_alb_ingress_https_from_notebooks" {
  description = "ingress-https-from-notebooks"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "registry_alb_ingress_https_from_superset_multiuser_service" {
  description = "ingress-https-from-superset"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.superset_multiuser_service.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "registry_alb_egress_https_to_service" {
  description = "egress-https-to-service"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.registry_service.id}"

  type        = "egress"
  from_port   = "${local.registry_container_port}"
  to_port     = "${local.registry_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "registry_service" {
  name        = "${var.prefix}-registry-service"
  description = "${var.prefix}-registry-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-registry-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "registry_service_ingress_https_from_alb" {
  description = "ingress-https-from-alb"

  security_group_id = "${aws_security_group.registry_service.id}"
  source_security_group_id = "${aws_security_group.registry_alb.id}"

  type        = "ingress"
  from_port   = "${local.registry_container_port}"
  to_port     = "${local.registry_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "registry_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.registry_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_alb" {
  name        = "${var.prefix}-admin-alb"
  description = "${var.prefix}-admin-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_alb_ingress_https_from_whitelist" {
  description = "ingress-https-from-whitelist"

  security_group_id = "${aws_security_group.admin_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}", "${aws_eip.nat_gateway.public_ip}/32"]

  type       = "ingress"
  from_port  = "443"
  to_port    = "443"
  protocol   = "tcp"
}

resource "aws_security_group_rule" "admin_alb_ingress_http_from_whitelist" {
  description = "ingress-http-from-whitelist"

  security_group_id = "${aws_security_group.admin_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type       = "ingress"
  from_port  = "80"
  to_port    = "80"
  protocol   = "tcp"
}

resource "aws_security_group_rule" "admin_alb_ingress_icmp_host_unreachable_for_mtu_discovery_from_whitelist" {
  description = "ingress-icmp-host-unreachable-for-mtu-discovery-from-whitelist"

  security_group_id = "${aws_security_group.admin_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type      = "ingress"
  from_port = 3
  to_port   = 0
  protocol  = "icmp"
}

resource "aws_security_group_rule" "admin_alb_egress_https_to_admin_service" {
  description = "egress-https-to-admin-service"

  security_group_id = "${aws_security_group.admin_alb.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "egress"
  from_port   = "${local.admin_container_port}"
  to_port     = "${local.admin_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.admin_alb.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_redis" {
  name        = "${var.prefix}-admin-redis"
  description = "${var.prefix}-admin-redis"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-redis"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_redis_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.admin_redis.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_redis_ingress_from_admin_service" {
  description = "ingress-redis-from-admin-service"

  security_group_id = "${aws_security_group.admin_redis.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "6379"
  to_port     = "6379"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_service" {
  name        = "${var.prefix}-admin-service"
  description = "${var.prefix}-admin-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_service_egress_http_to_superset_lb" {
  description = "egress-http-to-gitlab-service"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.superset_multiuser_lb.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_to_gitlab_service" {
  description = "egress-http-to-gitlab-service"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.gitlab_service.id}"

  type        = "egress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_egress_https_to_ecr_api" {
  description = "egress-https-to-ecr-api"

  security_group_id = "${aws_security_group.gitlab_service.id}"
  source_security_group_id = "${aws_security_group.ecr_api.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_to_admin_service" {
  description = "egress-redis-to-admin-redis"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_redis.id}"

  type        = "egress"
  from_port   = "6379"
  to_port     = "6379"
  protocol    = "tcp"
}


resource "aws_security_group_rule" "admin_service_ingress_https_from_admin_alb" {
  description = "ingress-https-from-admin-alb"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_alb.id}"

  type        = "ingress"
  from_port   = "${local.admin_container_port}"
  to_port     = "${local.admin_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.admin_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_to_notebooks" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "egress"
  from_port   = "${local.notebook_container_port}"
  to_port     = "${local.notebook_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_dev_to_notebooks" {
  description = "egress-http-dev-to-notebooks"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "egress"
  from_port   = "${local.notebook_container_port_dev}"
  to_port     = "${local.notebook_container_port_dev}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_admin_db" {
  description = "egress-postgres-to-admin-db"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.admin.port}"
  to_port     = "${aws_db_instance.admin.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_db" {
  name        = "${var.prefix}-admin-db"
  description = "${var.prefix}-admin-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_db_ingress_postgres_from_admin_service" {
  description = "ingress-postgres-from-admin-service"

  security_group_id = "${aws_security_group.admin_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.admin.port}"
  to_port     = "${aws_db_instance.admin.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "notebooks" {
  name        = "${var.prefix}-notebooks"
  description = "${var.prefix}-notebooks"
  vpc_id      = "${aws_vpc.notebooks.id}"

  tags {
    Name = "${var.prefix}-notebooks"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "notebooks_ingress_https_from_admin" {
  description = "ingress-https-from-jupytehub"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type      = "ingress"
  from_port = "${local.notebook_container_port}"
  to_port   = "${local.notebook_container_port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_ingress_http_dev_from_admin" {
  description = "ingress-http-dev-from-jupytehub"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type      = "ingress"
  from_port = "${local.notebook_container_port_dev}"
  to_port   = "${local.notebook_container_port_dev}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_ingress_http_from_prometheus" {
  description = "ingress-https-from-prometheus-service"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.prometheus_service.id}"

  type      = "ingress"
  from_port = "${local.notebook_container_port + 1}"
  to_port   = "${local.notebook_container_port + 1}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.notebooks.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_ssh_to_gitlab_service" {
  description = "ingress-ssh-from-nlb"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.gitlab_service.id}"

  type        = "egress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_dns_tcp" {
  description = "egress-dns-tcp"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.dnsmasq.id}"

  type        = "egress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_dns_udp" {
  description = "egress-dns-udp"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.dnsmasq.id}"

  type        = "egress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

resource "aws_security_group" "cloudwatch" {
  name        = "${var.prefix}-cloudwatch"
  description = "${var.prefix}-cloudwatch"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-cloudwatch"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecr_dkr" {
  name        = "${var.prefix}-ecr-dkr"
  description = "${var.prefix}-ecr-dkr"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-ecr-dkr"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecr_api" {
  name        = "${var.prefix}-ecr-api"
  description = "${var.prefix}-ecr-api"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-ecr-api"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_admin-service" {
  description = "ingress-https-from-admin-service"

  security_group_id = "${aws_security_group.ecr_api.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_gitlab_runner" {
  description = "ingress-https-from-gitlab-runner"

  security_group_id = "${aws_security_group.ecr_api.id}"
  source_security_group_id = "${aws_security_group.gitlab_runner.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "ecr_api_ingress_https_from_notebooks" {
  description = "ingress-https-from-notebooks"

  security_group_id = "${aws_security_group.ecr_api.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "cloudwatch_ingress_https_from_all" {
  description = "ingress-https-from-everywhere"

  security_group_id = "${aws_security_group.cloudwatch.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "ecr_dkr_ingress_https_from_all" {
  description = "ingress-https-from-everywhere"

  security_group_id = "${aws_security_group.ecr_dkr.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "mirrors_sync" {
  name        = "${var.prefix}-mirrors-sync"
  description = "${var.prefix}-mirrors-sync"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-mirrors-sync"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mirrors_sync_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.mirrors_sync.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group" "healthcheck_alb" {
  name        = "${var.prefix}-healthcheck-alb"
  description = "${var.prefix}-healthcheck-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-healthcheck-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "healthcheck_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.healthcheck_alb.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "healthcheck_alb_ingress_https_from_all" {
  description = "ingress-https-from-all"

  security_group_id = "${aws_security_group.healthcheck_alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type       = "ingress"
  from_port  = "443"
  to_port    = "443"
  protocol   = "tcp"
}

resource "aws_security_group_rule" "healthcheck_alb_egress_https_to_healthcheck_service" {
  description = "egress-https-to-healthcheck-service"

  security_group_id = "${aws_security_group.healthcheck_alb.id}"
  source_security_group_id = "${aws_security_group.healthcheck_service.id}"
 
  type        = "egress"
  from_port   = "${local.healthcheck_container_port}"
  to_port     = "${local.healthcheck_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "healthcheck_service" {
  name        = "${var.prefix}-healthcheck_service"
  description = "${var.prefix}-healthcheck_service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-healthcheck_service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "healthcheck_service_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.healthcheck_service.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "healthcheck_service_ingress_https_from_healthcheck_alb" {
  description = "ingress-https-from-healthcheck-alb"

  security_group_id = "${aws_security_group.healthcheck_service.id}"
  source_security_group_id = "${aws_security_group.healthcheck_alb.id}"

  type        = "ingress"
  from_port   = "${local.healthcheck_container_port}"
  to_port     = "${local.healthcheck_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "healthcheck_service_egress_https_to_everywhere" {
  description = "ingress-https-from-healthcheck-alb"

  security_group_id = "${aws_security_group.healthcheck_service.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "prometheus_alb" {
  name        = "${var.prefix}-prometheus-alb"
  description = "${var.prefix}-prometheus-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-prometheus-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "prometheus_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.prometheus_alb.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "prometheus_alb_ingress_https_from_whitelist" {
  description = "ingress-https-from-all"

  security_group_id = "${aws_security_group.prometheus_alb.id}"
  cidr_blocks       = ["${var.prometheus_whitelist}", "${aws_eip.nat_gateway.public_ip}/32"]

  type       = "ingress"
  from_port  = "443"
  to_port    = "443"
  protocol   = "tcp"
}

resource "aws_security_group_rule" "prometheus_alb_egress_https_to_prometheus_service" {
  description = "egress-https-to-prometheus-service"

  security_group_id = "${aws_security_group.prometheus_alb.id}"
  source_security_group_id = "${aws_security_group.prometheus_service.id}"
 
  type        = "egress"
  from_port   = "${local.prometheus_container_port}"
  to_port     = "${local.prometheus_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "prometheus_service" {
  name        = "${var.prefix}-prometheus_service"
  description = "${var.prefix}-prometheus_service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-prometheus_service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "prometheus_service_ingress_https_from_prometheus_alb" {
  description = "ingress-https-from-prometheus-alb"

  security_group_id = "${aws_security_group.prometheus_service.id}"
  source_security_group_id = "${aws_security_group.prometheus_alb.id}"

  type        = "ingress"
  from_port   = "${local.prometheus_container_port}"
  to_port     = "${local.prometheus_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "prometheus_service_egress_https_to_everywhere" {
  description = "egress-https-from-prometheus-service"

  security_group_id = "${aws_security_group.prometheus_service.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "prometheus_service_egress_http_to_notebooks" {
  description = "egress-https-from-prometheus-service"

  security_group_id = "${aws_security_group.prometheus_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "egress"
  from_port   = "${local.notebook_container_port + 1}"
  to_port     = "${local.notebook_container_port + 1}"
  protocol    = "tcp"
}

resource "aws_security_group" "gitlab_service" {
  name        = "${var.prefix}-gitlab-service"
  description = "${var.prefix}-gitlab-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-gitlab-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_service_ingress_http_from_nlb" {
  description = "ingress-https-from-nlb"

  security_group_id = "${aws_security_group.gitlab_service.id}"
  cidr_blocks = ["${aws_eip.gitlab.private_ip}/32"]

  type        = "ingress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_http_from_admin_service" {
  description = "ingress-http-from-admin-service"

  security_group_id = "${aws_security_group.gitlab_service.id}"
  source_security_group_id =  "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_https_from_gitlab_runner" {
  description = "ingress-https-from-gitlab-runner"

  security_group_id = "${aws_security_group.gitlab_service.id}"
  source_security_group_id =  "${aws_security_group.gitlab_runner.id}"

  type        = "ingress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_ssh_from_nlb" {
  description = "ingress-ssh-from-nlb"

  security_group_id = "${aws_security_group.gitlab_service.id}"
  cidr_blocks = ["${aws_eip.gitlab.private_ip}/32"]

  type        = "ingress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_ingress_ssh_from_notebooks" {
  description = "ingress-ssh-from-nlb"

  security_group_id = "${aws_security_group.gitlab_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_egress_https_to_everwhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.gitlab_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_egress_postgres_to_gitlab_db" {
  description = "egress-postgres-to-gitlab-db"

  security_group_id       = "${aws_security_group.gitlab_service.id}"
  source_security_group_id = "${aws_security_group.gitlab_db.id}"

  type        = "egress"
  from_port   = "${aws_rds_cluster.gitlab.port}"
  to_port     = "${aws_rds_cluster.gitlab.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_service_egress_redis" {
  description = "egress-redis"

  security_group_id        = "${aws_security_group.gitlab_service.id}"
  source_security_group_id = "${aws_security_group.gitlab_redis.id}"

  type        = "egress"
  from_port   = "6379"
  to_port     = "6379"
  protocol    = "tcp"
}

resource "aws_security_group" "gitlab_redis" {
  name        = "${var.prefix}-gitlab-redis"
  description = "${var.prefix}-gitlab-redis"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-gitlab"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_gitlab_ingress_from_gitlab_service" {
  description = "ingress-gitlab-from-admin-service"

  security_group_id = "${aws_security_group.gitlab_redis.id}"
  source_security_group_id = "${aws_security_group.gitlab_service.id}"

  type        = "ingress"
  from_port   = "6379"
  to_port     = "6379"
  protocol    = "tcp"
}

resource "aws_security_group" "gitlab_db" {
  name        = "${var.prefix}-gitlab-db"
  description = "${var.prefix}-gitlab-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-gitlab-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_db_ingress_from_gitlab_service" {
  description = "egress-postgres-to-gitlab-db"

  security_group_id        = "${aws_security_group.gitlab_db.id}"
  source_security_group_id = "${aws_security_group.gitlab_service.id}"

  type        = "ingress"
  from_port   = "${aws_rds_cluster.gitlab.port}"
  to_port     = "${aws_rds_cluster.gitlab.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "gitlab-ec2" {
  name        = "${var.prefix}-gitlab-ec2"
  description = "${var.prefix}-gitlab-ec2"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-gitlab-ec2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab-ec2-egress-all" {
  description = "egress-everything-to-everywhere"

  security_group_id = "${aws_security_group.gitlab-ec2.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "0"
  to_port     = "65535"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab-ec2-ingress-ssh" {
  description = "egress-ssh"

  security_group_id = "${aws_security_group.gitlab-ec2.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "ingress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"
}

resource "aws_security_group" "gitlab_runner" {
  name        = "${var.prefix}-gitlab-runner"
  description = "${var.prefix}-gitlab-runner"
  vpc_id      = "${aws_vpc.notebooks.id}"

  tags {
    Name = "${var.prefix}-gitlab-runner"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_runner_egress_https_to_ecr_api" {
  description = "egress-https-to-ecr-api"

  security_group_id = "${aws_security_group.gitlab_runner.id}"
  source_security_group_id = "${aws_security_group.ecr_api.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "gitlab_runner_egress_dns_udp_dnsmasq" {
  description = "egress-dns-udp-dnsmasq"

  security_group_id = "${aws_security_group.gitlab_runner.id}"
  source_security_group_id = "${aws_security_group.dnsmasq.id}"

  type        = "egress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

# Connections to AWS package repos and GitLab
resource "aws_security_group_rule" "gitlab_runner_egress_http" {
  description = "egress-https"

  security_group_id = "${aws_security_group.gitlab_runner.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
}

# Connections to ECR and CloudWatch
resource "aws_security_group_rule" "gitlab_runner_egress_https" {
  description = "egress-https"

  security_group_id = "${aws_security_group.gitlab_runner.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "superset_multiuser_db" {
  name        = "${var.prefix}-superset-multiuser-db"
  description = "${var.prefix}-superset-multiuser-db"
  vpc_id      = "${aws_vpc.notebooks.id}"

  tags {
    Name = "${var.prefix}-superset-multiuser-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "superset_multiuser_db_ingress_postgres_superset_service" {
  description = "ingress-postgress-superset-service"

  security_group_id = "${aws_security_group.superset_multiuser_db.id}"
  source_security_group_id = "${aws_security_group.superset_multiuser_service.id}"

  type        = "ingress"
  from_port   = "5432"
  to_port     = "5432"
  protocol    = "tcp"
}

resource "aws_security_group" "superset_multiuser_service" {
  name        = "${var.prefix}-superset-multiuser-service"
  description = "${var.prefix}-superset-multiuser-service"
  vpc_id      = "${aws_vpc.notebooks.id}"

  tags {
    Name = "${var.prefix}-superset-multiuser-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "superset_service_ingress_http_superset_lb" {
  description = "ingress-superset-lb"

  security_group_id = "${aws_security_group.superset_multiuser_service.id}"
  source_security_group_id = "${aws_security_group.superset_multiuser_lb.id}"

  type        = "ingress"
  from_port   = "8000"
  to_port     = "8000"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "superset_service_egress_postgres_superset_db" {
  description = "egress-postgress-superset-db"

  security_group_id = "${aws_security_group.superset_multiuser_service.id}"
  source_security_group_id = "${aws_security_group.superset_multiuser_db.id}"

  type        = "egress"
  from_port   = "5432"
  to_port     = "5432"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "superset_multiuser_service_egress_https_registry_alb" {
  description = "egress-https-to-registry"

  security_group_id = "${aws_security_group.superset_multiuser_service.id}"
  source_security_group_id = "${aws_security_group.registry_alb.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "superset_multiuser_service_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.superset_multiuser_service.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "superset_multiuser_service_egress_dns_udp_to_dnsmasq" {
  description = "egress-dns-to-dnsmasq"

  security_group_id = "${aws_security_group.superset_multiuser_service.id}"
  source_security_group_id = "${aws_security_group.dnsmasq.id}"

  type        = "egress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

resource "aws_security_group" "superset_multiuser_lb" {
  name        = "${var.prefix}-superset-multiuser-lb"
  description = "${var.prefix}-superset-multiuser-lb"
  vpc_id      = "${aws_vpc.notebooks.id}"

  tags {
    Name = "${var.prefix}-superset-multiuser-lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "superset_lb_ingress_http_admin_service" {
  description = "ingress-http-admin-service"

  security_group_id = "${aws_security_group.superset_multiuser_lb.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "superset_lb_egress_http_superset_service" {
  description = "egress-http-superset-service"

  security_group_id = "${aws_security_group.superset_multiuser_lb.id}"
  source_security_group_id = "${aws_security_group.superset_multiuser_service.id}"

  type        = "egress"
  from_port   = "8000"
  to_port     = "8000"
  protocol    = "tcp"
}
