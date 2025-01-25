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
    }

    -- Initialize null-ls
    null_ls.setup {
      on_attach = function(client, bufnr)
        -- Custom sorting logic for code actions
        vim.lsp.handlers['textDocument/codeAction'] = function(err, actions, ctx, config)
          if not err and actions then
            -- Add sorting logic here to move "hi mom" to the end
            table.sort(actions, function(a, b)
              if a.title == 'add "hi mom"' then
                return false
              elseif b.title == 'add "hi mom"' then
                return true
              else
                return a.title < b.title
              end
            end)
          end
          -- Call the default handler
          vim.lsp.handlers['textDocument/codeAction'](err, actions, ctx, config)
        end
      end,
    }
  end,
}
