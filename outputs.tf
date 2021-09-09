output "iam_assumable_role_efs_csi" {
  value = module.iam_assumable_role_efs_csi
}

output "efs_csi_helm_release" {
  value = helm_release.efs_csi
}

output "kubernetes_storage_claims" {
  value = module.kubernetes_volume_claims
}
