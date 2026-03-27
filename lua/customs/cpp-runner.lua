local M = {}

local default_configuration = {
    fixed_dir = "/home/samyuan/code/C++/",
    exec_name = "zsy.out",
    input_file = "in.txt",
    output_file = "out.txt",
    error_file = "debug.log",

    compile_command = "g++ % -g -o '{exec}' -std=c++23 -Wall -Werror",
    run_command = "'{exec}' < '{input}' > '{output}' 2> '{error}'",
    compile_run_command = "g++ % -g -o '{exec}' -std=c++23 -Wall -Werror 2> '{error}' && '{exec}' < '{input}' > '{output}' 2> '{error}'",
    -- 新增：带 O2 优化的编译运行命令
    compile_run_o2_command = "g++ % -g -O2 -o '{exec}' -std=c++23 -Wall -Werror 2> '{error}' && '{exec}' < '{input}' > '{output}' 2> '{error}'",

    float_window_width = 0.7,
    float_window_height = 0.7,
    float_window_border = "rounded",
}

local edit_windows = {}

local function get_full_path(config, file)
    return config.fixed_dir .. file
end

-- 创建只读浮动窗口
local function create_readonly_float_window(content, title)
    local width = math.floor(vim.o.columns * default_configuration.float_window_width)
    local height = math.floor(vim.o.lines * default_configuration.float_window_height)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = default_configuration.float_window_border,
        title = title,
        title_pos = "center",
    })

    if content then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
    end

    vim.api.nvim_buf_set_option(buf, "readonly", true)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "text")
    return buf, win
end

-- 创建可编辑浮动窗口
local function create_editable_float_window(content, title, filepath, _)
    local width = math.floor(vim.o.columns * default_configuration.float_window_width)
    local height = math.floor(vim.o.lines * default_configuration.float_window_height)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local buf
    if filepath then
        buf = vim.fn.bufadd(filepath)
        vim.fn.bufload(buf)
    else
        buf = vim.api.nvim_create_buf(true, true)
        if content then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
        end
    end

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = default_configuration.float_window_border,
        title = title,
        title_pos = "center",
    })

    vim.api.nvim_buf_set_option(buf, "filetype", "text")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "modified", false)

    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        callback = function()
            if filepath then edit_windows[filepath] = nil end
        end
    })

    if filepath then
        edit_windows[filepath] = { buf = buf, win = win, filepath = filepath }
    end

    return buf, win
end

local function read_file(filepath)
    local success, content = pcall(vim.fn.readfile, filepath)
    if success then return table.concat(content, "\n") end
    return ""
end

local function write_file(filepath, content)
    local dir = vim.fn.fnamemodify(filepath, ":h")
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile(vim.split(content or "", "\n"), filepath)
end

local function execute_command(cmd)
    local current_dir = vim.fn.getcwd()
    vim.fn.chdir(default_configuration.fixed_dir)
    local output = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    vim.fn.chdir(current_dir)

    if exit_code ~= 0 and output ~= "" then
        if output:match("%S") then
            vim.notify("Shell执行错误:\n" .. output, vim.log.levels.ERROR)
        end
    end
    return exit_code == 0
end

-- [新增逻辑] 通用的编译并运行函数，支持传入不同的 command 模板
local function compile_and_run_generic(config, cmd_template, is_o2)
    local file = vim.fn.expand("%:p")
    local exec_path = get_full_path(config, config.exec_name)
    local input_path = get_full_path(config, config.input_file)
    local output_path = get_full_path(config, config.output_file)
    local error_path = get_full_path(config, config.error_file)

    -- 准备工作：删除旧文件，确保输入文件存在
    if vim.fn.filereadable(exec_path) == 1 then vim.fn.delete(exec_path) end
    if vim.fn.filereadable(input_path) == 0 then write_file(input_path, "") end
    write_file(output_path, "")
    write_file(error_path, "")

    -- 变量替换
    local cmd = cmd_template:gsub("%%", "\"" .. file .. "\"")
    cmd = cmd:gsub("{exec}", exec_path)
    cmd = cmd:gsub("{input}", input_path)
    cmd = cmd:gsub("{output}", output_path)
    cmd = cmd:gsub("{error}", error_path)

    vim.cmd("wa")
    vim.notify(is_o2 and "正在以 O2 优化模式编译运行..." or "正在编译运行...", vim.log.levels.INFO)

    if execute_command(cmd) then
        vim.notify("运行完成", vim.log.levels.INFO)
    else
        if vim.fn.filereadable(exec_path) == 0 then
            vim.notify("编译失败！", vim.log.levels.ERROR)
        else
            vim.notify("运行结束（可能存在运行时错误）", vim.log.levels.WARN)
        end
    end
end

-- 导出函数
M.compile_and_run = function()
    compile_and_run_generic(default_configuration, default_configuration.compile_run_command, false)
end

M.compile_and_run_o2 = function()
    compile_and_run_generic(default_configuration, default_configuration.compile_run_o2_command, true)
end

-- 其他原有接口保持不变...
local function edit_input_float(config)
    local input_path = get_full_path(config, config.input_file)
    if edit_windows[input_path] then
        local win = edit_windows[input_path].win
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_set_current_win(win)
            return
        end
    end
    local _, win = create_editable_float_window(nil, "编辑输入 - " .. config.input_file, input_path, nil)
    vim.api.nvim_set_current_win(win)
end

-- [补回功能] 仅运行函数
local function run_only(config)
    local exec_path = get_full_path(config, config.exec_name)
    local input_path = get_full_path(config, config.input_file)
    local output_path = get_full_path(config, config.output_file)
    local error_path = get_full_path(config, config.error_file)

    if vim.fn.filereadable(exec_path) == 0 then
        vim.notify("可执行文件不存在，请先编译 (<leader>ca)", vim.log.levels.WARN)
        return
    end

    -- 运行前清理旧输出
    write_file(output_path, "")
    write_file(error_path, "")

    local cmd = config.run_command:gsub("{exec}", exec_path)
                                :gsub("{input}", input_path)
                                :gsub("{output}", output_path)
                                :gsub("{error}", error_path)

    vim.notify("正在运行程序...", vim.log.levels.INFO)
    execute_command(cmd)
    vim.notify("运行完成", vim.log.levels.INFO)
end

-- 导出接口
M.run = function() run_only(default_configuration) end

function M.setup(user_configuration)
    local config = vim.tbl_deep_extend("force", default_configuration, user_configuration or {})
    -- 路径处理略...

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "cpp",
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            local opts = { buffer = bufnr }

            vim.keymap.set("n", "<leader>ca", M.compile_and_run, { buffer = bufnr, desc = "编译并运行" })
            -- 新增快捷键：<leader>co2
            vim.keymap.set("n", "<leader>co2", M.compile_and_run_o2, { buffer = bufnr, desc = "以 O2 模式编译运行" })

            vim.keymap.set("n", "<leader>cr", function() run_only(config) end, { buffer = bufnr, desc = "仅运行现有程序" })

            -- 其他原有快捷键
            vim.keymap.set("n", "<leader>ci", function() edit_input_float(config) end, opts)
            vim.keymap.set("n", "<leader>co", function()
                local content = read_file(get_full_path(config, config.output_file))
                create_readonly_float_window(content, "标准输出")
            end, opts)
            vim.keymap.set("n", "<leader>ce", function()
                local content = read_file(get_full_path(config, config.error_file))
                create_readonly_float_window(content, "标准错误")
            end, opts)
        end,
    })
end

return M
