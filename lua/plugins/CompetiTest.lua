-- ~/.config/nvim/lua/plugins/competitest.lua

-- 辅助函数：清理当前文件相关的所有生成文件
local function clean_current_task_data()
    local base_name = vim.fn.expand("%:t:r")
    local cp_dir = vim.fn.expand("%:p:h") .. "/.cp_data" -- 获取当前文件所在目录下的 .cp_data
    if base_name == "" then return end

    local pattern = cp_dir .. "/" .. base_name .. "*"
    local files = vim.split(vim.fn.glob(pattern), "\n")

    local count = 0
    for _, file in ipairs(files) do
        if file ~= "" and vim.fn.filereadable(file) == 1 then
            vim.fn.delete(file)
            count = count + 1
        end
    end
    vim.notify("已清理 " .. count .. " 个该题的临时文件与可执行文件", vim.log.levels.INFO)
end

-- 辅助函数：一键清空当前工作区下的整个 .cp_data 文件夹
local function clean_all_cp_data()
    local cp_dir = vim.fn.expand("%:p:h") .. "/.cp_data"
    local choice = vim.fn.confirm("确定要清空当前目录下的 .cp_data 吗？", "&Yes\n&No", 2)
    if choice == 1 then
        vim.fn.delete(cp_dir, "rf")
        vim.fn.mkdir(cp_dir, "p")
        vim.notify("已成功清空 .cp_data 目录！", vim.log.levels.INFO)
    else
        vim.notify("已取消清空操作", vim.log.levels.INFO)
    end
end

return {
    "xeluxee/competitest.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    cmd = "CompetiTest",
    keys = {
        { "<leader>ca", "<cmd>CompetiTest run<CR>", desc = "编译并运行所有测试用例" },
        { "<leader>ci", "<cmd>CompetiTest add_testcase<CR>", desc = "添加/编辑测试用例" },
        { "<leader>ce", "<cmd>CompetiTest edit_testcase<CR>", desc = "编辑当前测试用例" },
        { "<leader>cd", "<cmd>CompetiTest delete_testcase<CR>", desc = "选择删除某个测试用例" },
        { "<leader>cr", "<cmd>CompetiTest receive testcases<CR>", desc = "从浏览器接收测试用例" },
        { "<leader>cx", clean_current_task_data, desc = "清理当前题目的所有测试文件和exe" },
        { "<leader>cX", clean_all_cp_data, desc = "清空 .cp_data 所有题目数据" },
        { "<leader>cu", "<cmd>CompetiTest show_ui<CR>", desc = "重新打开上一次的结果面板" },
    },
    opts = {
        -- 将编译的输出重定向到同级目录下的 .cp_data 中
        compile_command = {
            cpp = { exec = "g++", args = { "-std=c++23", "-Wall", "-Werror", "-g", "-O2", "$(FNAME)", "-o", ".cp_data/$(FNOEXT).out" } },
        },
        -- 运行指令去 .cp_data 中找
        run_command = {
            cpp = { exec = "./.cp_data/$(FNOEXT).out" },
        },
        runner_ui = {
            interface = "popup",
        },
        -- 核心修复：相对路径配置
        testcases_directory = ".cp_data",
        testcases_use_single_file = false,
        testcases_input_file_format = "$(FNOEXT)_input$(TCNUM).txt",
        testcases_output_file_format = "$(FNOEXT)_output$(TCNUM).txt",
    },
    config = function(_, opts)
        require("competitest").setup(opts)
        -- 每次打开 cpp 文件时，自动在同级目录下创建 .cp_data (如果不存在)
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "*.cpp",
            callback = function()
                local cp_dir = vim.fn.expand("%:p:h") .. "/.cp_data"
                if vim.fn.isdirectory(cp_dir) == 0 then
                    vim.fn.mkdir(cp_dir, "p")
                end
            end,
        })
    end
}
