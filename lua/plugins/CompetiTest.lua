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

-- 比赛接收配置与辅助函数
local contest_prompt_restore

local function stop_contest_prompt_override()
    if contest_prompt_restore then
        contest_prompt_restore()
        contest_prompt_restore = nil
    end
end

-- 根据 Competitive Companion 的 group 判断比赛平台。
local function contest_platform_root(task)
    local group = string.lower(tostring(task.group or ""))
    local judge = group:match("^(.-)%s+%-%s+") or group
    local problem_root = vim.fn.expand("~/code/C++/Problem")

    if judge:find("atcoder", 1, true) then
        return problem_root .. "/atcoder"
    elseif judge:find("codeforces", 1, true) or judge:find("codeforce", 1, true) then
        return problem_root .. "/codeforce"
    elseif judge:find("luogu", 1, true) then
        return problem_root .. "/luogu"
    end

    return problem_root
end

-- 让用户输入相对于平台目录的路径，例如 A/B。
local function resolve_contest_subdirectory(base, relative)
    relative = vim.trim(tostring(relative or "")):gsub("\\", "/")
    if relative == "" or relative == "." then
        return base
    end

    if relative:sub(1, 1) == "/" or relative:match("^%a:/") then
        return nil, "请输入相对路径，例如 A/B，不要输入绝对路径"
    end

    local parts = {}
    for part in relative:gmatch("[^/]+") do
        if part == ".." then
            return nil, "路径不能包含 .."
        elseif part ~= "." and part ~= "" then
            table.insert(parts, part)
        end
    end

    if #parts == 0 then
        return base
    end
    return base .. "/" .. table.concat(parts, "/")
end

-- 从题目名生成源文件名：A -> A.cpp，1000 -> 1000.cpp。
-- 对于 "A. xxx"、"A - xxx" 这类名称，取前面的题号。
local function contest_problem_filename(task, file_extension)
    local name = vim.trim(tostring(task.name or ""))
    name = name:gsub("%.cpp$", "")

    local short_name = name:match("^([%w]+)%s*[%.:%-]")
    if short_name then
        name = short_name
    end

    name = name:gsub("[<>:\"/\\|?*]", "_")
    name = name:gsub("%s+$", "")
    if name == "" then
        name = "problem"
    end

    return name .. "." .. file_extension
end

-- 将 snippets/cpp/init.json 中的 snippet body 生成 CompetiTest 可复制的 C++ 模板。
local function make_cpp_template()
    local snippet_path = vim.fn.expand("~/.config/nvim/snippets/cpp/init.json")
    if vim.fn.filereadable(snippet_path) ~= 1 then
        vim.notify("未找到 C++ snippet：" .. snippet_path, vim.log.levels.WARN)
        return false
    end

    local ok, snippets = pcall(vim.json.decode, table.concat(vim.fn.readfile(snippet_path), "\n"))
    if not ok or type(snippets) ~= "table" then
        vim.notify("无法解析 C++ snippet：" .. snippet_path, vim.log.levels.WARN)
        return false
    end

    local snippet = snippets["Print to console"]
    if not snippet then
        for _, value in pairs(snippets) do
            if type(value) == "table" then
                snippet = value
                break
            end
        end
    end

    if type(snippet) ~= "table" or type(snippet.body) ~= "table" then
        vim.notify("C++ snippet 中没有找到 body：" .. snippet_path, vim.log.levels.WARN)
        return false
    end

    local lines = {}
    for _, line in ipairs(snippet.body) do
        line = tostring(line)
        line = line:gsub("%${%d+:([^}]*)}", "%1")
        line = line:gsub("%${%d+}", "")
        line = line:gsub("%$%d+", "")
        table.insert(lines, line)
    end

    local cache_dir = vim.fn.stdpath("cache") .. "/competitest"
    vim.fn.mkdir(cache_dir, "p")
    local template_path = cache_dir .. "/init.cpp"
    vim.fn.writefile(lines, template_path)
    return template_path
end

local cpp_template_file = make_cpp_template()

-- CompetiTest 默认让用户输入完整目录；这里改成输入相对于平台目录的路径。
local function install_contest_directory_prompt()
    stop_contest_prompt_override()

    local widgets = require("competitest.widgets")
    local original_input = widgets.input
    local restored = false

    local function restore()
        if not restored then
            widgets.input = original_input
            restored = true
        end
    end

    contest_prompt_restore = restore
    widgets.input = function(title, default_text, border_style, callback_only, on_submit, on_close)
        if title ~= "Choose contest directory" or callback_only then
            return original_input(title, default_text, border_style, callback_only, on_submit, on_close)
        end

        restore()
        local base = default_text
        return original_input(
            "比赛目录（相对于 " .. base .. "，例如 A/B）",
            "",
            border_style,
            false,
            function(relative)
                local directory, err = resolve_contest_subdirectory(base, relative)
                if not directory then
                    vim.notify(err, vim.log.levels.ERROR)
                    if on_close then
                        on_close()
                    end
                    return
                end
                vim.fn.mkdir(directory, "p")
                on_submit(directory)
            end,
            on_close
        )
    end
end

-- 开始接收下一场完整比赛。
local function receive_contest()
    local config = require("competitest.config")
    local receive = require("competitest.receive")
    local cfg = config.load_local_config_and_extend(vim.fn.getcwd())

    install_contest_directory_prompt()
    local err = receive.start_receiving(
        "contest",
        cfg.companion_port,
        cfg.receive_print_message,
        cfg.receive_print_message,
        nil,
        cfg
    )

    if err then
        stop_contest_prompt_override()
        vim.notify("开始接收比赛失败：" .. err, vim.log.levels.ERROR)
    end
end

-- 辅助函数：停止接收并提示
local function stop_receiving()
    stop_contest_prompt_override()
    require("competitest.receive").stop_receiving()
    vim.notify("已停止接收测试用例/比赛", vim.log.levels.INFO)
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
        { "<leader>ct", receive_contest, desc = "接收整场比赛" },
        { "<leader>cs", stop_receiving, desc = "停止接收测试用例/比赛" },
        { "<leader>cx", clean_current_task_data, desc = "清理当前题目的所有测试文件和exe" },
        { "<leader>cX", clean_all_cp_data, desc = "清空 .cp_data 所有题目数据" },
        { "<leader>cu", "<cmd>CompetiTest show_ui<CR>", desc = "重新打开上一次的结果面板" },
    },
    opts = {
        -- 将编译的输出重定向到同级目录下的 .cp_data 中
        compile_command = {
            cpp = { exec = "g++", args = { "-std=c++23", "-Wall", "-Werror", "-g", "$(FNAME)", "-o", ".cp_data/$(FNOEXT).out" } },
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

        -- 接收整场比赛时：按平台自动选择 Problem/atcoder、Problem/codeforce、Problem/luogu，
        -- 其他平台放到 Problem；目录和题目文件名由下面两个函数决定。
        received_contests_directory = contest_platform_root,
        received_contests_problems_path = contest_problem_filename,
        received_contests_prompt_directory = true,
        received_contests_prompt_extension = false,
        received_files_extension = "cpp",
        template_file = cpp_template_file and { cpp = cpp_template_file } or false,
        evaluate_template_modifiers = false,
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
