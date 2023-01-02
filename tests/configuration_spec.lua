local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
local set_curpos = function(pos)
    vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] - 1 })
end
local set_lines = function(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end
local check_lines = function(lines)
    assert.are.same(lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

describe("configuration", function()
    before_each(function()
        local bufnr = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(0, bufnr)
    end)

    it("can define own add mappings", function()
        require("nvim-surround").setup({
            surrounds = {
                ["1"] = { add = { "1", "1" } },
                ["2"] = { add = { "2", { "2" } } },
                ["3"] = { add = { { "3" }, "3" } },
                ["f"] = { add = { { "int main() {", "    " }, { "", "}" } } },
            },
        })

        set_lines({
            "hello world",
            "more text",
            "another line",
            "interesting stuff",
        })
        set_curpos({ 1, 1 })
        vim.cmd("normal yss1")
        set_curpos({ 2, 1 })
        vim.cmd("normal yss2")
        set_curpos({ 3, 1 })
        vim.cmd("normal yss3")
        set_curpos({ 4, 1 })
        vim.cmd("normal yssf")
        check_lines({
            "1hello world1",
            "2more text2",
            "3another line3",
            "int main() {",
            "    interesting stuff",
            "}",
        })
    end)

    it("can disable surrounds", function()
        require("nvim-surround").setup({
            surrounds = {
                ["("] = false,
            },
        })

        set_lines({
            "hello world",
        })
        vim.cmd("normal yss(")
        check_lines({
            "(hello world(",
        })
    end)

    it("can change invalid_key_behavior", function() -- TODO: What should invalid_key_behavior do on false?
        require("nvim-surround").setup({
            surrounds = {
                invalid_key_behavior = {
                    add = function(char)
                        return { { "begin" .. char }, { char .. "end" } }
                    end,
                },
            },
        })

        set_lines({
            "hello world",
        })
        vim.cmd("normal yss|")
        check_lines({
            "begin|hello world|end",
        })
    end)

    it("can disable indent_lines", function()
        require("nvim-surround").setup({
            indent_lines = false,
        })

        vim.bo.filetype = "html"
        set_lines({ "some text" })
        vim.cmd("normal ySStdiv" .. cr)
        check_lines({
            "<div>",
            "some text",
            "</div>",
        })
        vim.bo.filetype = nil
    end)
end)
