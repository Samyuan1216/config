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
