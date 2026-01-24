module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_endpoint_public_access_cidrs = [
    "0.0.0.0/0"
  ]

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      desired_size = 1
      min_size     = 1
      max_size     = 2

      instance_types = ["t3.medium"]
    }
  }

  access_entries = {
    admin = {
      principal_arn = data.aws_caller_identity.current.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

data "aws_caller_identity" "current" {}

resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  triggers = {
    cluster_endpoint = module.eks.cluster_endpoint
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
  }
}
