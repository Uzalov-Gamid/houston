-- nginx configs (nginx-language-server, uv tool)
return {
  cmd = { "nginx-language-server" },
  filetypes = { "nginx" },
  root_markers = { "nginx.conf", ".git" },
}
