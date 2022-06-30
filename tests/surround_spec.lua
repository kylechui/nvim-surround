local surround_cmd = function(cmd)
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    if cmd:sub(1, 2) == "ys" then
        vim.api.nvim_feedkeys("ys" .. esc, "x", false)
        vim.api.nvim_feedkeys("g@" .. cmd:sub(3, #cmd), "x", false)
    else
        vim.api.nvim_feedkeys(cmd, "x", false)
    end
end

local set_lines = function(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

describe("nvim-surround", function()
    before_each(function()
        -- Setup default keybinds (can be overwritten with subsequent calls)
        require("nvim-surround").setup({})
    end)

    it("can be required with an empty setup table", function()
        require("nvim-surround").setup({})
        assert.are.same(
            require("nvim-surround.utils").delimiters,
            require("nvim-surround.config").default_opts.delimiters
        )
    end)

    it("can surround text-objects", function()
        set_lines({ "local str = test" })
        vim.fn.cursor({ 1, 13 })
        surround_cmd("ysiw\"")

        assert.are.same({
            "local str = \"test\"",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
        surround_cmd("ysa\"b")
        assert.are.same({
            "local str = (\"test\")",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)

    it("can delete surrounding quotes/parens", function()
        set_lines({ "local str = (\"test\")" })
        vim.fn.cursor({ 1, 13 })
        surround_cmd("dsb")
        surround_cmd("ds\"")

        assert.are.same({
            [[local str = test]],
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)

    it("can delete quotes using aliases", function()
        set_lines({ "local str = \"test\"" })
        vim.fn.cursor({ 1, 13 })
        surround_cmd("dsq")

        assert.are.same({
            [[local str = test]],
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)

    it("can disable default delimiters", function()
        require("nvim-surround").setup({
            delimiters = {
                HTML = {
                    ["t"] = false,
                },
            }
        })

        local utils = require("nvim-surround.utils")
        assert.are.same(
            false,
            utils.delimiters.HTML.t
        )
    end)

    it("can modify aliases", function()
        require("nvim-surround").setup({
            delimiters = {
                pairs = {
                    ["b"] = false,
                },
                aliases = {
                    ["b"] = { ")", "}" }
                }
            }
        })

        local utils = require("nvim-surround.utils")
        assert.are.same(
            false,
            utils.delimiters.pairs.b
        )
        assert.are.same(
            { ")", "}" },
            utils.delimiters.aliases.b
        )
    end)
end)
