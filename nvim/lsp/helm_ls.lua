-- Helm chart templates (helm-ls, brew); values.yaml goes to yamlls
return {
  cmd = { "helm_ls", "serve" },
  filetypes = { "helm" },
  root_markers = { "Chart.yaml" },
}
