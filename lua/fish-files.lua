local cache_file = require("utils").cache_file
local edit_cache = require("utils").edit_cache
local root = require("utils").root
local write_to_cache = require("utils").write_to_cache
local fish_group = vim.api.nvim_create_augroup("fish-files", { clear = true })

local goto_file = {}
local keymaps = 0
local prefix

---@type string[] List of all files hooked
local filename_list = {}

M = {}

---Normalize the filename. If "filename" is not provided, take the current
---buffer
---@param filename string? Name of the file
---@return string
local normalize_fname = function(filename)
  -- Get current filename
  if not filename then
    filename = vim.api.nvim_buf_get_name(0)
  end

  return vim.fs.normalize(vim.fs.abspath(filename))
end

---Shorten a filename for easier visualization
---@param filename string Name of the file
---@return string
local shorten_filename = function(filename)
  local pretty_line = nil
  if root then
    pretty_line = filename:sub(root:len() + 2)
  end
  if pretty_line and pretty_line:len() <= 30 then
    return pretty_line
  else
    return vim.fs.joinpath(
      vim.fs.basename(vim.fs.dirname(filename)),
      vim.fs.basename(filename)
    )
  end
end

---Open a file, loading the view
---@param filename string Name of the file
---@return nil
local reel_file = function(filename)
  if vim.api.nvim_buf_get_name(0) ~= "" then
    vim.cmd.mkview()
  end
  vim.cmd.edit(filename)
  pcall(vim.cmd.loadview(), "")
  vim.cmd.filetype("detect") -- Detecting again the filetype to trigger LSP and colorscheme
end

---Add keymap for the filename
---@param filename string Name of the file
---@return nil
local add_keymap = function(filename)
  -- Increment keymaps
  keymaps = keymaps + 1
  local index = keymaps
  vim.keymap.set("n", prefix .. index, function()
    reel_file(filename)
  end, { desc = "Reel file: " .. shorten_filename(filename) })
end

---Clean and re-create all the keymaps
---@return nil
local re_index_keymaps = function()
  -- Clean the keymaps
  for idx = 1, keymaps do
    vim.api.nvim_del_keymap("n", prefix .. idx)
  end
  keymaps = 0

  -- Now create them again
  for _, fname in ipairs(filename_list) do
    add_keymap(fname)
  end
end

---Add a keymap for the filename
---@param filename string? Name of the file
---@return nil
local add_hook = function(filename)
  -- Normalize current filename
  filename = normalize_fname(filename)

  -- Check if filename is already in array
  for _, fname in ipairs(filename_list) do
    if fname == filename then
      return
    end
  end

  -- Add filename and keymap
  filename_list[#filename_list + 1] = filename
  add_keymap(filename)
end

---@param filename string? Name of the file
---@param do_re_index boolean? Re-index default True
---@return nil
local remove_hook = function(filename, do_re_index)
  if do_re_index == nil then
    do_re_index = true
  end

  -- Normalize current filename
  filename = normalize_fname(filename)

  for idx, fname in ipairs(filename_list) do
    if fname == filename then
      table.remove(filename_list, idx)
      break
    end
  end

  if do_re_index then
    re_index_keymaps()
  end
end

---Function to remove all filenames
---@return nil
M.unhook_all_files = function()
  for _, fname in ipairs(filename_list) do
    remove_hook(fname, false)
  end
  re_index_keymaps()
end

-- Define the functions that use file_action

-- Cache utility functions

---Read cache file
---@return nil
local read_cache = function()
  -- In case we have some files in memory, unload them
  filename_list = {}
  re_index_keymaps()

  local file_read = io.open(cache_file, "r")
  if file_read then
    for line in file_read:lines() do
      add_hook(line)
    end
  end
end

M.manage_hooks = function()
  -- Write to the cache file
  write_to_cache(filename_list)

  -- Open the cache file to edit
  edit_cache(goto_file)

  -- The autocmd below makes sure we get the information after editing the
  -- cache
end

---@param opts {prefix: string}? Options for the plugin
---@return nil
M.setup = function(opts)
  opts = opts or {}
  prefix = opts.prefix or "<leader>"

  -- Read the cache file to the filenames
  read_cache()

  -- When the cache is changed, read it
  vim.api.nvim_create_autocmd("WinEnter", {
    group = fish_group,

    -- We either changed the buffer or selected a file
    callback = function()
      if #goto_file > 0 then
        reel_file(goto_file[1])
        goto_file = {}
      else
        read_cache()
      end
    end,
  })

  -- Save the filenames to the cache file when leaving nvim
  vim.api.nvim_create_autocmd({ "VimLeave" }, {
    group = fish_group,
    callback = function()
      write_to_cache(filename_list)
    end,
    once = true,
  })
end

M.add_hook = add_hook
M.remove_hook = remove_hook

return M
