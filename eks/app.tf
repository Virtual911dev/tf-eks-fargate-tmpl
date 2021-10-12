
resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "${var.name}-eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "fp-default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnets.*.id

  selector {
    namespace = "default"
  }

  selector {
    namespace = "kube-system"
  }

  selector {
    namespace = "lynx-micro"
  }

  timeouts {
    create = "30m"
    delete = "60m"
  }
}
/*
resource "null_resource" "resetdns" {
 

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = pathexpand("~/.kube/config")
    }
    command = <<EOT
      kubectl  patch deployment/coredns  --namespace kube-system   --type=json   -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'
    EOT
  }
}
*/

resource "kubernetes_namespace" "example" {
  metadata {
    labels = {
      app = "lynx-app"
    }

    name = "lynx-micro"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "lynx-app"
    namespace = "lynx-micro"
    labels    = {
      app = "lynx-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "lynx-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "lynx-app"
        }
      }

      spec {
        container {
          image = "661199018908.dkr.ecr.us-east-2.amazonaws.com/lynx-fh:v1"
          name  = "lynx-app"

          port {
            container_port = 8080
          }
        }
      }
    }
  }

  depends_on = [aws_eks_fargate_profile.main]
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "service-1"
    namespace = "lynx-micro"
  }
  spec {
    selector = {
      app = "lynx-app"
    }

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.app]
}

resource "kubernetes_ingress" "app" {
  metadata {
    name      = "lynx-ingress"
    namespace = "lynx-micro"
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
    labels = {
        "app" = "lynx-ingress"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = "service-1"
            service_port = 8080
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.app]
}