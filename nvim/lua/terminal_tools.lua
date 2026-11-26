local M = {}
local api = vim.api
local active = {}

local function geometry(title)
  local width = math.max(1, math.min(vim.o.columns - 2, math.floor(vim.o.columns * 0.92)))
  local height = math.max(1, math.min(vim.o.lines - 3, math.floor(vim.o.lines * 0.86)))
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "left",
  }
end

local function available(executable)
  if vim.fn.executable(executable) == 1 then return true end
  vim.notify(executable .. " is unavailable in PATH", vim.log.levels.WARN)
  return false
end

local function open(argv, title, cwd, env)
  local current = active[title]
  if current and api.nvim_win_is_valid(current.win) then
    api.nvim_set_current_win(current.win)
    vim.cmd.startinsert()
    return
  end
  if not available(argv[1]) then return end

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = api.nvim_open_win(buf, true, geometry(title))
  vim.wo[win].winhighlight = "Normal:NormalFloat,NormalNC:NormalFloat"
  active[title] = { win = win }

  local job = vim.fn.jobstart(argv, {
    cwd = cwd,
    env = env,
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if active[title] and active[title].win == win then active[title] = nil end
        if not api.nvim_win_is_valid(win) then return end
        api.nvim_win_close(win, true)
        if code ~= 0 then
          vim.notify(("%s exited with code %d"):format(title, code), vim.log.levels.WARN)
        end
      end)
    end,
  })
  if job <= 0 then
    active[title] = nil
    api.nvim_win_close(win, true)
    vim.notify("Cannot start " .. title, vim.log.levels.ERROR)
    return
  end
  vim.cmd.startinsert()
end

local function current_directory()
  if vim.bo.buftype == "" then
    local filename = api.nvim_buf_get_name(0)
    if filename ~= "" then
      local dir = vim.fs.dirname(filename)
      if vim.fn.isdirectory(dir) == 1 then return dir end
    end
  end
  return vim.fn.getcwd()
end

local function git()
  local root = vim.fs.root(current_directory(), ".git") or vim.fs.root(vim.fn.getcwd(), ".git")
  if not root then
    vim.notify("Open a file in a Git repository to use LazyGit", vim.log.levels.WARN)
    return
  end
  open({ "lazygit" }, "Git", root)
end

local docker_check_running = false
local function docker()
  if docker_check_running or not available("docker") or not available("lazydocker") then return end
  local directory = current_directory()
  local root = vim.fs.root(directory, { "compose.yml", "compose.yaml", "docker-compose.yml", "docker-compose.yaml" })
  docker_check_running = true
  local config = vim.fs.joinpath(vim.fs.dirname(vim.fn.stdpath("config")), "lazydocker")
  local function check(context)
    local cmd = { "docker", "info", "--format", "{{.ServerVersion}}" }
    if context then cmd = { "docker", "--context", context, "info", "--format", "{{.ServerVersion}}" } end
    vim.system(cmd, { timeout = 2500, text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 and not context and not vim.env.DOCKER_HOST and not vim.env.DOCKER_CONTEXT then
          check("colima")
          return
        end
        docker_check_running = false
        if result.code ~= 0 then
          vim.notify("Docker is unavailable. Start Colima or select a running Docker context.", vim.log.levels.WARN)
          return
        end
        open({ "lazydocker" }, "Docker", root or directory, { CONFIG_DIR = config, DOCKER_CONTEXT = context })
      end)
    end)
  end
  check()
end

local function sql()
  if type(vim.g.db) ~= "string" or vim.g.db == "" then
    vim.notify("No database connection is configured in vim.g.db", vim.log.levels.WARN)
    return
  end
  open({ "harlequin", "-a", "postgres", "--theme", "gruvbox", vim.g.db }, "SQL", current_directory())
end

function M.setup()
  local group = api.nvim_create_augroup("TerminalTools", { clear = true })
  api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      for title, current in pairs(active) do
        if api.nvim_win_is_valid(current.win) then
          api.nvim_win_set_config(current.win, geometry(title))
        end
      end
    end,
  })
  vim.keymap.set("n", "<leader>G", git, { desc = "Git (LazyGit)" })
  vim.keymap.set("n", "<leader>c", docker, { desc = "Docker (LazyDocker)" })
  vim.keymap.set("n", "<leader>H", sql, { desc = "SQL (Harlequin)" })
end

return M
