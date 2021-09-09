# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
# Using the new driver to attach the efs

locals {
  eks_cluster_oidc_issuer_url   = var.eks_cluster_oidc_issuer_url
  provider_url                  = replace(var.eks_cluster_oidc_issuer_url, "https://", "")
  efs_csi_service_account_name  = "efs-csi-controller-sa"
  efs_csi_policy_name           = "${var.eks_cluster_id}-AmazonEKS_EFS_CSI_Driver_Policy"
  efs_csi_role_name             = "${var.eks_cluster_id}-AmazonEKS_EFS_CSI_DriverRole"
  k8s_service_account_namespace = "kube-system"
  image_lookup = {
    "af-south-1"     = "877085696533.dkr.ecr.af-south-1.amazonaws.com/"
    "ap-east-1"      = "800184023465.dkr.ecr.ap-east-1.amazonaws.com/"
    "ap-northeast-1" = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com/"
    "ap-northeast-2" = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/"
    "ap-northeast-3" = "602401143452.dkr.ecr.ap-northeast-3.amazonaws.com/"
    "ap-south-1"     = "602401143452.dkr.ecr.ap-south-1.amazonaws.com/"
    "ap-southeast-1" = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com/"
    "ap-southeast-2" = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com/"
    "ca-central-1"   = "602401143452.dkr.ecr.ca-central-1.amazonaws.com/"
    "cn-north-1"     = "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn/"
    "cn-northwest-1" = "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn/"
    "eu-central-1"   = "602401143452.dkr.ecr.eu-central-1.amazonaws.com/"
    "eu-north-1"     = "602401143452.dkr.ecr.eu-north-1.amazonaws.com/"
    "eu-south-1"     = "590381155156.dkr.ecr.eu-south-1.amazonaws.com/"
    "eu-west-1"      = "602401143452.dkr.ecr.eu-west-1.amazonaws.com/"
    "eu-west-2"      = "602401143452.dkr.ecr.eu-west-2.amazonaws.com/"
    "eu-west-3"      = "602401143452.dkr.ecr.eu-west-3.amazonaws.com/"
    "me-south-1"     = "558608220178.dkr.ecr.me-south-1.amazonaws.com/"
    "sa-east-1"      = "602401143452.dkr.ecr.sa-east-1.amazonaws.com/"
    "us-east-1"      = "602401143452.dkr.ecr.us-east-1.amazonaws.com/"
    "us-east-2"      = "602401143452.dkr.ecr.us-east-2.amazonaws.com/"
    "us-gov-east-1"  = "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com/"
    "us-gov-west-1"  = "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com/"
    "us-west-1"      = "602401143452.dkr.ecr.us-west-1.amazonaws.com/"
    "us-west-2"      = "602401143452.dkr.ecr.us-west-2.amazonaws.com/"
  }
}


# https://github.com/kubernetes-sigs/aws-efs-csi-driver/issues/394
# https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.3.2/docs/iam-policy-example.json
# https://github.com/DrFaust92/terraform-kubernetes-efs-csi-driver

resource "aws_iam_policy" "efs_csi" {
  name        = local.efs_csi_policy_name
  description = "EKS AmazonEKS_EFS_CSI_Driver_Policy for cluster ${var.eks_cluster_id}"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticfilesystem:DescribeAccessPoints",
            "elasticfilesystem:DescribeFileSystems"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticfilesystem:CreateAccessPoint"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringLike" : {
              "aws:RequestTag/efs.csi.aws.com/cluster" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "elasticfilesystem:DeleteAccessPoint",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "aws:ResourceTag/efs.csi.aws.com/cluster" : "true"
            }
          }
        }
      ]
    }
  )
}

module "iam_assumable_role_efs_csi" {
  source       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version      = "3.6.0"
  create_role  = true
  role_name    = local.efs_csi_role_name
  provider_url = replace(local.eks_cluster_oidc_issuer_url, "https://", "")

  role_policy_arns = [
    aws_iam_policy.efs_csi.arn
  ]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.k8s_service_account_namespace}:${local.efs_csi_service_account_name}"
  ]
}

# ---
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: efs-csi-controller-sa
#   namespace: kube-system
#   labels:
#     app.kubernetes.io/name: aws-efs-csi-driver
#   annotations:
#     eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/AmazonEKS_EFS_CSI_DriverRole

# kubectl get sa -n kube-system
# kubectl describe sa -n kube-system efs-csi-controller-sa 
# arn:aws:iam::017309998751:role/AmazonEKS_EFS_CSI_DriverRole
resource "kubernetes_service_account" "efs_csi" {
  depends_on = [
    module.iam_assumable_role_efs_csi
  ]
  metadata {
    name      = local.efs_csi_service_account_name
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_efs_csi.this_iam_role_arn
    }
    labels = {
      "app.kubernetes.io/name" = "aws-efs-csi-driver"
    }
  }
  automount_service_account_token = true
}

# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
# https://github.com/kubernetes-sigs/aws-efs-csi-driver
# helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
# Get the right image for your region here - https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html

# kubectl get pods -n kube-system
# kubectl logs -f -n kube-system efs-csi-controller-5f7ff4464b-l9wlm csi-provisioner

resource "helm_release" "efs_csi" {
  depends_on = [
    module.iam_assumable_role_efs_csi
  ]
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  #   version    = "1.3.3"
  namespace = "kube-system"

  set {
    name = "image.repository"
    #TODO create lookup
    value = "${local.image_lookup[var.region]}eks/aws-efs-csi-driver"
  }
  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "controller.serviceAccount.name"
    value = local.efs_csi_service_account_name
  }
}


module "kubernetes_volume_claims" {
  depends_on = [
    helm_release.efs_csi
  ]
  source     = "./modules/kubernetes_volume_claims"
  efs_mounts = var.efs_mounts
}
