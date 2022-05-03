# nvim-surround

Surrounding structures, simply.

***WARNING:*** This plugin is in *very early* development, and things are likely
to not work, let alone be stable.

## Installation

<table style="text-align:center">
   <thead>
      <tr>
         <th>Package Manager</th>
         <th>Installation Code</th>
      </tr>
   </thead>
   <tbody>
      <tr>
         <td>
          <a href = "https://github.com/wbthomason/packer.nvim">packer.nvim</a>
         </td>
         <td>
          <code>use "kylechui/nvim-surround"</code>
         </td>
      </tr>
      <tr>
        <td>
          <a href = "https://github.com/junegunn/vim-plug">vim-plug</a>
        </td>
        <td>
          <code>Plug "kylechui/nvim-surround"</code>
        </td>
      </tr>
   </tbody>
</table>

## Setup

**TODO:** Document how to setup and use this plugin!

## Commands

Nothing in this plugin is set up by default, but here are some potential
defaults:

```lua
local map = vim.keymap.set

-- Surrounds a text object with a delimiter pair, i.e. ysiw]
map("n", "ys", require("nvim-surround").insert_surround)
-- Delete a surrounding delimiter, i.e. ds(
map("n", "ds", require("nvim-surround").delete_surround)
-- Changes the surrounding delimiter, i.e. cs'"
map("n", "cs", require("nvim-surround").change_surround)
-- Surrounds a visual selection with a delimiter, i.e. S{
map("x", "S", require("nvim-surround").insert_surround)
```

## TODO

* Find a better way to use `operatorfunc`
  * There's probably a better way to avoid the `va"` whitespace situation
* Add a method for surrounding around visual line selections
* Move more functions out of `init.lua`, start creating files other than
  `utils.lua` to better sort/separate functions
  * Perhaps only use `init.lua` for user-facing functions
* Add some sort of setup function, allowing users to modify delimiter pairs

## Future Ideas

* Try to implement "aliases" for different delimiter pair types, in a fashion
  similar to [targets.vim](https://github.com/wellle/targets.vim)
* Implement `t` for HTML tags, i.e. `cst<h1>`, `dst`

## Similar Projects

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
