return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',

  config = function()
      require('nvim-treesitter').install {
          'c', 'cpp', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline', 'javascript', 'typescript', 'java', 'python', 'html', 'latex', 'yaml'
      }
  end
}
