-- 交互题运行器：编译当前文件后，在浮动窗口中左侧输入、右侧查看输出。
-- 所有编译产物、输入记录、输出记录和日志都会放在当前文件旁的 .cp_data 中。

local M = {}
local session = nil
local resize_augroup = vim.api.nvim_create_augroup("InteractiveRunner", { clear = true })

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Interactive Runner" })
end

local function write_lines(path, lines)
  if path and type(lines) == "table" then
    vim.fn.writefile(lines, path)
  end
end

local function get_current_file()
  local source = vim.fn.expand("%:p")
  if source == "" or vim.fn.filereadable(source) ~= 1 then
    notify("当前缓冲区没有可编译的文件，请先保存文件。", vim.log.levels.ERROR)
    return nil
  end

  local extension = vim.fn.expand("%:e"):lower()
  if extension ~= "cpp" and extension ~= "cc" and extension ~= "cxx" and extension ~= "c" then
    notify("交互运行器目前只支持 C/C++ 文件。", vim.log.levels.ERROR)
    return nil
  end

  return {
    source = source,
    directory = vim.fn.fnamemodify(source, ":p:h"),
    basename = vim.fn.fnamemodify(source, ":t:r"),
    extension = extension,
  }
end

local function calculate_layout()
  -- nvim_open_win 的 width 不包含左右边框；两个浮窗之间还要预留空隙。
  -- 旧布局只按内容宽度计算，左右边框会占用额外列，导致 IN/OUT 相互覆盖。
  local horizontal_margin = 2
  local window_gap = 1
  local border_width = 2
  local outer_width = math.min(math.max(vim.o.columns - 2 * horizontal_margin, 44), 164)
  local content_width = outer_width - border_width * 2 - window_gap
  local total_width = math.max(content_width, 36)
  local total_height = math.min(math.max(vim.o.lines - 6, 10), 40)
  local left_width = math.floor(total_width / 2)
  local right_width = total_width - left_width
  local total_outer_width = total_width + border_width * 2 + window_gap
  local row = math.max(math.floor((vim.o.lines - total_height) / 2) - 1, 0)
  local col = math.max(math.floor((vim.o.columns - total_outer_width) / 2), 0)

  return {
    height = total_height,
    left_width = left_width,
    right_width = right_width,
    row = row,
    col = col,
    right_col = col + left_width + border_width + window_gap,
  }
end

local function write_output_log(target)
  target = target or session
  if not target or not target.output_path then
    return
  end

  local lines = vim.deepcopy(target.output_lines or {})
  if target.output_pending and target.output_pending ~= "" then
    table.insert(lines, target.output_pending)
  end
  write_lines(target.output_path, lines)
end

local function render_output()
  if not session or not session.output_buf or not vim.api.nvim_buf_is_valid(session.output_buf) then
    return
  end

  local lines = vim.deepcopy(session.output_lines)
  if session.output_pending ~= "" or #lines == 0 then
    table.insert(lines, session.output_pending or "")
  end

  vim.bo[session.output_buf].modifiable = true
  vim.api.nvim_buf_set_lines(session.output_buf, 0, -1, false, lines)
  vim.bo[session.output_buf].modifiable = false

  if session.output_win and vim.api.nvim_win_is_valid(session.output_win) then
    local line_count = math.max(vim.api.nvim_buf_line_count(session.output_buf), 1)
    pcall(vim.api.nvim_win_set_cursor, session.output_win, { line_count, 0 })
  end
  vim.cmd("redraw")
end

-- jobstart 的非 buffered stdout 回调会把一段数据拆成若干字符串。
-- 保留最后一个未遇到换行的片段，从而支持“无换行但已 flush”的交互提示。
local function append_output(data)
  if not session or type(data) ~= "table" then
    return
  end

  for index, chunk in ipairs(data) do
    if chunk ~= "" then
      session.output_pending = session.output_pending .. chunk
    end

    -- 列表中除最后一个元素外，都代表已经遇到了换行边界。
    if index < #data then
      table.insert(session.output_lines, session.output_pending)
      session.output_pending = ""
    end
  end

  render_output()
  write_output_log()
end

local function append_error(data)
  if not session or type(data) ~= "table" then
    return
  end

  for _, line in ipairs(data) do
    if line ~= "" then
      table.insert(session.error_lines, line)
    end
  end
  write_lines(session.error_path, session.error_lines)
end

local function resize_windows()
  if not session then
    return
  end

  local layout = calculate_layout()
  if session.input_win and vim.api.nvim_win_is_valid(session.input_win) then
    vim.api.nvim_win_set_config(session.input_win, {
      relative = "editor",
      width = layout.left_width,
      height = layout.height,
      row = layout.row,
      col = layout.col,
    })
  end
  if session.output_win and vim.api.nvim_win_is_valid(session.output_win) then
    vim.api.nvim_win_set_config(session.output_win, {
      relative = "editor",
      width = layout.right_width,
      height = layout.height,
      row = layout.row,
      col = layout.right_col,
    })
  end
end

local function close_session()
  if not session then
    return
  end

  local current = session
  write_lines(current.input_path, current.input_lines or {})
  write_output_log(current)
  session = nil

  if current.job_id and current.job_id > 0 then
    vim.fn.jobstop(current.job_id)
  end

  for _, win in ipairs({ current.input_win, current.output_win }) do
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  for _, buf in ipairs({ current.input_buf, current.output_buf }) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

local function send_line()
  if not session or session.finished then
    notify("交互程序已经结束。按 q 关闭窗口。", vim.log.levels.WARN)
    return
  end

  local line = vim.api.nvim_get_current_line()
  local sent = vim.fn.chansend(session.job_id, line .. "\n")
  if sent <= 0 then
    notify("发送输入失败：交互程序可能已经退出。", vim.log.levels.ERROR)
    return
  end

  table.insert(session.input_lines, line)
  write_lines(session.input_path, session.input_lines)

  local row = vim.api.nvim_win_get_cursor(session.input_win)[1]
  vim.api.nvim_buf_set_lines(session.input_buf, row - 1, row, false, { line, "" })
  vim.api.nvim_win_set_cursor(session.input_win, { row + 1, 0 })
end

local function close_stdin()
  if session and session.job_id and not session.finished and not session.stdin_closed then
    vim.fn.chanclose(session.job_id, "stdin")
    session.stdin_closed = true
    notify("已关闭交互程序的标准输入。", vim.log.levels.INFO)
  end
end

local function setup_buffer_keymaps()
  local input_buf = session.input_buf
  local output_buf = session.output_buf
  local quit = close_session

  vim.keymap.set("i", "<CR>", function()
    send_line()
  end, {
    buffer = input_buf,
    silent = true,
    expr = false,
    desc = "发送当前行到交互程序",
  })
  vim.keymap.set({ "i", "n" }, "<C-d>", close_stdin, {
    buffer = input_buf,
    silent = true,
    desc = "关闭交互程序标准输入",
  })
  vim.keymap.set("n", "q", quit, {
    buffer = input_buf,
    silent = true,
    nowait = true,
    desc = "关闭交互运行窗口",
  })
  vim.keymap.set("n", "q", quit, {
    buffer = output_buf,
    silent = true,
    nowait = true,
    desc = "关闭交互运行窗口",
  })
end

local function open_session(file)
  local cp_dir = file.directory .. "/.cp_data"
  local executable = cp_dir .. "/" .. file.basename .. "_interactive.out"
  local layout = calculate_layout()

  vim.fn.mkdir(cp_dir, "p")
  session = {
    input_lines = {},
    output_lines = {},
    output_pending = "",
    error_lines = {},
    input_path = cp_dir .. "/" .. file.basename .. "_interactive_in.txt",
    output_path = cp_dir .. "/" .. file.basename .. "_interactive_out.txt",
    error_path = cp_dir .. "/" .. file.basename .. "_interactive_err.log",
    executable = executable,
    finished = false,
    stdin_closed = false,
  }

  session.input_buf = vim.api.nvim_create_buf(false, true)
  session.output_buf = vim.api.nvim_create_buf(false, true)
  for _, buf in ipairs({ session.input_buf, session.output_buf }) do
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "text"
  end
  vim.api.nvim_buf_set_lines(session.input_buf, 0, -1, false, { "" })
  vim.api.nvim_buf_set_lines(session.output_buf, 0, -1, false, { "等待程序输出..." })
  vim.bo[session.output_buf].modifiable = false

  session.input_win = vim.api.nvim_open_win(session.input_buf, true, {
    relative = "editor",
    width = layout.left_width,
    height = layout.height,
    row = layout.row,
    col = layout.col,
    style = "minimal",
    border = "rounded",
    title = " IN  (Enter 发送，Ctrl-D 关闭 stdin，q 退出) ",
    title_pos = "center",
    zindex = 50,
  })
  session.output_win = vim.api.nvim_open_win(session.output_buf, false, {
    relative = "editor",
    width = layout.right_width,
    height = layout.height,
    row = layout.row,
    col = layout.right_col,
    style = "minimal",
    border = "rounded",
    title = " OUT  (q 退出) ",
    title_pos = "center",
    zindex = 50,
  })

  vim.wo[session.input_win].number = false
  vim.wo[session.input_win].relativenumber = false
  vim.wo[session.output_win].number = false
  vim.wo[session.output_win].relativenumber = false
  vim.wo[session.output_win].wrap = true
  setup_buffer_keymaps()

  vim.api.nvim_set_current_win(session.input_win)
  session.job_id = vim.fn.jobstart({ executable }, {
    cwd = file.directory,
    stdin = "pipe",
    stdout = "pipe",
    stderr = "pipe",
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      vim.schedule(function()
        append_output(data)
      end)
    end,
    on_stderr = function(_, data)
      vim.schedule(function()
        append_error(data)
      end)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if not session then
          return
        end
        if session.output_pending ~= "" then
          table.insert(session.output_lines, session.output_pending)
          session.output_pending = ""
        end
        session.finished = true
        render_output()
        write_output_log()
        write_lines(session.error_path, session.error_lines)
        if code == 0 then
          notify("交互程序运行结束。输出已保存到 .cp_data。", vim.log.levels.INFO)
        else
          notify("交互程序退出，状态码: " .. tostring(code) .. "。详见 .cp_data 下的日志。", vim.log.levels.WARN)
        end
      end)
    end,
  })

  if session.job_id <= 0 then
    local failed = session.job_id
    close_session()
    notify("启动交互程序失败，job id: " .. tostring(failed), vim.log.levels.ERROR)
    return
  end

  vim.cmd("startinsert")
  notify("程序已启动：在左侧输入一行后按 Enter 发送。", vim.log.levels.INFO)
end

local function compile(file)
  local cp_dir = file.directory .. "/.cp_data"
  local executable = cp_dir .. "/" .. file.basename .. "_interactive.out"
  local compile_log = cp_dir .. "/" .. file.basename .. "_interactive_compile.log"
  local compiler = file.extension == "c" and "gcc" or "g++"
  local standard = file.extension == "c" and "c17" or "c++23"
  local command = {
    compiler,
    "-std=" .. standard,
    "-Wall",
    "-Werror",
    "-g",
    file.source,
    "-o",
    executable,
  }
  local log_lines = { "$ " .. table.concat(command, " "), "" }
  vim.fn.mkdir(cp_dir, "p")
  write_lines(compile_log, log_lines)
  notify("正在编译 " .. file.source .. " ...", vim.log.levels.INFO)

  local job_id = vim.fn.jobstart(command, {
    cwd = file.directory,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if type(data) == "table" then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(log_lines, line)
          end
        end
        write_lines(compile_log, log_lines)
      end
    end,
    on_stderr = function(_, data)
      if type(data) == "table" then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(log_lines, line)
          end
        end
        write_lines(compile_log, log_lines)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        write_lines(compile_log, log_lines)
        if code ~= 0 then
          notify("编译失败，详见 " .. compile_log, vim.log.levels.ERROR)
          return
        end
        open_session(file)
      end)
    end,
  })

  if job_id <= 0 then
    notify("无法启动编译器，请确认已安装 " .. compiler .. "。", vim.log.levels.ERROR)
  end
end

function M.start()
  if session then
    close_session()
  end

  local file = get_current_file()
  if not file then
    return
  end

  local ok, err = pcall(vim.cmd, "write")
  if not ok then
    notify("保存当前文件失败: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  compile(file)
end

vim.api.nvim_create_autocmd("VimResized", {
  group = resize_augroup,
  callback = resize_windows,
})

return M
