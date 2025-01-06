-- Create the popup with structured data navigation
local popup = {}

-- Store the data in a structured format
local data = {
  { title = 'Dog', details = 'Age 30' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 20' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 90' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 10' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 20' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 40' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 20' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  { title = 'Cat', details = 'Height 50' },
  -- Add more items as needed
}

local current_index = 1
local win_id = nil
local buf_id = nil
local MAX_HEIGHT = 20

function popup.create()
  -- Create buffer
  buf_id = vim.api.nvim_create_buf(false, true)

  -- Calculate dimensions
  local width = 30
  local total_height = #data * 2 -- Each item takes 2 lines
  local height = math.min(total_height, MAX_HEIGHT)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Set window options
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }

  -- Create window
  win_id = vim.api.nvim_open_win(buf_id, true, opts)

  -- Create custom highlight groups
  vim.cmd [[
    highlight PopupSelectionTitle guibg=#FFFACD guifg=#000000
    highlight PopupSelectionDetails guibg=#FFFAE5 guifg=#000000
  ]]

  -- Populate buffer with data
  popup.refresh_content()

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')

  -- Set up keymapping
  vim.api.nvim_buf_set_keymap(buf_id, 'n', '<C-n>', ':lua require("config/plugins/popup").next_item()<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf_id, 'n', '<C-p>', ':lua require("config/plugins/popup").previous_item()<CR>', { noremap = true, silent = true })

  -- Highlight current selection
  popup.highlight_current()
end

function popup.refresh_content()
  local lines = {}
  for _, item in ipairs(data) do
    table.insert(lines, item.title)
    table.insert(lines, item.details)
  end

  vim.api.nvim_buf_set_option(buf_id, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
end

function popup.previous_item()
  -- Clear previous highlight
  vim.api.nvim_buf_clear_namespace(buf_id, -1, 0, -1)

  -- Update index
  if current_index == 1 then
    current_index = #data
  else
    current_index = current_index - 1
  end

  -- Ensure selected item is visible
  popup.ensure_visible()

  -- Highlight new selection
  popup.highlight_current()

  -- Move cursor to selected item
  popup.update_cursor()
end

function popup.next_item()
  -- Clear previous highlight
  vim.api.nvim_buf_clear_namespace(buf_id, -1, 0, -1)

  -- Update index
  current_index = current_index % #data + 1

  -- Ensure selected item is visible
  popup.ensure_visible()

  -- Highlight new selection
  popup.highlight_current()

  -- Move cursor to selected item
  popup.update_cursor()
end

function popup.ensure_visible()
  local current_line = (current_index - 1) * 2
  local win_height = vim.api.nvim_win_get_height(win_id)
  local current_top = vim.fn.line 'w0' - 1
  local current_bottom = vim.fn.line 'w$' - 1

  -- If selection is above visible area
  if current_line < current_top then
    vim.api.nvim_win_set_cursor(win_id, { current_line + 1, 0 })
    vim.cmd 'normal! zt'
  -- If selection is below visible area
  elseif current_line > current_bottom - 1 then
    vim.api.nvim_win_set_cursor(win_id, { current_line + 1, 0 })
    vim.cmd 'normal! zb'
  end
end

function popup.update_cursor()
  -- Move cursor to the title line of current selection
  local current_line = (current_index - 1) * 2 + 1
  vim.api.nvim_win_set_cursor(win_id, { current_line, 0 })
end

function popup.highlight_current()
  -- Calculate line numbers for both title and details
  local title_line = (current_index - 1) * 2
  local details_line = title_line + 1

  -- Apply highlights to both title and details lines
  vim.api.nvim_buf_add_highlight(buf_id, -1, 'PopupSelectionTitle', title_line, 0, -1)
  vim.api.nvim_buf_add_highlight(buf_id, -1, 'PopupSelectionDetails', details_line, 0, -1)
end

return popup
