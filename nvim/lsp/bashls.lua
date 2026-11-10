-- Bash / sh scripts (bash-language-server, brew); uses shellcheck if installed
return {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash" },
  root_markers = { ".git" },
}
