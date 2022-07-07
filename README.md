# nvim-surround

Surround selections, stylishly :sunglasses:

> **Warning**: This plugin is still in early development, so some things might
> not be fully fleshed out or stable. Feel free to open an issue or pull
> request!

<div align="center">
  <video src="https://user-images.githubusercontent.com/48545987/176824692-28c16e7b-5f30-4ba9-8f23-6d4b9c050428.mp4" type="video/mp4" width="800">
</div>

## :sparkles: Features

* Add/change/remove surrounding pairs and HTML tags
* Dot-repeat previous actions
* Change *only* the surrounding HTML tag's element type, and leave its
  attributes
* Use a single character as an alias for several text-objects
  * E.g. `q` is aliased to <code>\`,',"</code>, so <code>csqb</code> replaces
    the *nearest* set of quotes with parentheses
* Highlight the section that you are about to surround, as a visual indicator

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
    },
    delimiters = {
        pairs = {
            ["("] = { "( ", " )" },
            [")"] = { "(", ")" },
            ["{"] = { "{ ", " }" },
            ["}"] = { "{", "}" },
            ["<"] = { "< ", " >" },
            [">"] = { "<", ">" },
            ["["] = { "[ ", " ]" },
            ["]"] = { "[", "]" },
        },
        separators = {
            ["'"] = { "'", "'" },
            ['"'] = { '"', '"' },
            ["`"] = { "`", "`" },
        },
        HTML = {
            ["t"] = true, -- Use "t" for HTML-style mappings
        },
        aliases = {
            ["a"] = ">", -- Single character aliases apply everywhere
            ["b"] = ")",
            ["B"] = "}",
            ["r"] = "]",
            -- Table aliases only apply for changes/deletions
            ["q"] = { '"', "'", "`" }, -- Any quote character
            ["s"] = { ")", "]", "}", ">", "'", '"', "`" }, -- Any surrounding delimiter
        },
    },
    highlight_motion = { -- Highlight text-objects before surrounding them
        duration = 0,
    }
})
```

All keys should be one character *exactly*. To overwrite any functionality, you
only need to specify the keys that you wish to modify. To disable any
functionality, simply set the corresponding key's value to `false`. For example,

```lua
require("nvim-surround").setup({
    delimiters = {
        pairs = {
            ["b"] = { "{", "}" },
        },
        HTML = { -- Disables HTML-style mappings
            ["t"] = false,
        },
    },
})
```

## :white\_check\_mark: TODO

* Fix the bajillion bugs that exist
* Find a better way to use `operatorfunc`
  * There's probably a better way to avoid the `va"` white space situation

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
* [vim-sandwich](https://github.com/machakann/vim-sandwich)
* Like this project? Give it a :star: to show your support!
