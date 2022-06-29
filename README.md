# nvim-surround

Surround selections, stylishly :sunglasses:

> **Warning**: This plugin is still in early development, so some things might
> not be fully fleshed out or stable. Feel free to open an issue or pull
> request!

## :sparkles: Features

* Surround text objects/visual selections with delimiter pairs
* Delete/Change surrounding delimiters
* Quickly add/change/remove surrounding HTML tags
  * Change *only* the surrounding HTML tag's element type, and leave its
    attributes
* Use a single character as an alias for several text-objects
  * E.g. `q` is aliased to <code>\`,',"</code>, so <code>csqb</code> replaces
    the *nearest* set of quotes with parentheses

## :package: Installation

Install this plugin with your favorite package manager:

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
-- Lua
use({
    "kylechui/nvim-surround",
    config = function()
        require("nvim-surround").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
})
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
" Vim Script
Plug "kylechui/nvim-surround"

lua << EOF
    require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
    })
EOF
```

## :gear: Configuration

The default configuration is as follows:

```lua
require("nvim-surround").setup({
    keymaps = { -- vim-surround style keymaps
        insert = "ys",
        visual = "S",
        delete = "ds",
        change = "cs",
    }
})
```

## :white\_check\_mark: TODO

* Find a better way to use `operatorfunc`
  * There's probably a better way to avoid the `va"` white space situation
* Implement dot repeating for modifying surrounds
* Allow users to modify the delimiter pairs via the setup function
* Add GIF demonstrating functionality in README

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvimminisurround)
* Like this project? Give it a :star: to show your support!
