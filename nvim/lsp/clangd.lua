-- C (and C++): clangd from the Xcode command line tools
return {
  cmd = { "clangd", "--background-index", "--header-insertion=never" },
  filetypes = { "c", "cpp" },
  root_markers = { "compile_commands.json", ".clangd", ".clang-format", "Makefile", ".git" },
}
