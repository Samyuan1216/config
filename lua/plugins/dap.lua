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

            -- 配置 cpptools 适配器（指向 OpenDebugAD7.exe）
            dap.adapters.cppdbg = {
                id = 'cppdbg',
                type = 'executable',
                command = 'C:\\tools\\cpptools\\extension\\debugAdapters\\bin\\OpenDebugAD7.exe',
                options = {
                    detached = false
                }
            }

            -- ===== 新增：Windows C++ 同目录调试运行配置 =====
            dap.configurations.cpp = {
                {
                    name = "Debug Windows (同目录带文件重定向)",
                    type = "cppdbg",
                    request = "launch",

                    -- 1. 动态获取当前激活文件所在目录，指向该目录下的 zsy.exe
                    program = function()
                        local dir = vim.fn.expand('%:p:h')
                        -- 转换路径分隔符以防 Windows 路径格式问题
                        return dir:gsub("\\", "/") .. '/zsy.exe'
                    end,

                    -- 2. 将调试时的工作目录设置为当前文件所在目录
                    cwd = function()
                        return vim.fn.expand('%:p:h')
                    end,

                    -- 3. 重定向输入输出到同目录下的文本文件
                    args = function()
                        local dir = vim.fn.expand('%:p:h'):gsub("\\", "/")
                        return {
                            "<", dir .. "/in.txt",
                            ">", dir .. "/out.txt",
                            "2>", dir .. "/debug.log"
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
                    -- 注意：Windows 下如果你的 gdb.exe 没有添加进系统的 PATH 环境变量，
                    -- 你需要取消下面这行的注释，并填入你 MinGW gdb.exe 的绝对路径
                    -- miDebuggerPath = "C:\\msys64\\mingw64\\bin\\gdb.exe",
                },
            }

            -- 让 C 语言也复用这套配置
            dap.configurations.c = dap.configurations.cpp
            -- ===== 结束：Windows C++ 调试运行配置 =====
        end,
    },
}
