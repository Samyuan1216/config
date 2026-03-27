local M = {}

local function get_path_info()
  local bufname = vim.api.nvim_buf_get_name(0)

  if bufname == "" then
    return {
      full     = nil,
      relative = nil,
      dir      = nil,
      filename = nil,
      win      = nil,
    }
  end

  local full_path = vim.fn.fnamemodify(bufname, ":p")
  
  -- WSL 转 Windows 路径逻辑
  local win_path = nil
  local wsl_distro = vim.env.WSL_DISTRO_NAME
  -- 判断是否在 WSL 环境中
  if wsl_distro and wsl_distro ~= "" then
    -- 将正斜杠替换为反斜杠
    local win_format_path = full_path:gsub("/", "\\")
    -- 拼接 Windows 网络驱动器格式
    win_path = string.format("\\\\wsl.localhost\\%s%s", wsl_distro, win_format_path)
  end

  return {
    full     = full_path,
    relative = vim.fn.fnamemodify(bufname, ":~:."),
    dir      = vim.fn.fnamemodify(bufname, ":p:h"),
    filename = vim.fn.fnamemodify(bufname, ":t"),
    win      = win_path,
  }
end

local function show_path(label, value, is_win_request)
  -- 针对请求 Windows 路径但不在 WSL 环境的特殊错误提示
  if not value and is_win_request then
    vim.notify(
      "⚠  当前环境不是 WSL，或者未获取到文件路径",
      vim.log.levels.WARN,
      { title = "Path" }
    )
    return
  elseif not value then
    vim.notify(
      "⚠  当前缓冲区没有关联的文件路径",
      vim.log.levels.WARN,
      { title = "Path" }
    )
    return
  end

  vim.fn.setreg("+", value)
  vim.fn.setreg('"', value)

  vim.notify(
    string.format("%s\n%s", label, value),
    vim.log.levels.INFO,
    { title = "Path" }
  )
end

function M.setup()
  vim.api.nvim_create_user_command("Path", function(opts)
    local args = opts.args:match("^%s*(.-)%s*$")
    local info = get_path_info()

    if args == "" or args == "full" then
      show_path("󰉿 完整路径", info.full)
    elseif args == "relative" then
      show_path("󰉹 相对路径", info.relative)
    elseif args == "dir" then
      show_path("󰉋 所在目录", info.dir)
    elseif args == "filename" then
      show_path("󰈙 文件名", info.filename)
    elseif args == "win" then
      show_path("󰖳 Windows 路径", info.win, true)
    else
      vim.notify(
        table.concat({
          "用法：",
          "  :Path             - 显示完整路径",
          "  :Path full        - 显示完整路径",
          "  :Path relative    - 显示相对路径",
          "  :Path dir         - 显示所在目录",
          "  :Path filename    - 显示文件名",
          "  :Path win         - 显示 Windows 路径 (仅 WSL 下可用)",
        }, "\n"),
        vim.log.levels.INFO,
        { title = "Path Help" }
      )
    end
  end, {
    nargs    = "?",
    desc     = "显示当前文件的路径信息",
    complete = function(arglead, _, _)
      -- 将 win 加入自动补全列表
      local choices = { "full", "relative", "dir", "filename", "win" }
      if arglead == "" then
        return choices
      end
      return vim.tbl_filter(function(item)
        return item:find("^" .. arglead) ~= nil
      end, choices)
    end,
  })
end

return M
