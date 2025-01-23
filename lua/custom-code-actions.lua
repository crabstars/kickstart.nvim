return {
  'jose-elias-alvarez/null-ls.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local null_ls = require 'null-ls'

    -- Register the custom code action
    null_ls.register {
      name = 'my-actions',
      method = { null_ls.methods.CODE_ACTION },
      filetypes = { 'cs' }, -- Apply only to .cs files
      generator = {
        fn = function()
          return {
            {
              title = 'add "hi mom"',
              action = function()
                local current_row = vim.api.nvim_win_get_cursor(0)[1]
                vim.api.nvim_buf_set_lines(0, current_row, current_row, true, { 'hi mom' })
              end,
            },
          }
        end,
      },
      priority = -1, -- Set a low priority so it's the last in the list
    }

    -- Initialize null-ls
    null_ls.setup()
  end,
}
