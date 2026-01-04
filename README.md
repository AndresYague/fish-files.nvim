# mark-jumps.nvim

## Description

Small plugin that makes it easy to place and go to marks accross your files

## Installation

Install it like any other plugin. For example, if using `LazyVim` as your package manager:


```lua
  {
    'AndresYague/mark-jumps.nvim',
    opts = {},
  }
```

The default options are

```lua
  {
    'AndresYague/mark-jumps.nvim',
    opts = {
      add_mark_file = '<leader>ja' -- How to add a mark to the current file
      choose_change = '<leader>jc' -- Add a mark to this file by removing another
      choose_delete = '<leader>jx' -- Choose a mark to delete
      choose_file = '<leader>js' -- Picker to choose which file to go to
      mark_names = { 'A', 'B', 'C', 'D' } -- Which marks can the plugin use
      prefix = '<leader>' -- Prefix for file jump
      remove_mark_file = '<leader>jd' -- Delete the mark from this file
      remove_marks = '<leader>jr' -- Remove all marks
    },
  }
```

It can also be initialized through a `setup` call:

```lua
  require('mark-jumps').setup {}
```

or, with options

```lua
  require('mark-jumps').setup {
    add_mark_file = '<leader>ja' -- How to add a mark to the current file
    choose_change = '<leader>jc' -- Add a mark to this file by removing another
    choose_delete = '<leader>jx' -- Choose a mark to delete
    choose_file = '<leader>js' -- Picker to choose which file to go to
    mark_names = { 'A', 'B', 'C', 'D' } -- Which marks can the plugin use
    prefix = '<leader>' -- Prefix for file jump
    remove_mark_file = '<leader>jd' -- Delete the mark from this file
    remove_marks = '<leader>jr' -- Remove all marks
  }
```

## Inspiration

This plugin is inspired by [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)

## TODO

- Keep track of marks per project
- Allow more mapping flexibility
