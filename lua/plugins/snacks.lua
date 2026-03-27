return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    indent = {
      enabled = true,

      -- 背景灰色普通缩进线
      indent = {
        priority = 1,
        enabled = true, -- enable indent guides
        char = "│",
        only_scope = false, -- only show indent guides of the scope
        only_current = false, -- only show indent guides in the current window
      },

      -- 当前所在代码块
      scope = {
        enabled = true, -- enable highlighting the current scope
        priority = 200,
        char = "│",
        underline = false, -- underline the start of the scope
        only_current = false, -- only show scope in the current window
        hl = "SnacksIndentScope", ---@type string|string[] hl group for scopes
      },
    },

    -- 替代telescope
    picker = {
      enabled = true,
      win = {
        input = {
          keys = {
            ["<C-k>"] = { "list_up", mode = { "i", "n" } },
            ["<C-j>"] = { "list_down", mode = { "i", "n" } },
          },
        },

        list = {
          keys = {
            ["<k>"] = { "list_up", mode = { "i", "n" } },
            ["<j>"] = { "list_down", mode = { "i", "n" } },
          },
        },
      },
    },

    notifier = {
      enabled = true,
      timeout = 2000,
    },

    scope = { enabled = true },
    dashboard = { enabled = true },
    input = { enabled = true },
    animate = {},
  },

    -- <leader>fb: 打开缓冲区列表（显示所有打开的缓冲区）
    -- <leader>ff: 查找文件（在当前项目中搜索文件）
    -- <leader>fg: 全文搜索（在文件中搜索文本内容）
    -- <leader>fp: 打开项目列表（切换或管理项目）
    -- <leader>fr: 查看最近打开的文件
    -- <leader>:: 查看命令历史记录
    -- <leader>/: 查看搜索历史记录
    -- <leader>sd: 显示诊断信息（错误、警告等）
    -- gd: 跳转到定义（LSP功能）
    -- gD: 跳转到声明（LSP功能）
    -- gr: 查找引用（LSP功能，nowait=true表示不等待后续按键）
    -- gI: 跳转到实现（LSP功能）
    -- gy: 跳转到类型定义（LSP功能）
    -- <leader>gs: 查看Git状态
    -- <leader>gd: 查看Git差异（按块显示）
    -- gai: 查找调用此函数的位置（入向调用）
    -- gao: 查找此函数调用的函数（出向调用）
    -- <leader>ss: 查看当前文件的符号
    -- <leader>sS: 查看整个工作区的符号
    -- <leader>nh: 查看通知历史
    keys = {
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Find Grep",
    },
    {
      "<leader>fp",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.recent()
      end,
      desc = "Recent",
    },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>/",
      function()
        Snacks.picker.search_history()
      end,
      desc = "Search History",
    },

    {
      "<leader>sd",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },

    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Goto Definition",
    },
    {
      "gD",
      function()
        Snacks.picker.lsp_declarations()
      end,
      desc = "Goto Declaration",
    },
    {
      "gr",
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "gI",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "gy",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "Goto T[y]pe Definition",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>gd",
      function()
        Snacks.picker.git_diff()
      end,
      desc = "Git Diff (Hunks)",
    },

    {
      "gai",
      function()
        Snacks.picker.lsp_incoming_calls()
      end,
      desc = "C[a]lls Incoming",
    },
    {
      "gao",
      function()
        Snacks.picker.lsp_outgoing_calls()
      end,
      desc = "C[a]lls Outgoing",
    },
    {
      "<leader>ss",
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = "LSP Symbols",
    },
    {
      "<leader>sS",
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = "LSP Workspace Symbols",
    },

    {
      "<leader>mh",
      function()
        Snacks.picker.notifications()
      end,
      desc = "Notification History",
    },
  },
}
