# nvim-surround

Surround selections, stylishly :sunglasses:

<div align="center">
  <video src="https://user-images.githubusercontent.com/48545987/178679494-c7d58bdd-d8ca-4802-a01c-a9444b8b882f.mp4" type="video/mp4"></video>
</div>

## :sparkles: Features

* Add/change/remove surrounding pairs and HTML tags
  * Change *only* the surrounding HTML tag's element type, and leave its
    attributes
* Dot-repeat previous actions
* Set buffer-local mappings and surrounds
* Surround using powerful pairs that depend on user input
* Jump to the *nearest* surrounding pair for modification
* Use a single character as an alias for several text-objects
  * E.g. `q` is aliased to <code>\`,',"</code>, so <code>csqb</code> replaces
    the *nearest* set of quotes with parentheses
* Highlight the section that you are about to surround, as a visual indicator

For more information, see [`:h
nvim-surround`](https://github.com/kylechui/nvim-surround/blob/main/doc/nvim-surround.txt).

## :package: Installation

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
    "kylechui/nvim-surround",
    config = function()
        require("nvim-surround").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
})
```

## :rocket: Usage

Information on how to use this plugin can be found in [the
wiki](https://github.com/kylechui/nvim-surround/wiki).

## :gear: Configuration

### The Basics

All delimiter keys should be one character *exactly*, and *unique*. In the
`delimiters` table, each value is either a pair of strings, representing the
left and right surrounding pair, or a function returning a pair of strings.
Multi-line strings are represented by tables of strings, with each string
representing a new line.

> Looking for inspiration/examples? Want to share some cool surrounds that
> you've made? You can visit the [surrounds
> showcase](https://github.com/kylechui/nvim-surround/discussions/53) to see a
> community-made list of custom surrounds!

### Modifying Defaults

To change a preset, give the corresponding key a new value. To disable any
functionality, simply set the corresponding key's value to `false`. For example,

```lua
require("nvim-surround").setup({
    delimiters = {
        pairs = { -- Remaps "a" and "b"
            ["a"] = {
                { "this", "has", "several", "lines" },
                "single line",
            },
            ["b"] = function()
                return {
                    "hello",
                    "world",
                }
            end,
        },
        HTML = { -- Disables HTML-style mappings
            ["t"] = false,
            ["T"] = false,
        },
    },
    highlight_motion = { -- Disables highlights
        duration = false,
    },
})
```

For buffer-local configurations, just call
`require("nvim-surround").buffer_setup` for any buffer that you would like to
configure. This can be especially useful for setting filetype-specific surrounds
by calling `buffer_setup` inside `ftplugin/[filetype].lua`.

For more information, see [`:h
nvim-surround`](https://github.com/kylechui/nvim-surround/blob/main/doc/nvim-surround.txt),
or the [default configuration](https://github.com/kylechui/nvim-surround/blob/main/lua/nvim-surround/config.lua).

## Contributing

See [the contributing
file](https://github.com/kylechui/nvim-surround/blob/main/CONTRIBUTING.md).

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
* [vim-sandwich](https://github.com/machakann/vim-sandwich)
* Like this project? Give it a :star: to show your support!
