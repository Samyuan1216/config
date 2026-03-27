-- plugins/theme.lua

-- 定义你想用的主题名字
-- 可选: "tokyonight" 或 "catppuccin"
local active_theme = "onedarkpro"

-- 定义主题配置表
local themes = {
  onedarkpro = {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first

    config = function()
      require("onedarkpro").setup({
        options = {
          transparency = true,
        },

        styles = {
          types = "NONE",
          methods = "NONE",
          numbers = "NONE",
          strings = "NONE",
          comments = "italic",
          keywords = "italic",
          constants = "NONE",
          functions = "bold",
          operators = "NONE",
          variables = "NONE",
          parameters = "NONE",
          conditionals = "italic",
          virtual_text = "NONE",
        },
      })

      -- somewhere in your config:
      vim.cmd("colorscheme vaporwave")
    end,
  },
}

-- 返回当前激活的主题配置
return { themes[active_theme] }