return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      -- "hrsh7th/cmp-nvim-lsp",
      "glepnir/lspsaga.nvim",
      "folke/trouble.nvim",
      "j-hui/fidget.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- =================== capabilities ===================
      -- local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      -- if ok then
      --   capabilities = cmp_lsp.default_capabilities(capabilities)
      -- end

      -- local capabilities = require("blink.cmp").get_lsp_capabilities()
      -- local capabilities = {}
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- =================== on_attach ===================
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }

        vim.notify("LSP attached: " .. client.name, vim.log.levels.INFO)

        -- 开启 inlay hints
        -- if client.server_capabilities.inlayHintProvider then
        --   vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        -- end
      end

      -- =================== C / C++ ===================
    vim.lsp.config["clangd"] = {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",   -- 启用 clang-tidy
        "--clang-tidy-checks=clang-analyzer-*,-misc-unused-*,-clang-diagnostic-unused-*",
      },
      init_options = {
        fallbackFlags = {
          -- 移除 Windows 目标，只保留 C++23 标准
          "-std=gnu++23",
          "-Wno-vla-cxx-extension",
        }
      },
      filetypes = { "c", "cpp", "objc", "objcpp", "cc" },
      root_markers = { ".clangd", "compile_commands.json", "CMakeLists.txt", ".git" },
      capabilities = capabilities,   -- 你的 capabilities 变量
      on_attach = on_attach,         -- 你的 on_attach 函数
    }
    vim.lsp.enable("clangd")

    -- ⭐ 核心魔法：拦截并过滤掉指定的 LSP 诊断错误
    local orig_publish_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]
    vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    if result and result.diagnostics then
      local filtered = {}
      for _, diagnostic in ipairs(result.diagnostics) do
        -- 如果错误的 code 是这两个，直接过滤掉，不放入 Neovim 缓冲区
        if diagnostic.code ~= "variable_object_no_init" and diagnostic.code ~= "-Wvla-cxx-extension" then
          table.insert(filtered, diagnostic)
        end
      end
      result.diagnostics = filtered
    end
    orig_publish_diagnostics(err, result, ctx, config)
    end

      -- =================== Python ===================
      vim.lsp.config["pyright"] = {
        cmd = { "pyright-langserver", "--stdio" },
        root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          python = {
            pythonPath = "/usr/bin/python3",
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
              reportAttributeAccessIssue = "none", -- ⭐ 解决 tf.keras
            },
          },
        },
      }
      vim.lsp.enable("pyright")

      -- =================== Lua ===================
      vim.lsp.config["lua_ls"] = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".git", "lua" },
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = {
                vim.fn.stdpath("config"),
                vim.fn.stdpath("data") .. "/lazy",
                vim.api.nvim_get_runtime_file("", true),
              },
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      }
      vim.lsp.enable("lua_ls")

    -- =================== marksman (Markdown) ===================
        vim.lsp.config["marksman"] = {
            cmd = { "marksman", "server" },
            filetypes = { "markdown" },
            root_markers = { ".git", ".marksman.toml", "README.md" },   -- 修正了 .marksman.toml
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
                -- 你可以在这里添加 Marksman 的特定设置，例如处理 wiki 链接的风格
                -- wiki = { style = "file-stem" }  -- 如果你使用 Obsidian，可能需要这行
            },
        }
        vim.lsp.enable("marksman")

      -- =================== lspsaga ===================
      require("lspsaga").setup({
        ui = { border = "rounded" },
        symbol_in_winbar = { enable = false },
        lightbulb = { enable = false, virtual_text = false },
      })

      -- =================== trouble ===================
      require("trouble").setup({
        win = { position = "bottom", height = 0.3 },
        icons = {
          error = "",
          warning = "",
          hint = "",
          information = "",
        },
        mode = "workspace_diagnostics",
        fold_open = "",
        fold_closed = "",
        action_keys = {
          close = "q",
          jump = { "<cr>", "<tab>" },
          refresh = "r",
        },
        use_diagnostic_signs = true,
      })
    end,
  },
}
