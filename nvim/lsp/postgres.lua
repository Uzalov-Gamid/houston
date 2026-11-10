-- SQL for Postgres: syntax errors, and with a postgrestools.jsonc that
-- points at a database — types, tables, columns (npm @postgrestools/postgrestools)
return {
  cmd = { "postgrestools", "lsp-proxy" },
  filetypes = { "sql" },
  root_markers = { "postgrestools.jsonc", ".git" },
}
