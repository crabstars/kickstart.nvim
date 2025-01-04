local M = {}

-- Store the current selection state
local current_selection = 1
local current_buf = nil
local current_win = nil
local overloads_list = {}

local function update_window_content()
  if not current_buf or not vim.api.nvim_buf_is_valid(current_buf) then
    return
  end

  local lines = {}
  table.insert(lines, '```csharp')
  for i, overload in ipairs(overloads_list) do
    local prefix = i == current_selection and '→ ' or '  '
    local current_line = #lines + 1
    -- Add markdown code block for C# syntax highlighting
    table.insert(lines, '  ' .. overload.label)
    table.insert(lines, '  //' .. overload.documentation)
    table.insert(lines, '')
  end
  table.insert(lines, '```')
  vim.api.nvim_buf_set_option(current_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(current_buf, 'modifiable', false)
end

local function move_selection(delta)
  local new_selection = current_selection + delta
  if new_selection >= 1 and new_selection <= #overloads_list then
    current_selection = new_selection
    update_window_content()
  end
end

local function setup_keymaps()
  if not current_buf then
    return
  end

  -- Navigation keymaps
  vim.api.nvim_buf_set_keymap(current_buf, 'n', '<C-n>', '', {
    callback = function()
      move_selection(1)
    end,
    noremap = true,
    silent = true,
  })

  vim.api.nvim_buf_set_keymap(current_buf, 'n', '<C-p>', '', {
    callback = function()
      move_selection(-1)
    end,
    noremap = true,
    silent = true,
  })

  -- Close window keymap
  vim.api.nvim_buf_set_keymap(current_buf, 'n', 'q', '', {
    callback = function()
      if current_win and vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_win_close(current_win, true)
      end
    end,
    noremap = true,
    silent = true,
  })
end

-- Helper functions remain the same
local function get_function_name()
  local line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local col = cursor_pos[2] + 1
  local before_cursor = line:sub(1, col)
  local func_name = before_cursor:match '([%w_%.]+)%s*%('
  return func_name
end

local function format_function_signature(label)
  local return_type, params = label:match '^([%w%(%),%s]+)%s+[%w%.]+%s*(%b())'
  if return_type and params then
    local formatted_signature = params .. ': ' .. return_type
    return formatted_signature
  else
    vim.notify('Failed to parse function signature: ' .. label, vim.log.levels.WARN)
    return nil
  end
end

local function create_floating_window()
  -- Create buffer if it doesn't exist or get existing one
  if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
    vim.api.nvim_buf_set_option(current_buf, 'modifiable', true)
  else
    current_buf = vim.api.nvim_create_buf(false, true)
  end

  -- Set up buffer options
  vim.api.nvim_buf_set_option(current_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(current_buf, 'filetype', 'markdown')

  -- Calculate window dimensions
  local width = math.min(vim.o.columns - 4, 80)
  local height = math.min(vim.o.lines - 4, 40) -- Fixed height for consistent appearance
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create or update window
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }

  if current_win and vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_win_set_config(current_win, win_opts)
  else
    current_win = vim.api.nvim_open_win(current_buf, true, win_opts)
  end
end
function M.show_all_overloads()
  local params = vim.lsp.util.make_position_params()
  local func_name = get_function_name()

  vim.lsp.buf_request(0, 'textDocument/signatureHelp', params, function(err, result, ctx, config)
    if err or not result or not result.signatures or #result.signatures == 0 then
      vim.notify('No overloads found!', vim.log.levels.WARN)
      return
    end

    -- Reset selection state
    current_selection = 1
    overloads_list = {}

    -- Extract overloads
    for i, signature in ipairs(result.signatures) do
      local label = signature.label or 'No label'
      if #label ~= 'No label' then
        label = format_function_signature(label) or label
      end
      local documentation = signature.documentation and (type(signature.documentation) == 'string' and signature.documentation or signature.documentation.value)
        or 'No documentation available.'

      table.insert(overloads_list, {
        label = label,
        documentation = documentation,
      })
    end

    create_floating_window()
    update_window_content()
    setup_keymaps()
  end)
end

return M
