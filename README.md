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

### The Basics

This plugin serves to help you accomplish three common actions quickly and
efficiently:

* Surrounding some selection with a left and right delimiter
* Deleting the surrounding delimiter pair (around the cursor)
* Changing the surrounding delimiter pair (around the cursor) to another pair

The following examples are all run from Normal mode, unless otherwise specified.

#### Adding New Surrounds

By default, adding new surrounds is done by the keymap prefix `ys`, which can be
thought of as meaning "you surround". It is used via `ys[object][char]`, where
`object` denotes the
[text-object](https://vimhelp.org/motion.txt.html#object-select) that you are
surrounding with a delimiter pair defined by `char`. Consider the example
buffer:

```lua
local str = "This is a sentence"
```

If the cursor is on the `T` and you press `ysiw'`, then "you surround inner word
with single quotes", yielding:

```lua
local str = "'This' is a sentence"
```

From here, typing `ysa")` means "you surround around double quotes with
parentheses", yielding:

```lua
local str = ("'This' is a sentence")
```

Surrounds can also be added by first selecting the text *in Visual mode*, then
pressing `S[char]`, e.g. `VS]`.

#### Deleting Surrounds

By default, deleting surrounding pairs is done by the keymap prefix `ds`, which
can be thought of as meaning "delete surround". It is used via `ds[char]`, where
`char` refers to the pair to be deleted. Consider the example buffer:

```lua
require("nvim-surround").setup()
```

If the cursor is on the `-` and you press `ds"`, then you "delete surrounding
double quotes", yielding:

```lua
require(nvim-surround).setup()
```

From here, typing `ds(` means "delete surrounding parentheses", yielding:

```lua
requirenvim-surround.setup()
```

#### Changing Surrounds

By default, changing surrounding pairs is done by the keymap prefix `cs`, which
can be thought of as meaning "change surround". It is used via
`cs[char1][char2]`, where `char1` refers to the pair to be deleted, and `char2`
represents the pair to replace it. Consider the example buffer:

```lua
local tab = { 'Just', (some), "strings" }
```

If the cursor is on the `J` and you press `cs'"`, then you "change surrounding
single quotes to double quotes", yielding:

```lua
local tab = { "Just", (some), "strings" }
```

From here, typing `cs("` means "change surrounding parentheses to double
quotes", yielding:

```lua
local tab = { "Just", "some", "strings" }
```

> **Note**: If there are no pairs that are immediately surrounding the cursor, it
> can *jump* to the "nearest pair" (forwards or backwards). See `:h
> nvim-surround.jump` for more details.

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
or the default configuration below.

<details>
<summary><b>Default Configuration</b></summary>

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
    highlight_motion = { -- Highlight before inserting/changing surrounds
        duration = 0,
    }
})
```

</details>

## Contributing

All contributions are welcome :smile: If you have a bug/feature request, you can
open [a new issue](https://github.com/kylechui/nvim-surround/issues/new/choose).
General discussion/questions can be put in the [discussions
page](https://github.com/kylechui/nvim-surround/discussions). Thanks for the
help!

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
* [vim-sandwich](https://github.com/machakann/vim-sandwich)
* Like this project? Give it a :star: to show your support!
