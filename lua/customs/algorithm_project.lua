local M = {}

M.root = vim.fs.normalize(vim.fn.expand("~/code/Cpp_algorithm"))

function M.contains(path)
  if not path or path == "" then
    return false
  end

  path = vim.fs.normalize(path)
  return path == M.root or vim.startswith(path, M.root .. "/")
end

function M.current_buffer()
  return M.contains(vim.api.nvim_buf_get_name(0))
end

function M.require_current_buffer()
  if M.current_buffer() then
    return true
  end

  vim.notify("当前文件不在 Cpp_algorithm 项目中", vim.log.levels.WARN)
  return false
end

return M
