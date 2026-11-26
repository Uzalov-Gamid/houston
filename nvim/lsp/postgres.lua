-- SQL for Postgres: syntax errors, and with a postgres-language-server.jsonc
-- that points at a database — types, tables, columns (npm @postgrestools/postgrestools)
return {
  cmd = { "postgrestools", "lsp-proxy" },
  filetypes = { "sql" },
  root_markers = { "postgres-language-server.jsonc", "postgrestools.jsonc", ".git" },
}
