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
                wrap = true,
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

            -- ===== 开始：C++ 调试运行配置 =====
            dap.configurations.cpp = {
                {
                    name = "Debug 当前文件 (配合相对目录 .cp_data)",
                    type = "cppdbg",
                    request = "launch",

                    -- 1. 指定要调试的程序：当前代码目录下的 .cp_data 文件夹中
                    program = function()
                        -- 动态获取当前文件目录，并在里面寻找 .cp_data/文件名.out
                        local cp_dir = vim.fn.expand("%:p:h") .. "/.cp_data"
                        local exe_path = cp_dir .. "/" .. vim.fn.expand("%:t:r") .. ".out"

                        if vim.fn.filereadable(exe_path) == 0 then
                            vim.notify("未找到可执行文件: " .. exe_path .. "\n请先运行 <leader>ca 编译", vim.log.levels.ERROR)
                            return nil
                        end
                        return exe_path
                    end,

                    -- 2. 指定工作目录为当前代码所在的文件夹
                    cwd = function()
                        return vim.fn.expand("%:p:h")
                    end,

                    -- 3. 动态设置输入输出重定向，去 .cp_data 里读取
                    args = function()
                        local cp_dir = vim.fn.expand("%:p:h") .. "/.cp_data"
                        local tc_num = vim.fn.input("输入要调试的测试用例编号 (默认 0): ")
                        if tc_num == "" then tc_num = "0" end

                        local base_name = vim.fn.expand("%:t:r")
                        -- 拼接 .cp_data 下的输入输出文件路径
                        local input_file = cp_dir .. "/" .. base_name .. "_input" .. tc_num .. ".txt"
                        local output_file = cp_dir .. "/" .. base_name .. "_debug_out.txt"
                        local error_file = cp_dir .. "/" .. base_name .. "_debug_err.log"

                        if vim.fn.filereadable(input_file) == 0 then
                            vim.notify("\n找不到测试用例文件: " .. input_file, vim.log.levels.WARN)
                        end

                        return {
                            "<", input_file,
                            ">", output_file,
                            "2>", error_file
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

            dap.configurations.c = dap.configurations.cpp
            -- ===== 结束：C++ 调试运行配置 =====
        end,
    },
}
