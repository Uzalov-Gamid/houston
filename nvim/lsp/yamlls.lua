-- YAML: checked against schemastore.org by file name — GitHub Actions,
-- docker-compose, Ansible, Helm values…; Kubernetes for k8s/ and manifests/
return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.ansible" },
  root_markers = { ".git" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
      schemas = { kubernetes = { "k8s/**/*.yaml", "k8s/**/*.yml", "manifests/**/*.yaml", "*.k8s.yaml" } },
      keyOrdering = false,
      format = { enable = true },
    },
  },
}
