# Following: https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html#enable-windows-support

locals {
  vpc_resource_controller                      = "vpc-resource-controller"
  vpc_resource_controller_service_account_name = "vpc-resource-controller-2"
  vpc_admission_webhook_app                    = "vpc-admission-webhook"
  vpc_admission_webhook_service                = "${local.vpc_admission_webhook_app}-svc"
  vpc_admission_webhook_namespace              = "kube-system"
  vpc_admission_webhook_service_dns            = "${local.vpc_admission_webhook_service}.${local.vpc_admission_webhook_namespace}.svc"

}

# https://amazon-eks.s3.us-west-2.amazonaws.com/manifests/us-west-2/vpc-resource-controller/latest/vpc-resource-controller.yaml
resource "kubernetes_cluster_role" "vpc_resource_controller" {
  metadata {
    name = local.vpc_resource_controller
  }

  rule {
    api_groups = [""]
    resources = [
      "nodes",
      "nodes/status",
      "pods",
      "configmaps"
    ]
    verbs = [
      "update",
      "get",
      "list",
      "watch",
      "patch",
      "create"
    ]
  }
}

resource "kubernetes_cluster_role_binding" "vpc_resource_controller" {
  metadata {
    name = local.vpc_resource_controller
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.vpc_resource_controller
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vpc_resource_controller.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_service_account" "vpc_resource_controller" {
  metadata {
    name      = local.vpc_resource_controller_service_account_name
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "vpc_resource_controller" {
  metadata {
    name      = local.vpc_resource_controller
    namespace = "kube-system"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app   = local.vpc_resource_controller
        tier  = "backend"
        track = "stable"
      }
    }

    template {
      metadata {
        labels = {
          app   = local.vpc_resource_controller
          tier  = "backend"
          track = "stable"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.vpc_resource_controller.metadata[0].name
        container {
          image             = "602401143452.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/eks/windows-vpc-resource-controller:v0.2.7"
          name              = local.vpc_resource_controller
          command           = ["/vpc-resource-controller"]
          args              = ["-stderrthreshold=info"]
          image_pull_policy = "Always"

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = 61779
              scheme = "HTTP"
              host   = "127.0.0.1"
            }
            failure_threshold     = 5
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
          }
          security_context {
            privileged = true
          }
        }
        host_network = true
        node_selector = {
          "kubernetes.io/os"   = "linux"
          "kubernetes.io/arch" = "amd64"
        }
      }
    }
  }
}

# ./webhook-create-signed-cert.sh
resource "tls_private_key" "vpc_admission_webhook" {
  algorithm = "RSA"
}

resource "tls_cert_request" "vpc_admission_webhook" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.vpc_admission_webhook.private_key_pem

  subject {
    common_name = local.vpc_admission_webhook_service_dns
  }
  dns_names = [
    local.vpc_admission_webhook_service,
    "${local.vpc_admission_webhook_service}.${local.vpc_admission_webhook_namespace}",
    local.vpc_admission_webhook_service_dns
  ]
}

# create  server cert/key CSR and  send to k8s API
resource "kubernetes_certificate_signing_request" "vpc_admission_webhook" {
  metadata {
    name = local.vpc_admission_webhook_app
  }
  spec {
    usages  = ["digital signature", "key encipherment", "server auth"]
    request = tls_cert_request.vpc_admission_webhook.cert_request_pem
  }
  auto_approve = true
}

resource "kubernetes_secret" "vpc_admission_webhook_certs" {
  metadata {
    name      = "vpc-admission-webhook-certs"
    namespace = local.vpc_admission_webhook_namespace
  }
  data = {
    "key.pem"  = tls_private_key.vpc_admission_webhook.private_key_pem
    "cert.pem" = kubernetes_certificate_signing_request.vpc_admission_webhook.certificate
  }
}
# end webhook-create-signed-cert.sh

# vpc-admission-webhook-deployment
resource "kubernetes_service" "vpc_admission_webhook" {
  metadata {
    name      = local.vpc_admission_webhook_service
    namespace = local.vpc_admission_webhook_namespace
    labels = {
      app = local.vpc_admission_webhook_app
    }
  }
  spec {
    selector = {
      app = local.vpc_admission_webhook_app
    }
    port {
      port        = 443
      target_port = 443
    }
  }
}

resource "kubernetes_deployment" "vpc_admission_webhook" {
  metadata {
    name      = local.vpc_admission_webhook_app
    namespace = local.vpc_admission_webhook_namespace
    labels = {
      app = local.vpc_admission_webhook_app
    }
  }

  spec {
    replicas = 1
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = local.vpc_admission_webhook_app
      }
    }

    template {
      metadata {
        labels = {
          app = local.vpc_admission_webhook_app
        }
      }

      spec {
        container {
          image = "602401143452.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/eks/vpc-admission-webhook:v0.2.7"
          name  = local.vpc_admission_webhook_app
          args = [
            "-tlsCertFile=/etc/webhook/certs/cert.pem",
            "-tlsKeyFile=/etc/webhook/certs/key.pem",
            "--OSLabelSelectorOverride=windows",
            "-alsologtostderr",
            "-v=4",
            "2>&1"
          ]
          image_pull_policy = "Always"
          volume_mount {
            name       = "webhook-certs"
            mount_path = "/etc/webhook/certs"
            read_only  = true
          }

        }
        host_network = true
        node_selector = {
          "kubernetes.io/os"   = "linux"
          "kubernetes.io/arch" = "amd64"
        }
        volume {
          name = "webhook-certs"
          secret {
            secret_name = kubernetes_secret.vpc_admission_webhook_certs.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_mutating_webhook_configuration" "vpc_admission_webhook" {
  metadata {
    name = "vpc-admission-webhook-cfg"
    labels = {
      app = local.vpc_admission_webhook_app
    }
  }

  webhook {
    name = "vpc-admission-webhook.amazonaws.com"

    admission_review_versions = ["v1beta1"]

    client_config {
      service {
        namespace = local.vpc_admission_webhook_namespace
        name      = local.vpc_admission_webhook_service
        path      = "/mutate"
      }
      ca_bundle = base64decode(module.eks.cluster_certificate_authority_data)
    }

    rule {
      api_groups   = [""]
      api_versions = ["v1"]
      operations   = ["CREATE"]
      resources    = ["pods"]
    }

    failure_policy = "Ignore"
    side_effects   = "None"
  }
}
# end vpc-admission-webhook-deployment

resource "aws_autoscaling_group" "windows_workers" {
  name_prefix               = "${var.eks_cluster_name}-autoscaling-group-windows"
  desired_capacity          = var.eks_autoscaling_group_windows_desired_capacity
  max_size                  = var.eks_autoscaling_group_windows_max_size
  min_size                  = var.eks_autoscaling_group_windows_min_size
  force_delete              = false
  target_group_arns         = null
  load_balancers            = null
  service_linked_role_arn   = ""
  launch_configuration      = aws_launch_configuration.windows_workers.id
  vpc_zone_identifier       = concat(var.private_subnet_ids, var.public_subnet_ids)
  protect_from_scale_in     = false
  suspended_processes       = ["AZRebalance"]
  enabled_metrics           = []
  placement_group           = null
  termination_policies      = []
  max_instance_lifetime     = 0
  default_cooldown          = null
  health_check_type         = null
  health_check_grace_period = null
  capacity_rebalance        = false

  dynamic "tag" {
    for_each = concat(
      [
        {
          "key"                 = "Name"
          "value"               = "${var.eks_cluster_name}-autoscaling-group-windows-eks_asg"
          "propagate_at_launch" = true
        },
        {
          "key"                 = "kubernetes.io/cluster/${var.eks_cluster_name}"
          "value"               = "owned"
          "propagate_at_launch" = true
        },
        {
          "key"                 = "k8s.io/cluster/${var.eks_cluster_name}"
          "value"               = "owned"
          "propagate_at_launch" = true
        },
      ],
      [{
        key                 = "k8s.io/cluster-autoscaler/enabled"
        propagate_at_launch = true
        value               = "true"
        }, {
        key                 = "k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
        propagate_at_launch = true
        value               = "true"
      }]
    )
    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = tag.value.propagate_at_launch
    }
  }

  depends_on = [kubernetes_mutating_webhook_configuration.vpc_admission_webhook]
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

locals {
  launch_configuration_userdata_rendered = templatefile("${path.module}/templates/userdata_windows.tpl",
    {
      platform             = "windows"
      cluster_name         = var.eks_cluster_name
      endpoint             = module.eks.cluster_endpoint
      cluster_auth_base64  = module.eks.cluster_certificate_authority_data
      pre_userdata         = ""
      additional_userdata  = ""
      bootstrap_extra_args = ""
      kubelet_extra_args   = ""
    }
  )
}
resource "aws_iam_instance_profile" "windows_workers" {

  name_prefix = var.eks_cluster_name
  role        = module.eks.worker_iam_role_name
  path        = "/"

  tags = {}

  lifecycle {
    create_before_destroy = true
  }
}
data "aws_ami" "eks_worker_windows" {

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Core-EKS_Optimized-${local.cluster_version}-*"]
  }

  filter {
    name   = "platform"
    values = ["windows"]
  }

  most_recent = true

  owners = ["amazon"]
}

resource "aws_launch_configuration" "windows_workers" {
  name_prefix                 = "${var.eks_cluster_name}-autoscaling-group-windows"
  associate_public_ip_address = false
  security_groups             = [module.eks.worker_security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.windows_workers.id
  image_id                    = data.aws_ami.eks_worker_windows.id
  instance_type               = var.eks_instance_type
  key_name                    = ""
  user_data_base64            = base64encode(local.launch_configuration_userdata_rendered)
  ebs_optimized               = true
  enable_monitoring           = true
  spot_price                  = null
  placement_tenancy           = ""

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = null
  }

  root_block_device {
    encrypted             = false
    volume_size           = "100"
    volume_type           = "gp2"
    iops                  = "0"
    throughput            = null
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  # Prevent premature access of security group roles and policies by pods that
  # require permissions on create/destroy that depend on workers.
  depends_on = [
    module.eks
  ]
}
