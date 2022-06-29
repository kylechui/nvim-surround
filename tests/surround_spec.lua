describe("nvim-surround", function()
    it("can be required with no setup table", function()
        require("nvim-surround").setup()
    end)

    it("can be required with an empty setup table", function()
        require("nvim-surround").setup({})
    end)

    local buffer_contents = {
        [[local str = test]],
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, true, buffer_contents)

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
