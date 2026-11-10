-- docker-compose / compose.yaml: services, images, ports (npm
-- @microsoft/compose-language-service); yamlls checks the schema alongside
return {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml.docker-compose" },
  root_markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml", ".git" },
}
