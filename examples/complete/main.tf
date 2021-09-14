provider "aws" {
  region = var.region
}

module "eks" {
  # version = "1.10.0"
  source = "dabble-of-devops-biodeploy/eks-autoscaling/aws"

  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  # Trying to reconcile eks version vs kubectl version
  # kubernetes_version = "1.21.2"

  oidc_provider_enabled             = true
  cluster_encryption_config_enabled = true
  # eks_worker_groups                 = var.eks_worker_groups
  eks_node_groups = var.eks_node_groups

  # This should get us auto discovery!
  eks_node_group_autoscaling_enabled            = true
  eks_worker_group_autoscaling_policies_enabled = true

  context = module.this.context
}

data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.eks.eks_cluster_id
    kubernetes_config_map_id = module.eks.eks_cluster.kubernetes_config_map_id
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.eks_cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_id]
      command     = "aws"
    }
  }
}

resource "null_resource" "kubectl_update" {
  depends_on = [
    module.eks,
  ]
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws eks --region $AWS_REGION update-kubeconfig --name $NAME"
    environment = {
      AWS_REGION = var.region
      NAME       = module.eks.eks_cluster_id
    }
  }
}


module "efs_csi" {
  providers = {
    aws        = aws
    kubernetes = kubernetes
    helm       = helm
  }
  source                      = "dabble-of-devops-biodeploy/eks-efs-csi/aws"
  region                      = var.region
  eks_cluster_id              = module.eks.eks_cluster_id
  eks_cluster_oidc_issuer_url = module.eks.eks_cluster_identity_oidc_issuer
  efs_mounts                  = var.efs_mounts
}

