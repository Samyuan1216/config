local M = {}

local default_configuration = {
    fixed_dir = "C:/Users/ZSY30/Desktop/tools/my-own/Code/C++/",
    exec_name = "zsy.exe",
    input_file = "in.txt",
    output_file = "out.txt",
    error_file = "debug.log",

    compile_command = "g++ % -g -o \"{exec}\" -std=c++17 -Wall -Werror",
    run_command = "\"{exec}\" < \"{input}\" > \"{output}\" 2> \"{error}\"",
    compile_run_command = "g++ % -g -o \"{exec}\" -std=c++17 -Wall -Werror && \"{exec}\" < \"{input}\" > \"{output}\" 2> \"{error}\"",

    float_window_width = 0.7,
    float_window_height = 0.7,
    float_window_border = "rounded",
}

local edit_windows = {}
local merged_config = nil  -- 保存合并后的用户配置（仅作为模板，fixed_dir 会被动态覆盖）

-- 根据当前文件生成临时配置（fixed_dir = 当前目录）
local function with_current_dir_config()
    local file = vim.fn.expand("%:p")
    if file == "" then
        vim.notify("当前缓冲区没有关联的文件", vim.log.levels.ERROR)
        return nil
    end
    local current_dir = vim.fn.fnamemodify(file, ":h")
    local base = merged_config or default_configuration
    local cfg = vim.tbl_deep_extend("force", {}, base)
    cfg.fixed_dir = current_dir
    return cfg
end

local function get_full_path(config, file)
    local dir = config.fixed_dir:gsub("/", "\\"):gsub("\\$", "") .. "\\"
    return dir .. file
end

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
            if filepath then
                edit_windows[filepath] = nil
            end
        end
    })

    if filepath then
        edit_windows[filepath] = { buf = buf, win = win, filepath = filepath }
    end

    return buf, win
end

local function read_file(filepath)
    local success, content = pcall(vim.fn.readfile, filepath)
    if success then
        return table.concat(content, "\n")
    end
    return ""
end

local function write_file(filepath, content)
    local dir = vim.fn.fnamemodify(filepath, ":h")
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile(vim.split(content or "", "\n"), filepath)
end

-- [修改] 接收 config 参数，使用 config.fixed_dir 切换目录
local function execute_command_windows(cmd, config)
    local current_dir = vim.fn.getcwd()
    local plugin_dir = config.fixed_dir:gsub("/", "\\"):gsub("\\$", "")

    -- 检查目录是否存在（理论上应该存在，因为它是当前文件所在目录）
    if vim.fn.isdirectory(plugin_dir) == 0 then
        vim.notify("工作目录不存在: " .. plugin_dir, vim.log.levels.ERROR)
        return false
    end

    -- 切换目录，若失败则报错返回
    local ok, err = pcall(vim.fn.chdir, plugin_dir)
    if not ok then
        vim.notify("切换目录失败: " .. err, vim.log.levels.ERROR)
        return false
    end

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

local function compile_code(config)
    local file = vim.fn.expand("%:p")
    local exec_path = get_full_path(config, config.exec_name)

    if vim.fn.filereadable(exec_path) == 1 then
        vim.fn.delete(exec_path)
    end

    local cmd = config.compile_command
    cmd = cmd:gsub("%%", "\"" .. file .. "\"")
    cmd = cmd:gsub("{exec}", exec_path)

    vim.cmd("wa")
    -- 传递 config 给 execute_command_windows
    local success = execute_command_windows(cmd, config)

    if vim.fn.filereadable(exec_path) == 1 then
        vim.notify("编译成功: " .. exec_path, vim.log.levels.INFO)
        return true
    else
        vim.notify("编译失败，请检查错误信息(leader+ce)或代码", vim.log.levels.ERROR)
        return false
    end
end

local function run_code(config)
    local exec_path = get_full_path(config, config.exec_name)
    local input_path = get_full_path(config, config.input_file)
    local output_path = get_full_path(config, config.output_file)
    local error_path = get_full_path(config, config.error_file)

    if vim.fn.filereadable(input_path) == 0 then
        write_file(input_path, "")
    end

    write_file(output_path, "")
    write_file(error_path, "")

    local cmd = config.run_command
    cmd = cmd:gsub("{exec}", exec_path)
    cmd = cmd:gsub("{input}", input_path)
    cmd = cmd:gsub("{output}", output_path)
    cmd = cmd:gsub("{error}", error_path)

    if vim.fn.filereadable(exec_path) == 0 then
        vim.notify("可执行文件不存在: " .. exec_path, vim.log.levels.WARN)
        return false
    end

    vim.notify("正在运行程序...", vim.log.levels.INFO)
    -- 传递 config 给 execute_command_windows
    execute_command_windows(cmd, config)

    local error_content = read_file(error_path)
    if error_content and #error_content > 0 then
        vim.notify("运行完成 (有错误输出)", vim.log.levels.WARN)
    else
        vim.notify("运行完成", vim.log.levels.INFO)
    end

    return true
end

local function compile_and_run(config)
    if compile_code(config) then
        vim.defer_fn(function()
            run_code(config)
        end, 100)
    end
end

-- ========== 公开接口（动态获取当前目录） ==========
M.compile = function()
    local cfg = with_current_dir_config()
    if cfg then compile_code(cfg) end
end

M.run = function()
    local cfg = with_current_dir_config()
    if cfg then run_code(cfg) end
end

M.compile_and_run = function()
    local cfg = with_current_dir_config()
    if cfg then
        if compile_code(cfg) then
            vim.defer_fn(function() run_code(cfg) end, 100)
        end
    end
end

M.open_input = function()
    local cfg = with_current_dir_config()
    if not cfg then return end
    local path = get_full_path(cfg, cfg.input_file)
    local content = read_file(path)
    create_readonly_float_window(content, "标准输入 - " .. cfg.input_file)
end

M.open_output = function()
    local cfg = with_current_dir_config()
    if not cfg then return end
    local path = get_full_path(cfg, cfg.output_file)
    local content = read_file(path)
    create_readonly_float_window(content, "标准输出 - " .. cfg.output_file)
end

M.open_error = function()
    local cfg = with_current_dir_config()
    if not cfg then return end
    local path = get_full_path(cfg, cfg.error_file)
    local content = read_file(path)
    create_readonly_float_window(content, "标准错误 - " .. cfg.error_file)
end

M.edit_input = function()
    local cfg = with_current_dir_config()
    if not cfg then return end
    local input_path = get_full_path(cfg, cfg.input_file)
    if edit_windows[input_path] then
        local win = edit_windows[input_path].win
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_set_current_win(win)
            return
        end
    end
    create_editable_float_window(nil, "编辑输入文件 - " .. cfg.input_file, input_path, nil)
end

-- ========== 插件初始化 ==========
function M.setup(user_configuration)
    local config = vim.tbl_deep_extend("force", default_configuration, user_configuration or {})
    -- 标准化 fixed_dir 格式
    config.fixed_dir = config.fixed_dir:gsub("\\", "/")
    if not config.fixed_dir:match("/$") then
        config.fixed_dir = config.fixed_dir .. "/"
    end
    merged_config = config  -- 保存合并后的配置（作为模板）

    -- 检查 g++ 是否可用
    local check_gpp = vim.fn.system("where g++ 2>nul")
    if check_gpp == "" then
        vim.notify("警告: g++ 未找到，请确保MinGW已安装并加入PATH", vim.log.levels.WARN)
    end

    -- 为 C++ 文件设置快捷键（直接绑定到 M 中的函数）
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "cpp",
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.keymap.set("n", "<leader>cb", M.compile, { buffer = bufnr, desc = "编译代码" })
            vim.keymap.set("n", "<leader>cr", M.run, { buffer = bufnr, desc = "运行程序" })
            vim.keymap.set("n", "<leader>ca", M.compile_and_run, { buffer = bufnr, desc = "编译并运行" })
            vim.keymap.set("n", "<leader>ci", M.edit_input, { buffer = bufnr, desc = "编辑输入文件" })
            vim.keymap.set("n", "<leader>co", M.open_output, { buffer = bufnr, desc = "查看输出文件" })
            vim.keymap.set("n", "<leader>ce", M.open_error, { buffer = bufnr, desc = "查看错误文件" })
        end,
    })

    vim.notify("C++插件已加载", vim.log.levels.INFO)
end

return M
