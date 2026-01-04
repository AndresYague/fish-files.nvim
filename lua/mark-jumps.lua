local Snacks = require 'snacks'
local marks = {}
local keymaps = {}

M = {}

---Go to a mark saving the view before leaving and restoring it
---after arriving
---@param mark string
---@return nil
local go_to_mark = function(mark)
  if vim.api.nvim_buf_get_name(0) ~= '' then
    vim.cmd.mkview()
  end
  vim.api.nvim_feedkeys('`' .. mark, 'ixn', false)
  vim.cmd.loadview()
end

---Add a given mark to the list or create a new one in the current position
---@param mark string?
---@param filename string?
---@return nil
local mark_add = function(mark, filename)
  if not mark then
    local insert_mark = { did = false, index = 0 }

    -- Do not add more than one mark per file
    local bufname = vim.api.nvim_buf_get_name(0)
    for _, mrk in ipairs(marks) do
      if bufname == vim.fs.abspath(vim.api.nvim_get_mark(mrk, {})[4]) then
        return nil
      end
    end

    -- Add the mark to the list
    if #marks == 0 then
      marks = { M.opts.mark_names[1] }
      insert_mark.did = true
      insert_mark.index = #marks
    else
      for idx, mark_name in ipairs(M.opts.mark_names) do
        if marks[idx] ~= mark_name then
          table.insert(marks, idx, mark_name)
          insert_mark.did = true
          insert_mark.index = idx
          break
        end
      end

      -- Tell user to change mark
      if not insert_mark.did then
        vim.notify(
          'Maximum number of marks reached, please choose to change a '
            .. 'mark instead with "'
            .. M.opts.choose_change
            .. '" or add more marks to your configuration',
          vim.log.levels.INFO,
          { title = 'Too many marks' }
        )

        return nil
      end
    end

    -- Add the mark to the file
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_buf_set_mark(
      0,
      marks[insert_mark.index],
      cursor[1],
      cursor[2],
      {}
    )
  else
    marks[#marks + 1] = mark
  end

  -- Save the current size of marks to avoid
  -- capturing the dynamic #marks
  local mark_index = #marks

  -- Get filename for mark
  if not filename then
    filename = vim.api.nvim_buf_get_name(0)
  end

  -- Shorten filename
  filename = vim.fs.joinpath(
    vim.fs.basename(vim.fs.dirname(filename)),
    vim.fs.basename(filename)
  )

  -- Add the keymap
  vim.keymap.set('n', M.opts.prefix .. mark_index, function()
    go_to_mark(marks[mark_index])
  end, { desc = 'File: ' .. filename })
  keymaps[#keymaps + 1] = mark_index
end

---@param mark_arr string[]
---@return string[]
local filename_array = function(mark_arr)
  local filename_arr = {}
  for _, mark in ipairs(mark_arr) do
    local markinfo = vim.api.nvim_get_mark(mark, {})
    filename_arr[#filename_arr + 1] = mark .. ' -> ' .. markinfo[4]
  end

  return filename_arr
end

---Index all existing marks so they are not overwritten
---@return nil
local index_all_marks = function()
  -- Clean the table and keymaps
  for _, keymap in ipairs(keymaps) do
    vim.api.nvim_del_keymap('n', M.opts.prefix .. keymap)
  end

  marks = {}
  keymaps = {}

  -- Re-index
  for _, tbl in ipairs(vim.fn.getmarklist()) do
    -- Take only the A-Z marks
    if tbl.mark:match "'[A-Z]" then
      mark_add(tbl.mark:sub(2), tbl.file)
    end
  end
end

---Perform an action on a chosen mark
---@param action string
---@param prompt string
---@return nil
local choose_mark = function(action, prompt)
  Snacks.picker.select(
    filename_array(marks),
    { prompt = prompt },
    function(choice)
      -- User canceled
      if not choice then
        return
      end

      -- Get only the mark name
      local mark = choice:sub(1, 1)

      if action == 'go' then
        go_to_mark(mark)
      elseif action == 'delete' then
        -- Remove mark from nvim
        vim.api.nvim_del_mark(mark)

        -- Re-index marks
        index_all_marks()
      elseif action == 'change' then
        -- Remove this mark and then create another in the current file
        vim.api.nvim_del_mark(mark)
        index_all_marks()
        mark_add()
      end
    end
  )
end

---Function to remove all marks
---@return nil
local remove_marks = function()
  for _, mark in ipairs(marks) do
    vim.api.nvim_del_mark(mark)
  end

  index_all_marks()
end

---Remove mark from current file
local delete_from_file = function()
  for _, tbl in ipairs(vim.fn.getmarklist()) do
    -- Take only the A-Z marks
    if tbl.mark:match "'[A-Z]" then
      if vim.fs.abspath(tbl.file) == vim.api.nvim_buf_get_name(0) then
        vim.api.nvim_buf_del_mark(0, tbl.mark:sub(2))
        break
      end
    end
  end

  index_all_marks()
end

-- Set picker actions

---@param opts {add_mark_file: string, choose_change: string, choose_delete: string, choose_file: string, mark_names: string[], prefix: string, remove_mark_file: string, remove_marks: string}?
---@return nil
M.setup = function(opts)
  M.opts = opts or {}

  M.opts.add_mark_file = M.opts.add_mark_file or '<leader>ja'
  M.opts.choose_change = M.opts.choose_change or '<leader>jc'
  M.opts.choose_delete = M.opts.choose_delete or '<leader>jx'
  M.opts.choose_file = M.opts.choose_file or '<leader>js'
  M.opts.mark_names = M.opts.mark_names or { 'A', 'B', 'C', 'D' }
  M.opts.prefix = M.opts.prefix or '<leader>'
  M.opts.remove_mark_file = M.opts.remove_mark_file or '<leader>jd'
  M.opts.remove_marks = M.opts.remove_marks or '<leader>jr'

  -- Set other keymaps

  -- Set the "mark_add" keymap
  vim.keymap.set('n', M.opts.add_mark_file, function()
    mark_add()
  end, { desc = 'Add file to marks' })
  vim.keymap.set(
    'n',
    M.opts.remove_marks,
    remove_marks,
    { desc = 'Remove all marks' }
  )
  vim.keymap.set(
    'n',
    M.opts.remove_mark_file,
    delete_from_file,
    { desc = 'Remove mark from this file' }
  )

  ---General function to set picker actions
  ---@param lhs string
  ---@param action string
  ---@param prompt string
  ---@return nil
  local picker_action = function(lhs, action, prompt)
    vim.keymap.set('n', lhs, function()
      choose_mark(action, prompt)
    end, { desc = prompt })
  end

  picker_action(M.opts.choose_file, 'go', 'Choose go to file')
  picker_action(M.opts.choose_delete, 'delete', 'Choose delete mark')
  picker_action(M.opts.choose_change, 'change', 'Choose change mark')

  -- Run the mark indexing once vim has loaded
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('Marks indexing', { clear = true }),
    callback = function()
      index_all_marks()
    end,
    once = true,
  })
end

return M
