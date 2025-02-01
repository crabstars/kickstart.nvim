local M = {}

-- open empty window
-- write something in window
-- some entry in window
-- extra window for each entry
-- use in init.lua
-- implement with lsp
--
-- hints
-- :source to run
-- :h api-floatwin
-- https://neovim.io/doc/user/api.html#nvim_open_win()
-- M.setup = function()
--   -- nothing
-- end

vim.print 'hello from overload'

local state = {
  selected = 0,
  float_buf = nil, -- buffer id for the floating window
  float_win = nil, -- window id for the floating window
}

local overloads = {
  { signature = 'string (int, bool)', doc = 'overload 1' },
  { signature = 'bool (string, bool)', doc = 'overload 2' },
  { signature = 'void (string, bool)', doc = 'overload 3' },
}

local function doc_window(index, win_id, doc_id)
  if doc_id ~= nil and vim.api.nvim_buf_is_valid(doc_id) then
    vim.api.nvim_buf_set_lines(doc_id, 0, -1, false, { overloads[index].doc })
    return doc_id, win_id
  end
  local opts = {
    relative = 'editor',
    -- win = win_id,
    width = 30,
    height = 10,
    row = 5,
    col = 40,
    style = 'minimal',
    border = 'rounded',
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, { overloads[index].doc })
  vim.api.nvim_open_win(buf, false, opts)
  return buf, win_id
end

local function create_window()
  local buf = vim.api.nvim_create_buf(false, true)
  local doc_id = nil
  local win_id = nil
  for i, overload in ipairs(overloads) do
    vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { overload.signature })
  end
  local opts = {
    relative = 'editor',
    width = 30,
    height = 10,
    row = 1,
    col = 0,
    style = 'minimal',
    border = 'rounded',
  }
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'SelectionMenu')
  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.wo[win].cursorline = true -- highlights current line

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = buf, -- only triggers for own buffer
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(win)
      doc_id, win_id = doc_window(cursor[1], win, doc_id)
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufLeave' }, {
    buffer = buf,
    callback = function()
      if win_id ~= nil and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
      end
      if doc_id ~= nil and vim.api.nvim_buf_is_valid(doc_id) then
        vim.api.nvim_buf_delete(doc_id, {})
      end
    end,
  })
end
local function get_function_name()
  local line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local col = cursor_pos[2] + 1
  local before_cursor = line:sub(1, col)
  local func_name = before_cursor:match '([%w_%.]+)%s*%('
  return func_name
end
local function get_overloads()
  local params = vim.lsp.util.make_position_params()
  --   {
  --   position = {
  --     character = 26,
  --     line = 27
  --   },
  --   textDocument = {
  --     uri = "file:///home/kami/RiderProjects/Planto/Planto/Planto.cs"
  --   }
  -- }
  local func_name = get_function_name()
  local res = vim.lsp.buf_request(0, 'textDocument/signatureHelp', params, function(err, result, ctx, config)
    if err or not result or not result.signatures or #result.signatures == 0 then
      vim.notify('No overloads found!', vim.log.levels.WARN)
      return
    end
    vim.notify('Overloads found!', vim.log.levels.WARN)
  end)
  -- vim.print(res.signatures)
  -- vim.lsp.buf_request(0, 'textDocument/signatureHelp', params, function(err, result, ctx, config)
  --   if err or not result or not result.signatures or #result.signatures == 0 then
  --     vim.notify('No overloads found!', vim.log.levels.WARN)
  --     return
  --   end
  --
  --   -- Reset selection state
  --   local current_selection = 1
  --   local overloads_list = {}
  --
  --   -- Extract overloads
  --   for i, signature in ipairs(result.signatures) do
  --     local label = signature.label or 'No label'
  --     -- if #label ~= 'No label' then
  --     --   label = format_function_signature(label) or label
  --     -- end
  --     local documentation = signature.documentation and (type(signature.documentation) == 'string' and signature.documentation or signature.documentation.value)
  --       or 'No documentation available.'
  --
  --     table.insert(overloads_list, {
  --       label = label,
  --       documentation = documentation,
  --     })
  --   end
  --   print(vim.inspect(overloads_list))
  --   vim.cmd 'new' -- Open a new split
  --   vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(vim.inspect(overloads_list), '\n')) {
  --     {
  --       documentation = 'Writes the current line terminator to the standard output stream.',
  --       label = 'void Console.WriteLine()',
  --     },
  --     {
  --       documentation = 'Writes the text representation of the specified Boolean value, followed by the current line terminator, to the standard output stream.',
  --       label = 'void Console.WriteLine(bool value)',
  --     },
  --   }
  -- end)
end
--   vim.lsp.buf_request(0, 'textDocument/signatureHelp', params, function(err, result, ctx, config)
--     if err or not result or not result.signatures or #result.signatures == 0 then
--       vim.notify('No overloads found!', vim.log.levels.WARN)
--       return
--     end
-- end
vim.keymap.set('n', '<leader>o', create_window, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>i', get_overloads, { noremap = true, silent = true })
return M
-- local ns_id = vim.api.nvim_create_namespace 'SelectionMenu'
-- vim.api.nvim_buf_add_highlight(buf, ns_id, 'Comment', 0, 0, -1)
-- vim.api.nvim_win_set_cursor(win, { 2, 2 })
-- Internal state

-- Start v1 ##########################
-- Helper function to create a centered window
-- function M.create_centered_float(width, height)
--   local columns = vim.o.columns
--   local lines = vim.o.lines
--   local win_opts = {
--     relative = 'editor',
--     row = math.floor((lines - height) / 2),
--     col = math.floor((columns - width) / 2),
--     width = width,
--     height = height,
--     style = 'minimal',
--     border = 'rounded',
--     zindex = 50, -- Ensure menu appears above other windows
--   }
--
--   local buf = vim.api.nvim_create_buf(false, true)
--   local win = vim.api.nvim_open_win(buf, true, win_opts) -- Set focus to true
--
--   -- Set window-local options
--   vim.wo[win].cursorline = true
--   vim.wo[win].signcolumn = 'no'
--   vim.wo[win].number = false
--   vim.wo[win].relativenumber = false
--
--   return buf, win
-- end
--
-- function M.create_selection_menu(items, opts)
--   if #items == 0 then
--     vim.notify('No items to display', vim.log.levels.WARN)
--     return
--   end
--
--   opts = vim.tbl_deep_extend('force', {
--     width = 40,
--     height = math.min(#items + 2, math.floor(vim.o.lines * 0.8)),
--     title = 'Select an option',
--     prompt = '> ',
--     on_select = function(selected)
--       print('Selected: ' .. selected)
--     end,
--     on_cancel = function() end,
--   }, opts or {})
--
--   local buf, win = M.create_centered_float(opts.width, opts.height)
--
--   -- Set buffer options
--   vim.api.nvim_buf_set_option(buf, 'modifiable', true)
--   vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
--   vim.api.nvim_buf_set_option(buf, 'filetype', 'SelectionMenu')
--
--   -- Add title and items to buffer
--   local lines = { opts.title, string.rep('─', opts.width - 2) }
--   for _, item in ipairs(items) do
--     table.insert(lines, opts.prompt .. item)
--   end
--   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
--
--   -- Make title line non-modifiable
--   local ns_id = vim.api.nvim_create_namespace 'SelectionMenu'
--   vim.api.nvim_buf_add_highlight(buf, ns_id, 'Title', 0, 0, -1)
--   vim.api.nvim_buf_add_highlight(buf, ns_id, 'Comment', 1, 0, -1)
--
--   -- Set cursor to first item
--   vim.api.nvim_win_set_cursor(win, { 3, #opts.prompt })
--
--   -- Handle window close
--   local function cleanup()
--     if vim.api.nvim_win_is_valid(win) then
--       vim.api.nvim_win_close(win, true)
--     end
--   end
--
--   -- Function to move cursor
--   local function move_cursor(direction)
--     local cursor = vim.api.nvim_win_get_cursor(win)
--     local new_line = cursor[1] + direction
--
--     -- Ensure we stay within bounds (3 is first item, #items + 2 is last item)
--     if new_line >= 3 and new_line <= #items + 2 then
--       vim.api.nvim_win_set_cursor(win, { new_line, cursor[2] })
--     end
--   end
--
--   -- Set up autocommands
--   local group = vim.api.nvim_create_augroup('SelectionMenu' .. buf, { clear = true })
--   vim.api.nvim_create_autocmd('BufLeave', {
--     group = group,
--     buffer = buf,
--     callback = cleanup,
--   })
--
--   -- Set keymaps
--   local keymaps = {
--     ['j'] = function()
--       move_cursor(1)
--     end,
--     ['k'] = function()
--       move_cursor(-1)
--     end,
--     ['<Down>'] = function()
--       move_cursor(1)
--     end,
--     ['<Up>'] = function()
--       move_cursor(-1)
--     end,
--     ['<C-n>'] = function()
--       move_cursor(1)
--     end, -- Added Ctrl+n support
--     ['<C-p>'] = function()
--       move_cursor(-1)
--     end, -- Added Ctrl+p support for consistency
--     ['<CR>'] = function()
--       local cursor = vim.api.nvim_win_get_cursor(win)
--       local selected = items[cursor[1] - 2] -- Adjust for title and separator
--       cleanup()
--       if selected then
--         opts.on_select(selected)
--       end
--     end,
--     ['q'] = function()
--       cleanup()
--       opts.on_cancel()
--     end,
--     ['<Esc>'] = function()
--       cleanup()
--       opts.on_cancel()
--     end,
--   }
--
--   for key, mapping in pairs(keymaps) do
--     vim.keymap.set('n', key, mapping, { buffer = buf, nowait = true })
--   end
--
--   -- Prevent cursor from going above items or below last item
--   vim.api.nvim_create_autocmd('CursorMoved', {
--     group = group,
--     buffer = buf,
--     callback = function()
--       local cursor = vim.api.nvim_win_get_cursor(win)
--       if cursor[1] < 3 then
--         vim.api.nvim_win_set_cursor(win, { 3, cursor[2] })
--       elseif cursor[1] > #items + 2 then
--         vim.api.nvim_win_set_cursor(win, { #items + 2, cursor[2] })
--       end
--     end,
--   })
-- end
--
-- local items = { 'Option 1', 'Option 2', 'Option 3', 'Option 4' }
-- M.create_selection_menu(items, {
--   on_select = function(selected) end,
-- })
-- end v1 ###################################
-- return M
-- Store the current selection state
-- local M = {}
-- local current_selection = 1
-- local current_buf = nil
-- local current_win = nil
-- local overloads_list = {}
--
-- local function update_window_content()
--   if not current_buf or not vim.api.nvim_buf_is_valid(current_buf) then
--     return
--   end
--
--   local lines = {}
--   table.insert(lines, '```csharp')
--   for i, overload in ipairs(overloads_list) do
--     local prefix = i == current_selection and '→ ' or '  '
--     local current_line = #lines + 1
--     -- Add markdown code block for C# syntax highlighting
--     table.insert(lines, '  ' .. overload.label)
--     table.insert(lines, '  //' .. overload.documentation)
--     table.insert(lines, '')
--   end
--   table.insert(lines, '```')
--   vim.api.nvim_buf_set_option(current_buf, 'modifiable', true)
--   vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
--   vim.api.nvim_buf_set_option(current_buf, 'modifiable', false)
-- end
--
-- local function move_selection(delta)
--   local new_selection = current_selection + delta
--   if new_selection >= 1 and new_selection <= #overloads_list then
--     current_selection = new_selection
--     update_window_content()
--   end
-- end
--
-- local function setup_keymaps()
--   if not current_buf then
--     return
--   end
--
--   -- Navigation keymaps
--   vim.api.nvim_buf_set_keymap(current_buf, 'n', '<C-n>', '', {
--     callback = function()
--       move_selection(1)
--     end,
--     noremap = true,
--     silent = true,
--   })
--
--   vim.api.nvim_buf_set_keymap(current_buf, 'n', '<C-p>', '', {
--     callback = function()
--       move_selection(-1)
--     end,
--     noremap = true,
--     silent = true,
--   })
--
--   -- Close window keymap
--   vim.api.nvim_buf_set_keymap(current_buf, 'n', 'q', '', {
--     callback = function()
--       if current_win and vim.api.nvim_win_is_valid(current_win) then
--         vim.api.nvim_win_close(current_win, true)
--       end
--     end,
--     noremap = true,
--     silent = true,
--   })
-- end
--
-- -- Helper functions remain the same
-- local function get_function_name()
--   local line = vim.api.nvim_get_current_line()
--   local cursor_pos = vim.api.nvim_win_get_cursor(0)
--   local col = cursor_pos[2] + 1
--   local before_cursor = line:sub(1, col)
--   local func_name = before_cursor:match '([%w_%.]+)%s*%('
--   return func_name
-- end
--
-- local function format_function_signature(label)
--   local return_type, params = label:match '^([%w%(%),%s]+)%s+[%w%.]+%s*(%b())'
--   if return_type and params then
--     local formatted_signature = params .. ': ' .. return_type
--     return formatted_signature
--   else
--     vim.notify('Failed to parse function signature: ' .. label, vim.log.levels.WARN)
--     return nil
--   end
-- end
--
-- local function create_floating_window()
--   -- Create buffer if it doesn't exist or get existing one
--   if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
--     vim.api.nvim_buf_set_option(current_buf, 'modifiable', true)
--   else
--     current_buf = vim.api.nvim_create_buf(false, true)
--   end
--
--   -- Set up buffer options
--   vim.api.nvim_buf_set_option(current_buf, 'bufhidden', 'wipe')
--   vim.api.nvim_buf_set_option(current_buf, 'filetype', 'markdown')
--
--   -- Calculate window dimensions
--   local width = math.min(vim.o.columns - 4, 80)
--   local height = math.min(vim.o.lines - 4, 40) -- Fixed height for consistent appearance
--   local row = math.floor((vim.o.lines - height) / 2)
--   local col = math.floor((vim.o.columns - width) / 2)
--
--   -- Create or update window
--   local win_opts = {
--     relative = 'editor',
--     width = width,
--     height = height,
--     row = row,
--     col = col,
--     style = 'minimal',
--     border = 'rounded',
--   }
--
--   if current_win and vim.api.nvim_win_is_valid(current_win) then
--     vim.api.nvim_win_set_config(current_win, win_opts)
--   else
--     current_win = vim.api.nvim_open_win(current_buf, true, win_opts)
--   end
-- end
-- function show_all_overloads()
--   local params = vim.lsp.util.make_position_params()
--   local func_name = get_function_name()
--
--   vim.lsp.buf_request(0, 'textDocument/signatureHelp', params, function(err, result, ctx, config)
--     if err or not result or not result.signatures or #result.signatures == 0 then
--       vim.notify('No overloads found!', vim.log.levels.WARN)
--       return
--     end
--
--     -- Reset selection state
--     current_selection = 1
--     overloads_list = {}
--
--     -- Extract overloads
--     for i, signature in ipairs(result.signatures) do
--       local label = signature.label or 'No label'
--       if #label ~= 'No label' then
--         label = format_function_signature(label) or label
--       end
--       local documentation = signature.documentation and (type(signature.documentation) == 'string' and signature.documentation or signature.documentation.value)
--         or 'No documentation available.'
--
--       table.insert(overloads_list, {
--         label = label,
--         documentation = documentation,
--       })
--     end
--
--     create_floating_window()
--     update_window_content()
--     setup_keymaps()
--   end)
-- end
-- vim.keymap.set('n', '<leader>o', show_all_overloads, { noremap = true, silent = true })
--
-- return M
