describe("nvim-surround", function()
    it("can be required with an empty setup table", function()
        require("nvim-surround").setup({})
        assert.are.same(
            require("nvim-surround.utils").delimiters,
            require("nvim-surround.config").default_opts.delimiters
        )
    end)

    it("can modify/disable default delimiters", function()
        require("nvim-surround").setup({
            delimiters = {
                pairs = {
                    ["b"] = { "{", "}" },
                    ["B"] = false,
                },
                HTML = {
                    ["t"] = false,
                },
            }
        })

        local utils = require("nvim-surround.utils")
        assert.are.same(
            { "{", "}" },
            utils.delimiters.pairs.b
        )
        assert.are.same(
            false,
            utils.delimiters.pairs.B
        )
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

    --[=[
    it("can delete surrounding quotes", function()
        require("nvim-surround").setup()
        vim.fn.cursor({ 1, 13 })
        require("nvim-surround").delete_surround()
        vim.api.nvim_feedkeys("\"", "x", false)
        assert.are.same({
            [[local str = test]],
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)
    --]=]

    --[=[
    it("change surrounding quotes to parentheses", function()
        require("nvim-surround").setup()
        vim.fn.cursor({ 1, 13 })
        vim.api.nvim_feedkeys("dsq", "x", false)
        assert.are.same({
            [[local str = (test)]],
        }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)
    --]=]
end)
