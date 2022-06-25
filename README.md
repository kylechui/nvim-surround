# nvim-surround

Surround selections, stylishly :sunglasses:

> **Warning**: This plugin is still in early development, so some things might
> not be fully fleshed out or stable. Feel free to open an issue or pull
> request!

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
The default configuration is as follows:
```lua
require("nvim-surround").setup({
    keymaps = {
        insert = "ys",
        visual = "S",
        delete = "ds",
        change = "cs",
    }
})
```

## Features

### The Basics

The basic functionality of this plugin can be found in the README of
[vim-surround](https://github.com/tpope/vim-surround):

* Surround text objects with delimiters
  * Alternatively, surround using visual selections instead
* Delete surrounding delimiters
* Change surrounding delimiters

### Bonus!

* Surround selections using HTML tags
  * Changing surrounding HTML tags only changes the element, not the attributes
* Modify surrounding delimiters using aliases, e.g. `q` to represent any quote
  * By default, nvim-surround will choose the closest pair that the cursor
    is contained in
  * For example, with the cursor denoted by `^`, if we run `csqb` on
    ```
    string s = "Hello 'world'!"
                        ^
    ```
    then we get
    ```
    string s = "Hello (world)!"
    ```

## TODO

* Get rid of the ugly `set opfunc=...` when changing/deleting
* Find a better way to use `operatorfunc`
  * There's probably a better way to avoid the `va"` white space situation
* Implement dot repeating for modifying surrounds
* Allow users to modify the delimiter pairs via the setup function

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
* Like this project? Give it a :star: to show your support!
