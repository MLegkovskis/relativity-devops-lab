output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "kubeconfig_tip" {
  value = "Kubeconfig updated (~/.kube/config). Try: kubectl get nodes && kubectl get ns"
}
