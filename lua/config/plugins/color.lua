return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000, -- Ensure it loads first
  config = function()
    require('catppuccin').setup {
      flavour = 'macchiato', -- Options: latte, frappe, macchiato, mocha
    }
    vim.cmd.colorscheme 'catppuccin'
  end,
}
