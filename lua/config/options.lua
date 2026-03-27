-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.mouse = "a"
vim.opt.laststatus = 3

-- 系统剪贴板
vim.opt.clipboard:append("unnamedplus")

-- 针对 WSL 环境的系统剪贴板支持
if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = 'clip.exe',
      ['*'] = 'clip.exe',
    },
    paste = {
      ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end

-- 默认新窗口右和下
vim.opt.splitright = true
vim.opt.splitbelow = true

-- 禁止自动注释续行
vim.opt.formatoptions:remove({ "c", "r", "o" })

vim.opt.cursorline = true -- 开启光标行高亮（可以只高亮行号）
vim.opt.cursorlineopt = "number" -- 只高亮行号，而不是整行

-- 全局 LSP 诊断配置
vim.diagnostic.config({
  signs = false, -- ❌ 左侧 gutter 不显示 E/W
  -- underline = true, -- 保留下划线标记
  -- virtual_text = true, -- 保留行内提示文字
  -- update_in_insert = false, -- 插入模式不更新（可选）
})

-- 创建 :H 命令，在新 tab 中打开帮助
vim.api.nvim_create_user_command("Hv", function(opts)
  vim.cmd("vertical help " .. (opts.args ~= "" and opts.args or ""))
end, { nargs = "*", complete = "help" })

vim.o.modeline = false

-- 使得左右键可以跨行
vim.o.whichwrap = vim.o.whichwrap .. "<>,h,l"

-- 禁止加载 netrw 核心
vim.g.loaded_netrw = 1

-- 禁止加载 netrw 的 plugin 层
vim.g.loaded_netrwPlugin = 1

-- 定义函数并使用 vim.cmd 执行 Vimscript
vim.cmd([[
function! OpenMarkdownPreview(url)
  let edge_path = '/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
  let cmd = 'silent !"' . edge_path . '" --app=' . shellescape(a:url, 1) . ' --new-window &'
  execute cmd
endfunction
]])

-- 设置插件变量
vim.g.mkdp_browserfunc = 'OpenMarkdownPreview'
vim.g.mkdp_auto_close = 0
vim.g.mkdp_echo_preview_url = 1
