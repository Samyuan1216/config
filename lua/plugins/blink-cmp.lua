return {
  "saghen/blink.cmp",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "onsails/lspkind-nvim",
    "nvim-tree/nvim-web-devicons",
    "L3MON4D3/LuaSnip",
  },

  version = "1.*",

  -- 添加 config 函数
  config = function()
    -- 加载自定义 snippets 目录
    require("luasnip.loaders.from_vscode").lazy_load({
      paths = { vim.fn.stdpath("config") .. "/snippets" }
    })

    -- 设置 blink.cmp
    require("blink.cmp").setup({
      -- 你的原始 opts 配置
      keymap = {
        preset = "none",
        ["<Tab>"] = {
          function(cmp)
            if cmp.is_visible() then
              return cmp.select_next()
            end
            if cmp.snippet_active({ direction = 1 }) then
              return cmp.snippet_forward()
            end
            return false
          end,
          "fallback",
        },
        ["<S-Tab>"] = {
          function(cmp)
            if cmp.is_visible() then
              return cmp.select_prev()
            end
            if cmp.snippet_active({ direction = -1 }) then
              return cmp.snippet_backward()
            end
            return false
          end,
          "fallback",
        },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Esc>"] = { "hide", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        list = {
          selection = {
            preselect = false,
          },
        },
        menu = {
          auto_show = true,
          scrollbar = false,
          border = "rounded",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None",

          draw = {
            components = {
              source_name = {
                text = function(ctx)
                  return "[" .. ctx.source_name .. "]"
                end,
                highlight = "Comment",
                width = {min = 10, max = 15},
              },
            },
            columns = {
              { "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
        },
        documentation = {
          auto_show = false,
          window = {
            border = "rounded",
            scrollbar = false,
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:FloatBorder,EndOfBuffer:BlinkCmpDoc",
          },
        },
      },

      signature = {
        enabled = true,
        window = {
          border = "rounded",
          scrollbar = false,
        },
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" },
    })
  end,

  -- 如果 blink.cmp 需要 opts，可以这样设置（但不与 config 函数同时使用）
  -- opts = {...},
}
