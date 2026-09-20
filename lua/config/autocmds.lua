vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("SystemVerilogFiletype", {
    clear = true,
  }),
  pattern = { "*.v", "*.vh", "*.sv", "*.svh" },
  callback = function()
    vim.bo.filetype = "systemverilog"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("DisableCommentContinuation", {
    clear = true,
  }),
  callback = function(args)
    -- Apply after filetype plugins finish updating buffer-local options.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_call(args.buf, function()
          vim.opt_local.formatoptions:remove({ "r", "o" })
        end)
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("PythonTreesitter", { clear = true }),
  pattern = "python",
  callback = function(args)
    vim.treesitter.start(args.buf)
  end,
})
