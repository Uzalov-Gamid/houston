-- Python: types, imports, errors (pyright, brew)
return {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".venv", ".git" },
  settings = { python = { analysis = { typeCheckingMode = "basic", autoSearchPaths = true } } },
}
