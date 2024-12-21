return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      direction = 'float',
    }
    vim.api.nvim_set_keymap('n', '<C-\\>', ':ToggleTerm<CR>', { noremap = true, silent = true })
  end,
}
