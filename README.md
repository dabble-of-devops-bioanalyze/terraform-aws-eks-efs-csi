
<!-- markdownlint-disable -->
# terraform-aws-eks-efs-csi [![Latest Release](https://img.shields.io/github/release/cloudposse/terraform-example-module.svg)](https://github.com/cloudposse/terraform-example-module/releases/latest) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com) [![Discourse Forum](https://img.shields.io/discourse/https/ask.sweetops.com/posts.svg)](https://ask.sweetops.com/)
<!-- markdownlint-restore -->

![BioDeploy Logo](https://raw.githubusercontent.com/Dabble-of-DevOps-BioHub/biohub-info/master/logos/BioHub_v2-01.jpg)

<!--




  ** DO NOT EDIT THIS FILE
  **
  ** This file was automatically generated by the `build-harness`.
  ** 1) Make all changes to `README.yaml`
  ** 2) Run `make init` (you only need to do this once)
  ** 3) Run`make readme` to rebuild this file.
  **
  ** (We maintain HUNDREDS of open source projects. This is how we maintain our sanity.)
  **





-->

Terraform module to create the existing permissions and deploy a helm chart to allow an existing EKS cluster to access EFS storage.


---

This project is part of the ["BioDeploy"](https://www.dabbleofdevops.com/biohub) project, which aims to make High Performance Compute Architecture accessible to everyone.


It's 100% Open Source and licensed under the [APACHE2](LICENSE).






## Data Science Infrastructure on AWS

![BioHub Logo](https://raw.githubusercontent.com/Dabble-of-DevOps-BioHub/biohub-info/master/images/BioHub-Ecosystem-Data-Visualization.jpeg)






**IMPORTANT:** We do not pin modules to versions in our examples because of the
difficulty of keeping the versions in the documentation in sync with the latest released versions.
We highly recommend that in your code you pin the version to the exact version you are
using so that your infrastructure remains stable, and update versions in a
systematic way so that they do not catch you by surprise.

Also, because of a bug in the Terraform registry ([hashicorp/terraform#21417](https://github.com/hashicorp/terraform/issues/21417)),
the registry shows many of our inputs as required when in fact they are optional.
The table below correctly indicates which inputs are required.


For automated tests of the complete example using [bats](https://github.com/bats-core/bats-core) and [Terratest](https://github.com/gruntwork-io/terratest)
(which tests and deploys the example on AWS), see [test](test).

This module requires an existing EKS cluster. You can create it seperately and grab the `eks_cluster_id`, or bootstrap the EKS Cluster + EFS CSI claim below.

```hcl
provider "aws" {
  region = var.region
}

module "eks" {
  source = "dabble-of-devops-biodeploy/eks-autoscaling/aws"

  region = var.region
  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids

  oidc_provider_enabled = true
  cluster_encryption_config_enabled = true
  
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
      args        = ["eks", "get-token", "--cluster-name", module.jhub.eks_cluster_id]
      command     = "aws"
    }
  }
}


module "efs_csi" {
  depends_on = [
    module.eks,
  ]
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


```


## Examples

Here is an example of using this module:
- [`examples/complete`](https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi/) - complete example of using this module



<!-- markdownlint-disable -->
## Makefile Targets
```text
Available targets:

  help                                Help screen
  help/all                            Display help for all targets
  help/short                          This help short screen
  lint                                Lint terraform code

```
<!-- markdownlint-restore -->
<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_assumable_role_efs_csi"></a> [iam\_assumable\_role\_efs\_csi](#module\_iam\_assumable\_role\_efs\_csi) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 3.6.0 |
| <a name="module_kubernetes_volume_claims"></a> [kubernetes\_volume\_claims](#module\_kubernetes\_volume\_claims) | ./modules/kubernetes_volume_claims | n/a |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.efs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [helm_release.efs_csi](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account.efs_csi](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br>This is for some rare cases where resources want additional configuration of tags<br>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br>in the order they appear in the list. New attributes are appended to the<br>end of the list. The elements of the list are joined by the `delimiter`<br>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "descriptor_formats": {},<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "labels_as_tags": [<br>    "unset"<br>  ],<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {},<br>  "tenant": null<br>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br>Map of maps. Keys are names of descriptors. Values are maps of the form<br>`{<br>   format = string<br>   labels = list(string)<br>}`<br>(Type is `any` so the map values can later be enhanced to provide additional options.)<br>`format` is a Terraform format string to be passed to the `format()` function.<br>`labels` is a list of labels, in order, to pass to `format()` function.<br>Label values will be normalized before being passed to `format()` so they will be<br>identical to how they appear in `id`.<br>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_efs_mounts"></a> [efs\_mounts](#input\_efs\_mounts) | EFS Mounts and Volume Claims | <pre>list(object({<br>    name         = string<br>    fs_id        = string<br>    storage      = string<br>    access_modes = list(string)<br>    namespace    = string<br>  }))</pre> | `[]` | no |
| <a name="input_eks_cluster_id"></a> [eks\_cluster\_id](#input\_eks\_cluster\_id) | EKS Cluster Id - This cluster must exist. | `string` | n/a | yes |
| <a name="input_eks_cluster_oidc_issuer_url"></a> [eks\_cluster\_oidc\_issuer\_url](#input\_eks\_cluster\_oidc\_issuer\_url) | URL to the oidc issuer. The cluster must have been created with :   oidc\_provider\_enabled = true | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for keep the existing setting, which defaults to `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br>Does not affect keys of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br>set as tag values, and output by this module individually.<br>Does not affect values of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br>Default is to include all labels.<br>Tags with empty values will not be included in the `tags` output.<br>Set to `[]` to suppress all generated tags.<br>**Notes:**<br>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br>This is the only ID element not also included as a `tag`.<br>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br>Characters matching the regex will be removed from the ID elements.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-east-1"` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_efs_csi_helm_release"></a> [efs\_csi\_helm\_release](#output\_efs\_csi\_helm\_release) | n/a |
| <a name="output_iam_assumable_role_efs_csi"></a> [iam\_assumable\_role\_efs\_csi](#output\_iam\_assumable\_role\_efs\_csi) | n/a |
| <a name="output_kubernetes_storage_claims"></a> [kubernetes\_storage\_claims](#output\_kubernetes\_storage\_claims) | n/a |
<!-- markdownlint-restore -->




## Share the Love

Like this project? Please give it a ★ on [our GitHub](https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi)! (it helps **a lot**)



## Related Projects

Check out these related projects.

- [terraform-aws-eks-autoscaling](https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-autoscaling) - Terraform module to provision an Autoscaling EKS Cluster. Acts as a wrapper around cloudposse/terraform-aws-eks-cluster and cloudposse/terraform-aws-eks-node-groups
- [terraform-aws-eks-cluster](https://github.com/cloudposse/terraform-aws-eks-workers) - Terraform module to deploy an AWS EKS Cluster.
- [terraform-aws-eks-node-group](https://github.com/cloudposse/terraform-aws-eks-node-group) - Terraform module to provision an EKS Node Group
- [Zero to Kubernetes](https://zero-to-jupyterhub.readthedocs.io/) - JupyterHub allows users to interact with a computing environment through a webpage. As most devices have access to a web browser, JupyterHub makes it is easy to provide and standardize the computing environment for a group of people (e.g., for a class of students or an analytics team).

This project will help you set up your own JupyterHub on a cloud/on-prem k8s environment and leverage its scalable nature to support a large group of users. Thanks to Kubernetes, we are not tied to a specific cloud provider.

- [Dask Gateway](https://gateway.dask.org/) - Dask Gateway provides a secure, multi-tenant server for managing Dask clusters. It allows users to launch and use Dask clusters in a shared, centrally managed cluster environment, without requiring users to have direct access to the underlying cluster backend (e.g. Kubernetes, Hadoop/YARN, HPC Job queues, etc…).

- [DaskHub](https://github.com/dask/helm-chart/blob/main/daskhub/README.md) - This chart provides a multi-user, Dask-Gateway enabled JupyterHub. It combines the JupyterHub and Dask Gateway helm charts.

- [Dask](https://docs.dask.org/en/latest/) - Dask is a flexible library for parallel computing in Python.

- [terraform-aws-ec2-autoscale-group](https://github.com/cloudposse/terraform-aws-ec2-autoscale-group) - Terraform module to provision Auto Scaling Group and Launch Template on AWS
- [terraform-aws-ec2-instance](https://github.com/cloudposse/terraform-aws-ec2-instance) - Terraform module for providing a general purpose EC2 instance
- [terraform-aws-ec2-instance-group](https://github.com/cloudposse/terraform-aws-ec2-instance-group) - Terraform module for provisioning multiple general purpose EC2 hosts for stateful applications
- [terraform-null-label](https://github.com/cloudposse/terraform-null-label) - Terraform module designed to generate consistent names and tags for resources. Use terraform-null-label to implement a strict naming convention.


## References

For additional context, refer to some of these links.

- [Terraform Standard Module Structure](https://www.terraform.io/docs/modules/index.html#standard-module-structure) - HashiCorp's standard module structure is a file and directory layout we recommend for reusable modules distributed in separate repositories.
- [Terraform Module Requirements](https://www.terraform.io/docs/registry/modules/publish.html#requirements) - HashiCorp's guidance on all the requirements for publishing a module. Meeting the requirements for publishing a module is extremely easy.
- [Terraform `random_integer` Resource](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) - The resource random_integer generates random values from a given range, described by the min and max attributes of a given resource.
- [Terraform Version Pinning](https://www.terraform.io/docs/configuration/terraform.html#specifying-a-required-terraform-version) - The required_version setting can be used to constrain which versions of the Terraform CLI can be used with your configuration


## Help

**Got a question?** We got answers.

File a GitHub [issue](https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi/issues), send us an jillian@dabbleofdevops.com.

## Bioinformatics Infrastructure on AWS for Startups

I'll help you build your data science cloud infrastructure from the ground up so you can own it using open source software. Then I'll show you how to operate it and stick around for as long as you need us.

[Learn More](https://www.dabbleofdevops.com)

Work directly with me via email, slack, and video conferencing.

- **Scientific Workflow Automation and Optimization.** Got workflows that are giving you trouble? Let's work together to ensure that your analyses run with or without your scientists being fully caffeinated.
- **High Performance Compute Infrastructure.** Highly available, auto scaling clusters to analyze *all the (bioinformatics related!) things*. All setups are completely integrated with your workflow system of choice, whether that is Airflow, Prefect, Snakemake or Nextflow.
- **Kubernetes and AWS Batch Setup for Apache Airflow** Orchestrate your Bioinformatics Workflows with Apache Airflow. Get full auditing, SLA, logging and monitoring for your workflows running on AWS Batch.
- **High Performance Compute Setup that Int** You'll have built-in governance with accountability and audit logs for all changes.
- **Docker Images** Get advice and hands on training for your team to build complex software stacks onto docker images.
- **Training.** You'll receive hands-on training so your team can operate what we build.
- **Questions.** You'll have a direct line of communication between our teams via a Shared Slack channel.
- **Troubleshooting.** You'll get help to triage when things aren't working.
- **Bug Fixes.** We'll rapidly work with you to fix any bugs in our projects.

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing this project or help out with other projects, I would love to hear from you! Shoot me an email at jillian@dabbleofdevops.com.

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from "upstream" before making a pull request!



## Copyrights

Copyright © 2020-2021 [Dabble of DevOps, SCorp](https://www.dabbleofdevops.com)





## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

```text
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
```









## Trademarks

All other trademarks referenced herein are the property of their respective owners.



### Contributors

<!-- markdownlint-disable -->
|  [![Jillian Rowe][jerowe_avatar]][jerowe_homepage]<br/>[Jillian Rowe][jerowe_homepage] |
|---|
<!-- markdownlint-restore -->

  [jerowe_homepage]: https://github.com/jerowe
  [jerowe_avatar]: https://img.cloudposse.com/150x150/https://github.com/jerowe.png

Learn more at [Dabble of DevOps](https://www.dabbleofdevops.com)

  [logo]: https://cloudposse.com/logo-300x69.svg
  [docs]: https://cpco.io/docs?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=docs
  [website]: https://cpco.io/homepage?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=website
  [github]: https://cpco.io/github?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=github
  [jobs]: https://cpco.io/jobs?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=jobs
  [hire]: https://cpco.io/hire?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=hire
  [slack]: https://cpco.io/slack?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=slack
  [linkedin]: https://cpco.io/linkedin?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=linkedin
  [twitter]: https://cpco.io/twitter?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=twitter
  [testimonial]: https://cpco.io/leave-testimonial?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=testimonial
  [office_hours]: https://cloudposse.com/office-hours?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=office_hours
  [newsletter]: https://cpco.io/newsletter?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=newsletter
  [discourse]: https://ask.sweetops.com/?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=discourse
  [email]: https://cpco.io/email?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=email
  [commercial_support]: https://cpco.io/commercial-support?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=commercial_support
  [we_love_open_source]: https://cpco.io/we-love-open-source?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=we_love_open_source
  [terraform_modules]: https://cpco.io/terraform-modules?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=terraform_modules
  [readme_header_img]: https://cloudposse.com/readme/header/img
  [readme_header_link]: https://cloudposse.com/readme/header/link?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=readme_header_link
  [readme_footer_img]: https://cloudposse.com/readme/footer/img
  [readme_footer_link]: https://cloudposse.com/readme/footer/link?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=readme_footer_link
  [readme_commercial_support_img]: https://cloudposse.com/readme/commercial-support/img
  [readme_commercial_support_link]: https://cloudposse.com/readme/commercial-support/link?utm_source=github&utm_medium=readme&utm_campaign=dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi&utm_content=readme_commercial_support_link
  [share_twitter]: https://twitter.com/intent/tweet/?text=terraform-aws-eks-efs-csi&url=https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi
  [share_linkedin]: https://www.linkedin.com/shareArticle?mini=true&title=terraform-aws-eks-efs-csi&url=https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi
  [share_reddit]: https://reddit.com/submit/?url=https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi
  [share_facebook]: https://facebook.com/sharer/sharer.php?u=https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi
  [share_googleplus]: https://plus.google.com/share?url=https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi
  [share_email]: mailto:?subject=terraform-aws-eks-efs-csi&body=https://github.com/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi
  [beacon]: https://ga-beacon.cloudposse.com/UA-76589703-4/dabble-of-devops-biodeploy/terraform-aws-eks-efs-csi?pixel&cs=github&cm=readme&an=terraform-aws-eks-efs-csi
