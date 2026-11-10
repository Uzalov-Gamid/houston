-- Ansible playbooks and roles (npm @ansible/ansible-language-server);
-- ansible-lint can be switched on below once installed
return {
  cmd = { "ansible-language-server", "--stdio" },
  filetypes = { "yaml.ansible" },
  root_markers = { "ansible.cfg", ".ansible-lint", ".git" },
  -- lint off until ansible-lint is installed (uv tool install ansible-lint), then set true
  settings = { ansible = { validation = { enabled = true, lint = { enabled = false } } } },
}
