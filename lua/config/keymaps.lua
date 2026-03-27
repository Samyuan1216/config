-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- lua/keymaps.lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- leader 键
vim.g.mapleader = " " -- 空格为 leader

-- ---------- 插入模式 ---------- ---
map("i", "jk", "<ESC>")

-- ---------- 视觉模式 ---------- ---
-- 单行或多行移动
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- ---------- 正常模式 ---------- ---
-- 窗口
map("n", "<leader>sv", "<C-w>v") -- 水平新增窗口 
map("n", "<leader>sh", "<C-w>s") -- 垂直新增窗口

-- 全选
map("n", "<leader>a", "ggVG")

-- 下一个 / 上一个 Tab
map("n", "gt", ":BufferLineCycleNext<CR>", opts) -- 下一个 Tab
map("n", "gT", ":BufferLineCyclePrev<CR>", opts) -- 上一个 Tab

-- 快速跳转到指定 Tab（1~9）
for i = 1, 9 do
  map("n", "<leader>" .. i, ":BufferLineGoToBuffer " .. i .. "<CR>", opts)
end

-- 窗口导航（更明确的映射）
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- 使用 Ctrl + 方向键调整窗口大小
map('n', '<C-Up>', ':resize -2<CR>')
map('n', '<C-Down>', ':resize +2<CR>')
map('n', '<C-Left>', ':vertical resize -2<CR>')
map('n', '<C-Right>', ':vertical resize +2<CR>')

-- 关闭当前 Tab
map("n", "<leader>cc", ":bdelete!<CR>", opts)

-- 在终端模式中按 Esc 直接退出到普通模式
map("t", "<leader>jk", [[<C-\><C-n>]], opts)

-- 清除查找高亮
map("n", "<leader>nh", "<cmd>nohlsearch<CR>", opts)

-- 打开一个浮动终端
local float_term = require("customs.float_trem")
map("n", "<leader>ft", float_term.open, opts)

-- 打开诊断窗口
map("n", "<leader>xx", ":Trouble diagnostics toggle<CR>", opts)

-- 在你的 keymaps.lua 中添加
map("v", "<Tab>", ">", opts)
map("v", "<S-Tab>", "<", opts) -- Shift+Tab 减少缩进

-- 文件树
map("n", "<leader>e", ":Neotree toggle<CR>", opts)

-- 设置显示 / 不显示 tab
vim.keymap.set("n", "<leader>tb", function()
  if vim.o.showtabline == 0 then
    vim.o.showtabline = 2
  else
    vim.o.showtabline = 0
  end
end, { desc = "Toggle Bufferline" })
