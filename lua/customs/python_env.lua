local M = {}

function M.resolve(root)
  local candidates = {}
  if root then
    candidates[#candidates + 1] = vim.fs.joinpath(root, ".venv", "bin", "python")
    candidates[#candidates + 1] = vim.fs.joinpath(root, "venv", "bin", "python")
  end

  for _, variable in ipairs({ "VIRTUAL_ENV", "CONDA_PREFIX" }) do
    local directory = vim.env[variable]
    if directory and directory ~= "" then
      candidates[#candidates + 1] = vim.fs.joinpath(directory, "bin", "python")
    end
  end

  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  for _, command in ipairs({ "python3", "python" }) do
    local path = vim.fn.exepath(command)
    if path ~= "" then
      return path
    end
  end
end

function M.before_init(_, config)
  -- Mutate the existing settings table: the LSP client already references it.
  config.settings = config.settings or {}
  config.settings.python = config.settings.python or {}
  if not config.settings.python.pythonPath then
    config.settings.python.pythonPath = M.resolve(config.root_dir)
  end
end

return M
