-- Create the popup with structured data navigation
local popup = {}

-- Store the data in a structured format with code blocks
local data = {
  { signature = '(string bla, int wow, IList kek): void', comment = 'This is the best overload' },
  { signature = '(string bla, int wow): void', comment = 'No This is the best overload' },
  { signature = '(string bla): void', comment = 'No This is the best overload' },
  { signature = '(string bla, int wow, IList kek): void', comment = 'This is the best overload' },
  { signature = '(string bla, int wow, IList kek): void', comment = 'This is the best overload' },
  { signature = '(string bla, int wow): void', comment = 'No This is the best overload' },
  { signature = '(string bla): void', comment = 'No This is the best overload' },
  { signature = '(string bla, int wow): void', comment = 'No This is the best overload' },
  { signature = '(string bla): void', comment = 'No This is the best overload' },
  { signature = '(string format, params object?[]? arg): void', comment = 'No This is the best overload' },
}

local current_index = 1
local win_id = nil
local buf_id = nil
local MAX_HEIGHT = 20

function popup.create()
  -- Create buffer
  buf_id = vim.api.nvim_create_buf(false, true)

  -- Enable syntax highlighting
  -- TODO: maybe use this  vim.api.nvim_buf_set_option(buf_id, 'syntax', 'cs')
  vim.api.nvim_buf_set_option(buf_id, 'filetype', 'markdown')

  -- Calculate dimensions
  local width = 50 -- Increased width for code
  local total_height = popup.calculate_total_height()
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
    highlight PopupSelectionsignature guibg=#FFF6D5 guifg=#000000
    highlight PopupSelectioncomment guibg=#FFF9DB guifg=#000000
  ]]

  -- hide markdown
  vim.cmd [[
    syntax match markdownCodeBlock /```csharp/ conceal
    syntax match markdownCodeBlockEnd /```/ conceal
    set conceallevel=2
  ]]

  -- Populate buffer with data
  popup.refresh_content()

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')
  vim.api.nvim_win_set_option(win_id, 'wrap', true)
  vim.api.nvim_win_set_option(win_id, 'linebreak', true)

  -- Set up keymapping
  vim.api.nvim_buf_set_keymap(buf_id, 'n', '<C-n>', ':lua require("config/plugins/popup").next_item()<CR>', { noremap = true, silent = true })

  -- Highlight current selection
  popup.highlight_current()
  popup.update_cursor()
end

function popup.calculate_total_height()
  local height = 0
  for _, item in ipairs(data) do
    height = height + 1 -- signature line
    -- Count newlines in comment plus one for the comment itself
    height = height + select(2, string.gsub(item.comment, '\n', '\n')) + 1
  end
  return height
end

function popup.parse_signature(signature)
  local lines = {}
  table.insert(lines, '```csharp')
  table.insert(lines, signature)
  table.insert(lines, '```')

  return lines
end

function popup.refresh_content()
  local lines = {}
  local current_line = 0

  for _, item in ipairs(data) do
    local signature_lines = popup.parse_signature(item.signature)
    for _, line in ipairs(signature_lines) do
      table.insert(lines, line)
      current_line = current_line + 1
    end
    table.insert(lines, item.comment)
    current_line = current_line + 1
    table.insert(lines, '')
  end

  vim.api.nvim_buf_set_option(buf_id, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
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

function popup.get_item_start_line(index)
  local line = 0
  for i = 1, index - 1 do
    line = line + 1 -- signature line
    line = line + select(2, string.gsub(data[i].comment, '\n', '\n')) + 1
  end
  return line
end

function popup.ensure_visible()
  local current_line = popup.get_item_start_line(current_index)
  local current_top = vim.fn.line 'w0' - 1
  local current_bottom = vim.fn.line 'w$' - 1

  if current_line < current_top then
    vim.api.nvim_win_set_cursor(win_id, { current_line + 1, 0 })
    vim.cmd 'normal! zt'
  elseif current_line > current_bottom - 1 then
    vim.api.nvim_win_set_cursor(win_id, { current_line + 1, 0 })
    vim.cmd 'normal! zb'
  end
end

function popup.update_cursor()
  local current_line = popup.get_item_start_line(current_index) + 1
  vim.api.nvim_win_set_cursor(win_id, { current_line, 0 })
end

function popup.highlight_current()
  -- local start_line = popup.get_item_start_line(current_index)
  -- local comment_lines = popup.parse_signature(data[current_index].signature)
  --
  -- -- Highlight signature
  -- vim.api.nvim_buf_add_highlight(buf_id, -1, 'PopupSelectionsignature', start_line, 0, -1)
  --
  -- -- Highlight comment
  -- for i = 1, #comment_lines do
  --   vim.api.nvim_buf_add_highlight(buf_id, -1, 'PopupSelectioncomment', start_line + i, 0, -1)
  -- end
end

return popup
