local insert_surround = function(textobj, ins_char)
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys("ys" .. esc, "x", false)
    vim.api.nvim_feedkeys("g@" .. textobj .. ins_char, "x", false)
end

local delete_surround = function(del_char)
    require("nvim-surround").delete_surround(del_char)
end

local change_surround = function(del_char, ins_char)
    require("nvim-surround").change_surround(del_char, ins_char)
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
        insert_surround("iw", "\"")

        assert.are.same({
            "local str = \"test\"",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
        insert_surround("a\"", "b")
        assert.are.same({
            "local str = (\"test\")",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)

    it("can delete surrounding quotes/parens", function()
        set_lines({ "local str = (\"test\")" })
        vim.fn.cursor({ 1, 13 })
        delete_surround("b")
        delete_surround("\"")

        assert.are.same({
            [[local str = test]],
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)

    it("can change surrounding delimiters", function()
        set_lines({
            "require'nvim-surround'.setup(",
            "",
            ")",
        })
        vim.fn.cursor({ 1, 8 })
        insert_surround("a'", "b")
        vim.fn.cursor({ 1, 9 })
        change_surround("'", '"')
        vim.fn.cursor({ 2, 1 })
        change_surround("b", "B")
        insert_surround("aB", "b")
        assert.are.same({
            "require(\"nvim-surround\").setup({",
            "",
            "})",
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)

    it("can delete quotes using aliases", function()
        set_lines({ "local str = \"test\"" })
        vim.fn.cursor({ 1, 13 })
        delete_surround("q")

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
