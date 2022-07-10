# nvim-surround

Surround selections, stylishly :sunglasses:

<div align="center">
  <video src="https://user-images.githubusercontent.com/48545987/178091618-f477b51d-d366-4de2-84a8-cbf4f72928e3.mp4" type="video/mp4" width="800">
</div>

## :sparkles: Features

* Add/change/remove surrounding pairs and HTML tags
  * Change *only* the surrounding HTML tag's element type, and leave its
    attributes
* Dot-repeat previous actions
* Set buffer-local mappings and surrounds
* Surround using powerful pairs that depend on user input
* Use a single character as an alias for several text-objects
  * E.g. `q` is aliased to <code>\`,',"</code>, so <code>csqb</code> replaces
    the *nearest* set of quotes with parentheses
* Highlight the section that you are about to surround, as a visual indicator

For more information, see `:h nvim-surround`

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
        insert_line = "yss",
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
            -- Define pairs based on function evaluations!
            ["i"] = function()
                return {
                    require("nvim-surround.utils").get_input(
                        "Enter the left delimiter: "
                    ),
                    require("nvim-surround.utils").get_input(
                        "Enter the right delimiter: "
                    )
                }
            end,
            ["f"] = function()
                return {
                    require("nvim-surround.utils").get_input(
                        "Enter the function name: "
                    ) .. "(",
                    ")"
                }
            end,
        },
        separators = {
            ["'"] = { "'", "'" },
            ['"'] = { '"', '"' },
            ["`"] = { "`", "`" },
        },
        HTML = {
            ["t"] = "type", -- Change just the tag type
            ["T"] = "whole", -- Change the whole tag contents
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

For buffer-local configurations, just call
`require("nvim-surround").buffer_setup` for any buffer that you would like to
configure, e.g.

```lua
-- ftplugin/python.lua
require("nvim-surround").buffer_setup({
    delimiters = {
        pairs = {
            ["f"] = function()
                return {
                    "def " .. require("nvim-surround.utils").get_input(
                        "Enter the function name: "
                    ) .. "(",
                    "):"
                }
            end,
        }
    }
})
-- ftplugin/lua.lua
require("nvim-surround").buffer_setup({
    delimiters = {
        pairs = {
            ["f"] = function()
                return {
                    "function " .. require("nvim-surround.utils").get_input(
                        "Enter the function name: "
                    ) .. "(",
                    ")"
                }
            end,
        }
    }
})
```

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
* [vim-sandwich](https://github.com/machakann/vim-sandwich)
* Like this project? Give it a :star: to show your support!
