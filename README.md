# nvim-surround

Surround selections, stylishly :sunglasses:

<div align="center">
  <video src="https://user-images.githubusercontent.com/48545987/178679494-c7d58bdd-d8ca-4802-a01c-a9444b8b882f.mp4" type="video/mp4"></video>
</div>

## :sparkles: Features

* Add/delete/change surrounding pairs
  * Function calls and HTML tags out-of-the-box
* Dot-repeat previous actions
* Set buffer-local mappings and surrounds
* Jump to the *nearest* surrounding pair for modification
* Use a single character as an alias for several text-objects
  * E.g. `q` is aliased to <code>\`,',"</code>, so <code>csqb</code> replaces
    the *nearest* set of quotes with parentheses
* Surround using powerful pairs that depend on user input
* Modify custom surrounds
  * First-class support for text-objects and Lua patterns
* Highlight selections for visual feedback

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

The three "core" operations of `add`/`delete`/`change` can be done with the
keymaps `ys{motion}{char}`, `ds{char}`, and `cs{target}{replacement}`,
respectively. For the following examples, `*` will denote the cursor position:

```help
    Old text                    Command         New text
--------------------------------------------------------------------------------
    surr*ound_words             ysiw)           (surround_words)
    *make strings               ys$"            "make strings"
    [delete ar*ound me!]        ds]             delete around me!
    remove <b>HTML t*ags</b>    dst             remove HTML tags
    'change quot*es'            cs'"            "change quotes"
    <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
    delete(functi*on calls)     dsf             function calls
```

Detailed information on how to use this plugin can be found in [`:h
nvim-surround.usage`](https://github.com/kylechui/nvim-surround/blob/main/doc/nvim-surround.txt).

## :gear: Configuration

The default configuration is found
[here](https://github.com/kylechui/nvim-surround/blob/main/lua/nvim-surround/config.lua).
Simply call `require("nvim-surround").setup` or
`require("nvim-surround").buffer_setup` with the desired options.

More information on how to configure this plugin can be found in [`:h
nvim-surround.configuration`](https://github.com/kylechui/nvim-surround/blob/main/doc/nvim-surround.txt).

## Contributing

See [the contributing
file](https://github.com/kylechui/nvim-surround/blob/main/CONTRIBUTING.md).

## Shoutouts

* [vim-surround](https://github.com/tpope/vim-surround)
* [mini.surround](https://github.com/echasnovski/mini.nvim#minisurround)
* [vim-sandwich](https://github.com/machakann/vim-sandwich)
* Like this project? Give it a :star: to show your support!
