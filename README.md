# nvim-surround

Surrounding structures, simply.

***WARNING:*** This plugin is in *very early* development, and things are likely
to not work, let alone be stable.

## Setup

**TODO:** Document how to setup and use this plugin!

## Commands

Nothing in this plugin is set up by default, but here are some potential
defaults:

```lua
local map = vim.keymap.set

-- The basic surround mode that will take a text-object and surround it with a
-- delimiter, i.e. ysiw'
map("n", "ys", require("nvim-surround").operator_surround, { expr = true })
-- Surrounds a visual selection with a delimiter, i.e. S{
map("x", "S", require("nvim-surround").visual_surround, { expr = true })
```

## Known Issues

* Doesn't have any sort of configuration
* Lacks deletion or changing surrounding delimiter pair

## Acknowledgements

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
