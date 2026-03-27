-- ~/.config/nvim/lua/plugins/hop.lua
return {
  "phaazon/hop.nvim",
  branch = "v2",                     -- 使用 v2 版本
  event = "VeryLazy",                 -- 可选：延迟加载，提升启动速度
  config = function()
    -- 必须调用 setup 初始化
    require("hop").setup()

    -- 设置常用的跳转快捷键（可根据个人习惯调整）
    local hop = require("hop")
    local directions = require("hop.hint").HintDirection

    -- 跳转到任意单词
    vim.keymap.set("n", "<leader>hw", "<cmd>HopWord<CR>", { desc = "Hop to word" })
    -- 跳转到当前行任意位置
    vim.keymap.set("n", "<leader>hl", "<cmd>HopLine<CR>", { desc = "Hop to line" })
  end,
}
