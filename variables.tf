variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "eks_cluster_id" {
  description = "EKS Cluster Id - This cluster must exist."
  type        = string
}

variable "eks_cluster_oidc_issuer_url" {
  description = "URL to the oidc issuer. The cluster must have been created with :   oidc_provider_enabled = true"
  type        = string
}

variable "efs_mounts" {
  type = list(object({
    name         = string
    fs_id        = string
    storage      = string
    access_modes = list(string)
    namespace    = string
  }))
  description = "EFS Mounts and Volume Claims"
  default     = []
}

