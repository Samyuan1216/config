return {
  -- 状态栏
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- 获取当前颜色方案的基础颜色
      local colors = {
        normal = '#808080',
        insert = '#56b6c2',
        visual = '#c678dd',
        replace = '#e06c75',
        command = '#61afef',
        terminal = '#98c379',
      }
      
      require("lualine").setup({
        options = {
          theme = {
            normal = {
              a = { fg = '#000000', bg = colors.normal, gui = 'bold' },
              b = { fg = '#ffffff', bg = 'NONE' },  -- 透明
              c = { fg = '#cccccc', bg = 'NONE' },  -- 透明
            },
            insert = {
              a = { fg = '#000000', bg = colors.insert, gui = 'bold' },
              b = { fg = '#ffffff', bg = 'NONE' },
              c = { fg = '#cccccc', bg = 'NONE' },
            },
            visual = {
              a = { fg = '#000000', bg = colors.visual, gui = 'bold' },
              b = { fg = '#ffffff', bg = 'NONE' },
              c = { fg = '#cccccc', bg = 'NONE' },
            },
            replace = {
              a = { fg = '#000000', bg = colors.replace, gui = 'bold' },
              b = { fg = '#ffffff', bg = 'NONE' },
              c = { fg = '#cccccc', bg = 'NONE' },
            },
            command = {
              a = { fg = '#000000', bg = colors.command, gui = 'bold' },
              b = { fg = '#ffffff', bg = 'NONE' },
              c = { fg = '#cccccc', bg = 'NONE' },
            },
            terminal = {
              a = { fg = '#000000', bg = colors.terminal, gui = 'bold' },
              b = { fg = '#ffffff', bg = 'NONE' },
              c = { fg = '#cccccc', bg = 'NONE' },
            },
            inactive = {
              a = { fg = '#808080', bg = 'NONE', gui = 'bold' },
              b = { fg = '#808080', bg = 'NONE' },
              c = { fg = '#808080', bg = 'NONE' },
            },
          },
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
      })
    end,
  },
}
