return {
  {
    -- 给插件起个名字，方便在 :Lazy 界面看到
    "my-custom-path",
    -- dir 必须指向一个绝对路径。
    -- 在 Windows 上，我们直接指向你的 nvim 配置根目录
    dir = vim.fn.stdpath("config"),
    -- 明确告诉 lazy 这不是一个需要从网络下载的插件
    dev = false,
    config = function()
      -- 因为 nvim 已经把 lua 文件夹加入路径了
      -- 所以可以直接 require 你的 custom.path
      require("customs.path").setup()
    end,
  },
}
