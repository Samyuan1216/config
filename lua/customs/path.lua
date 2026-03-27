local M = {}

local function get_path_info()
  local bufname = vim.api.nvim_buf_get_name(0)

  if bufname == "" then
    return {
      full     = nil,
      relative = nil,
      dir      = nil,
      filename = nil,
    }
  end

  return {
    full     = vim.fn.fnamemodify(bufname, ":p"),
    relative = vim.fn.fnamemodify(bufname, ":~:."),
    dir      = vim.fn.fnamemodify(bufname, ":p:h"),
    filename = vim.fn.fnamemodify(bufname, ":t"),
  }
end

local function show_path(label, value)
  if not value then
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
    else
      vim.notify(
        table.concat({
          "用法：",
          "  :Path             - 显示完整路径",
          "  :Path full        - 显示完整路径",
          "  :Path relative    - 显示相对路径",
          "  :Path dir         - 显示所在目录",
          "  :Path filename    - 显示文件名",
        }, "\n"),
        vim.log.levels.INFO,
        { title = "Path Help" }
      )
    end
  end, {
    nargs    = "?",
    desc     = "显示当前文件的路径信息",
    complete = function(arglead, _, _)
      local choices = { "full", "relative", "dir", "filename" }
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
