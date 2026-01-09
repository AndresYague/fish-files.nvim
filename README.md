# fish-files.nvim

## Description

Small-sized plugin that makes it easy to mark and retrieve your files in a
project. Inspired by [harpoon](#inspiration), but smaller, so instead of harpooning the files
we hook them so we can reel them.

## Usage

Hook the file in the current buffer with

```lua
require('fish-files').add_hook()
```

Navigate away and return to the file exactly where you left off with
`<prefix>1` without having to nagivate the jump-list with `<C-O>`, where
`<prefix>` is set up in the [Configuration](#configuration) below. Keep
hooking files and nagivate to them with `<prefix>N` where `N` is given in
the chronological order that the file was hooked. Alternatively, open a picker
with

```lua
require('fish-files').manage_hooks()
```

## Dependencies

- Neovim > 0.10.0 (probably)
- [which-key](#https://github.com/folke/which-key.nvim) is not needed but it is recommended.

## Installation

Install it like any other plugin. For example, if using `LazyVim` as your
package manager:


```lua
{
  'AndresYague/fish-files.nvim',
  opts = {},
}
```

It can also be initialized through a `setup` call:

```lua
require('fish-files').setup(opts)
```

## Configuration

### Defalt options

The default options are

```lua
opts = {
  prefix = '<leader>' -- Prefix for file jump, <prefix>N goes to the Nth marked file
}
```

### Example keymaps

These example keymaps set-up the full api

```lua
vim.keymap.set(
  'n',
  '<leader>ja',
  require('fish-files').add_hook,
  { desc = 'Hook this file' }
)
vim.keymap.set(
  'n',
  '<leader>jd',
  require('fish-files').remove_hook,
  { desc = 'Unhook this file' }
)
vim.keymap.set(
  'n',
  '<leader>jm',
  require('fish-files').manage_hooks,
  { desc = 'Manage hooks' }
)
vim.keymap.set(
  'n',
  '<leader>jr',
  require('fish-files').unhook_all_files,
  { desc = 'Unhook all files' }
)
```

## Manage hooks

The `manage_hooks` function opens a buffer/picker on a floating window so
that it can be modified by the user. Pressing `<CR>` on a file name closes
the window and opens the file to edit, while saving and exiting (with `:wq`,
`:x` or `ZZ`) propagates the changes made in the buffer to `fish-files`. That
is, deleting or re-ordering the file names will remove them from the hooks or
change the keybind to access them.

## Inspiration

This plugin is inspired by [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)
