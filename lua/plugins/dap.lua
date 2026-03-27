---@diagnostic disable: undefined-field
return {
    -- 核心调试插件（如果你还没有添加）
    { "mfussenegger/nvim-dap" },
    { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
    { "theHamsta/nvim-dap-virtual-text", opts = {} },
    { "folke/edgy.nvim", opts = {} },

    {
        "mfussenegger/nvim-dap",
        keys = {
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Condition: ')) end, desc = "Conditional Breakpoint" },
            { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
            { "<leader>da", function() local d = require("dap"); d.continue({ before = d.continue }) end, desc = "Run with Args" },
            { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
            { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
            { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
            { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
            { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
            { "<leader>de", function() require("dapui").eval() end, desc = "Evaluate", mode = { "n", "v" } },
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            dapui.setup({
                icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
                mappings = {
                    expand = { "<CR>", "<2-LeftMouse>" },
                    open = "o",
                    remove = "d",
                    edit = "e",
                    repl = "r",
                    toggle = "t",
                },
                element_mappings = {},
                expand_lines = true,
                force_buffers = true,
                layouts = {
                    {
                        elements = {
                            { id = "scopes", size = 0.6 }, -- 变量窗口
                            { id = "watches", size = 0.4 }, -- 监视窗口
                        },
                        position = "right", -- 放在右侧
                        size = 40,          -- 宽度 40 列
                    },
                },
                floating = {
                    max_height = nil,
                    max_width = nil,
                    border = "single",
                    mappings = { close = { "q", "<Esc>" } },
                },
                render = {
                    indent = 1,
                    max_type_length = nil,
                    max_value_lines = 100,
                },
                controls = {
                    enabled = false, -- 关闭内置控制按钮
                    element = "repl",
                    icons = {
                        pause = "",
                        play = "",
                        step_into = "",
                        step_over = "",
                        step_out = "",
                        step_back = "",
                        run_last = "↺",
                        terminate = "□",
                        disconnect = "⏏",
                    },
                },
            })

            -- ===== 开始：自定义断点样式 =====
            -- 1. 定义高亮组
            vim.cmd("hi DapBreakpointColor guifg=#ff6b6b")
            vim.cmd("hi DapBreakpointConditionColor guifg=#ffd93d")
            vim.cmd("hi DapLogPointColor guifg=#6bcf7f")

            -- 2. 定义符号
            vim.fn.sign_define("DapBreakpoint", { text = "󰯮", texthl = "DapBreakpointColor" })
            vim.fn.sign_define("DapBreakpointCondition", { text = "󰯱", texthl = "DapBreakpointConditionColor" })
            vim.fn.sign_define("DapLogPoint", { text = "󰰌", texthl = "DapLogPointColor" })
            vim.fn.sign_define("DapStopped", { text = "⇒", texthl = "WarningMsg", linehl = "Visual" })

            -- 3. 自定义 UI 断点列表颜色
            vim.cmd("hi DapUIBreakpointsPath guifg=#61afef")
            vim.cmd("hi DapUIBreakpointsInfo guifg=#98c379")
            vim.cmd("hi DapUIBreakpointsCurrentLine guifg=#e5c07b gui=bold")
            -- ===== 结束：自定义断点样式 =====

            -- 自动打开/关闭 dapui
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            dap.adapters.cppdbg = {
                id = 'cppdbg',
                type = 'executable',
                command = vim.fn.stdpath("data") .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
                options = {
                    detached = false
                }
            }

            -- ===== 新增：C++ 调试运行配置 =====
            dap.configurations.cpp = {
                {
                    name = "Debug zsy.out (带文件重定向)",
                    type = "cppdbg",
                    request = "launch",

                    -- 1. 指定要调试的程序绝对路径 (当前工作区/zsy.out)
                    program = function()
                        return vim.fn.getcwd() .. "/zsy.out"
                    end,

                    -- 2. 指定工作目录为当前工作区根目录
                    cwd = function()
                        return vim.fn.getcwd()
                    end,

                    -- 3. 设置输入输出重定向
                    -- 在 Ubuntu (Linux) 下，GDB 会通过 Shell 启动程序，
                    -- 因此它能正确识别 "<", ">", "2>" 这样的重定向符号
                    args = function()
                        local cwd = vim.fn.getcwd()
                        return {
                            "<", cwd .. "/in.txt",
                            ">", cwd .. "/out.txt",
                            "2>", cwd .. "/debug.log"
                        }
                    end,

                    stopAtEntry = false,
                    setupCommands = {
                        {
                            description = "Enable pretty-printing for gdb",
                            text = "-enable-pretty-printing",
                            ignoreFailures = true,
                        },
                    },
                },
            }

            -- 让 C 语言也直接复用 C++ 的配置
            dap.configurations.c = dap.configurations.cpp
            -- ===== 结束：C++ 调试运行配置 =====
        end,
    },
}
