terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.59"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "test" {
  source            = "../../"
  eks_instance_type = "t3.small"
}

data "aws_eks_cluster" "cluster" {
  name = module.test.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.test.eks_cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "nginx"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
        node_selector = {
          "kubernetes.io/os"   = "linux"
          "kubernetes.io/arch" = "amd64"
        }
      }
    }
  }
}
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    selector = {
      app = kubernetes_deployment.nginx.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "windows" {
  metadata {
    name      = "windows"
    namespace = "default"
  }

  spec {
    selector {
      match_labels = {
        app = "windows"
      }
    }
    replicas = 1
    template {
      metadata {
        labels = {
          app = "windows"
        }
      }
      spec {
        container {
          image = "mcr.microsoft.com/windows/servercore/iis"
          name  = "windows"
          port {
            name           = "http"
            container_port = 80
          }
        }
        node_selector = {
          "kubernetes.io/os"   = "windows"
          "kubernetes.io/arch" = "amd64"
        }
      }
    }
  }
}

resource "kubernetes_service" "windows" {
  metadata {
    name      = "windows"
    namespace = "default"
  }
  spec {
    selector = {
      app = kubernetes_deployment.windows.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
