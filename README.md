# nvim-surround

Surround selections, stylishly :sunglasses:

***WARNING:*** This plugin is in *very early* development, and things are likely
to not work, let alone be stable.

## Features

### The Basics

* Surround text objects with delimiters using `ys`, e.g. `ysiw"`
  * Alternatively, visually select text and use `S`, e.g. `Sb`
* Delete surrounding delimiters using `ds`, e.g. `dsB`
* Change surrounding delimiters using `cs`, e.g. `csBb`
* This plugin aims to be more or less compatible with
  [vim-surround](https://github.com/tpope/vim-surround)

### Bonus!

* Surround using HTML tags, e.g. `ysiwtdiv<CR>`
  * Changing surrounding HTML tags only changes the tag type, not any attributes
* Modify surrounding delimiters using aliases, e.g. `q` to represent any quote
  * By default, nvim-surround will choose the closest pair that the cursor
    resides in
  * For example, with the cursor denoted by `^`, if we run `csqb` in
  ```
  string s = "Hello 'world'!"
                      ^
  ```
  then we get
  ```
  string s = "Hello (world)!"
  ```

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

TODO: Make these a part of the setup configuration (via variables), and set by
default

There are no keymaps set by default, but here's how to mimic
[vim-surround](https://github.com/tpope/vim-surround): 

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
* Implement dot repeating for modifying surrounds
* Add some sort of setup function, allowing users to modify delimiter
  pairs/aliases without directly modifying internal variables

## Future Ideas

* Try to implement "aliases" for different delimiter pair types, in a fashion
  similar to [targets.vim](https://github.com/wellle/targets.vim)

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
* Like this project? Give it a :star: to show your support!
