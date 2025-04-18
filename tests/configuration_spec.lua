local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
local ctrl_v = vim.api.nvim_replace_termcodes("<C-v>", true, false, true)
local get_curpos = function()
    local curpos = vim.api.nvim_win_get_cursor(0)
    return { curpos[1], curpos[2] + 1 }
end
local set_curpos = function(pos)
    vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] - 1 })
end
local check_curpos = function(pos)
    assert.are.same({ pos[1], pos[2] - 1 }, vim.api.nvim_win_get_cursor(0))
end
local set_lines = function(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end
local check_lines = function(lines)
    assert.are.same(lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end
local get_extmarks = function()
    return vim.api.nvim_buf_get_extmarks(0, require("nvim-surround.buffer").namespace.extmark, 0, -1, {})
end

describe("configuration", function()
    before_each(function()
        local bufnr = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(0, bufnr)
    end)

    it("can define own add mappings", function()
        require("nvim-surround").buffer_setup({
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

    it("can define and use multi-byte mappings", function()
        require("nvim-surround").setup({
            surrounds = {
                -- multi-byte quote
                ["“"] = {
                    add = { "„", "“" },
                    find = "„.-“",
                    delete = "^(„)().-(“)()$",
                },
            },
            aliases = {
                ["•"] = ")",
            },
        })

        set_lines({ "hey! hello world" })
        set_curpos({ 1, 7 })
        vim.cmd("normal ysiw“")
        check_lines({ "hey! „hello“ world" })
        vim.cmd("normal ds“")
        check_lines({ "hey! hello world" })

        vim.cmd("normal yss•")
        check_lines({ "(hey! hello world)" })
        vim.cmd("normal ds•")
        check_lines({ "hey! hello world" })
    end)

    it("can define and use 'interpreted' multi-byte mappings", function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                -- interpreted multi-byte
                ["<M-]>"] = {
                    add = { "[[", "]]" },
                    find = "%[%b[]%]",
                    delete = "^(%[%[)().-(%]%])()$",
                },
            },
            aliases = {
                ["<CR>"] = ")",
            },
        })
        local meta_close_bracket = vim.api.nvim_replace_termcodes("<M-]>", true, false, true)
        set_lines({ "hey! hello world" })
        set_curpos({ 1, 7 })
        vim.cmd("normal ysiw" .. meta_close_bracket)
        check_lines({ "hey! [[hello]] world" })
        vim.cmd("normal ds" .. meta_close_bracket)
        check_lines({ "hey! hello world" })

        vim.cmd("normal yss" .. cr)
        check_lines({ "(hey! hello world)" })
        vim.cmd("normal ds" .. cr)
        check_lines({ "hey! hello world" })
    end)

    it("default deletes using invalid_key_behavior for an 'interpreted' multi-byte mapping", function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                -- interpreted multi-byte
                ["<C-q>"] = {
                    add = { "‘", "’" },
                    find = "‘.-’",
                },
            },
        })
        local ctrl_q = vim.api.nvim_replace_termcodes("<C-q>", true, false, true)
        set_lines({ "hey! hello world" })
        set_curpos({ 1, 7 })
        vim.cmd("normal ysiw" .. ctrl_q)
        check_lines({ "hey! ‘hello’ world" })
        vim.cmd("normal ds" .. ctrl_q)
        check_lines({ "hey! hello world" })
    end)

    it("can use 'syntactic sugar' for add functions", function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["("] = {
                    add = function()
                        return { "<<", ">>" }
                    end,
                },
            },
        })

        set_lines({
            "hello world",
        })
        vim.cmd("normal yss(")
        check_lines({
            "<<hello world>>",
        })
    end)

    it("can disable surrounds", function()
        require("nvim-surround").buffer_setup({
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

    it("can change invalid_key_behavior", function()
        require("nvim-surround").buffer_setup({
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
        require("nvim-surround").buffer_setup({
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

    it("can disable invalid_key_behavior", function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                invalid_key_behavior = false,
            },
        })

        set_lines({
            "hello world",
        })
        vim.cmd("normal yssx")
        check_lines({
            "hello world",
        })
    end)

    it("can disable cursor movement for actions", function()
        require("nvim-surround").buffer_setup({ move_cursor = false })
        set_lines({
            [[And jump "forwards" and `backwards` to 'the' "nearest" surround.]],
        })
        set_curpos({ 1, 27 })

        vim.cmd("normal dsq")
        assert.are.same(get_curpos(), { 1, 27 })
        check_lines({
            [[And jump "forwards" and backwards to 'the' "nearest" surround.]],
        })

        vim.cmd("normal ysa'\"")
        check_lines({
            [[And jump "forwards" and backwards to "'the'" "nearest" surround.]],
        })

        vim.cmd("normal dsq")
        assert.are.same(get_curpos(), { 1, 27 })
        vim.cmd("normal! ..")
        assert.are.same(get_curpos(), { 1, 27 })
        check_lines({
            [[And jump forwards and backwards to the "nearest" surround.]],
        })

        vim.cmd("normal csqb")
        assert.are.same(get_curpos(), { 1, 27 })
        check_lines({
            [[And jump forwards and backwards to the (nearest) surround.]],
        })

        set_curpos({ 1, 5 })
        vim.cmd("normal v")
        set_curpos({ 1, 31 })
        vim.cmd('normal S"')
        assert.are.same(get_curpos(), { 1, 31 })
        check_lines({
            [[And "jump forwards and backwards" to the (nearest) surround.]],
        })
        vim.cmd("normal yss)")
        assert.are.same(get_curpos(), { 1, 31 })
        check_lines({
            [[(And "jump forwards and backwards" to the (nearest) surround.)]],
        })
    end)

    it("can move the cursor to the beginning of an action", function()
        set_lines({
            [[And jump "forwards" and `backwards` to 'the' "nearest" surround.]],
        })
        set_curpos({ 1, 27 })

        vim.cmd("normal dsq")
        assert.are.same(get_curpos(), { 1, 25 })
        check_lines({
            [[And jump "forwards" and backwards to 'the' "nearest" surround.]],
        })

        vim.cmd("normal ysa'\"")
        assert.are.same(get_curpos(), { 1, 38 })
        check_lines({
            [[And jump "forwards" and backwards to "'the'" "nearest" surround.]],
        })

        vim.cmd("normal dsq")
        assert.are.same(get_curpos(), { 1, 38 })
        vim.cmd("normal! ..")
        assert.are.same(get_curpos(), { 1, 19 })
        check_lines({
            [[And jump "forwards and backwards to the nearest" surround.]],
        })

        vim.cmd("normal csqb")
        assert.are.same(get_curpos(), { 1, 10 })
        check_lines({
            [[And jump (forwards and backwards to the nearest) surround.]],
        })

        set_curpos({ 1, 11 })
        vim.cmd("normal v")
        set_curpos({ 1, 32 })
        vim.cmd('normal S"')
        assert.are.same(get_curpos(), { 1, 11 })
        check_lines({
            [[And jump ("forwards and backwards" to the nearest) surround.]],
        })
    end)

    it("can make the cursor 'stick' to the text (normal)", function()
        require("nvim-surround").buffer_setup({
            move_cursor = "sticky",
            surrounds = {
                ["c"] = { add = { "singleline", "surr" } },
                ["d"] = { add = { { "multiline", "f" }, "" } },
                ["e"] = { add = { { "multiline", "f" }, { "", "shouldbethislength" } } },
                ["f"] = { add = { "singleline", { "", "multilinehere" } } },
            },
        })

        -- Sticks to the text if the cursor is inside the selection
        set_lines({
            "this is a line",
        })
        set_curpos({ 1, 9 })
        vim.cmd("normal ysiwc")
        check_curpos({ 1, 19 })

        set_lines({
            "this is a line",
        })
        set_curpos({ 1, 4 })
        vim.cmd("normal ysiwd")
        check_curpos({ 2, 5 })

        set_lines({
            "this is another line",
        })
        set_curpos({ 1, 14 })
        vim.cmd("normal ysiwe")
        check_curpos({ 2, 7 })

        set_lines({
            "this is a line",
        })
        set_curpos({ 1, 9 })
        vim.cmd("normal ysiwf")
        check_curpos({ 1, 19 })

        -- Doesn't move if the cursor is before the selection
        set_lines({
            "this 'is' a line",
        })
        set_curpos({ 1, 2 })
        vim.cmd("normal ysa'c")
        vim.cmd("normal ysa'd")
        vim.cmd("normal ysa'e")
        vim.cmd("normal ysa'f")
        check_curpos({ 1, 2 })

        assert.are.same(get_extmarks(), {})
    end)

    it("can make the cursor 'stick' to the text (visual)", function()
        require("nvim-surround").buffer_setup({
            move_cursor = "sticky",
        })

        set_lines({
            "this is a line",
        })
        set_curpos({ 1, 9 })
        vim.cmd("normal vllS'")
        check_curpos({ 1, 12 })

        set_lines({
            "this is a line",
            "with some more text",
        })
        set_curpos({ 1, 6 })
        vim.cmd("normal vjeSb")
        check_curpos({ 2, 9 })

        set_lines({
            "this is a line",
            "with some more text",
        })
        set_curpos({ 1, 6 })
        vim.cmd("normal vjeoSb")
        check_curpos({ 1, 7 })

        assert.are.same(get_extmarks(), {})
    end)

    it("can make the cursor 'stick' to the text (visual line)", function()
        require("nvim-surround").buffer_setup({
            move_cursor = "sticky",
        })

        set_lines({
            "this is a line",
        })
        set_curpos({ 1, 9 })
        vim.cmd("normal VSb")
        check_curpos({ 2, 9 })

        set_lines({
            "this is a line",
            "with some more text",
        })
        set_curpos({ 1, 6 })
        vim.cmd("normal VjStdiv" .. cr)
        check_curpos({ 3, 6 })

        assert.are.same(get_extmarks(), {})
    end)

    it("can make the cursor 'stick' to the text (visual block)", function()
        require("nvim-surround").buffer_setup({
            move_cursor = "sticky",
            surrounds = {
                ["x"] = {
                    add = { { "|", "" }, { "", "|" } },
                },
            },
        })

        set_lines({
            "this is a line",
            "this is another line",
        })
        set_curpos({ 1, 5 })
        vim.cmd("normal! " .. ctrl_v .. "jf ")
        vim.cmd("normal Sb")
        check_curpos({ 2, 9 })

        set_lines({
            "this is a line",
            "this is another line",
            "some more random text",
        })
        set_curpos({ 1, 4 })
        vim.cmd("normal! " .. ctrl_v .. "jjww")
        vim.cmd("normal Sx")
        set_curpos({ 8, 8 })

        assert.are.same(get_extmarks(), {})
    end)

    it("can make the cursor 'stick' to the text (delete)", function()
        require("nvim-surround").buffer_setup({
            move_cursor = "sticky",
        })

        set_lines({
            "func_name(foobar)",
        })
        set_curpos({ 1, 14 })
        vim.cmd("normal dsf")
        check_curpos({ 1, 4 })

        set_lines({
            "<div id='foobar'>",
            "    hello",
            "</div>",
        })
        set_curpos({ 2, 7 })
        vim.cmd("normal dst")
        check_curpos({ 2, 7 })

        set_lines({
            "hello 'world'",
        })
        set_curpos({ 1, 2 })
        vim.cmd("normal dsq")
        check_curpos({ 1, 2 })

        set_lines({
            "func(hello) world",
        })
        set_curpos({ 1, 14 })
        vim.cmd("normal dsf")
        check_curpos({ 1, 8 })

        assert.are.same(get_extmarks(), {})
    end)

    it("can make the cursor 'stick' to the text (change)", function()
        require("nvim-surround").buffer_setup({
            move_cursor = "sticky",
        })

        set_lines({
            "func_name(foobar)",
        })
        set_curpos({ 1, 14 })
        vim.cmd("normal csff" .. cr)
        check_curpos({ 1, 6 })

        set_lines({
            "<div id='foobar'>",
            "    hello",
            "</div>",
        })
        set_curpos({ 2, 7 })
        vim.cmd("normal csth1" .. cr)
        check_curpos({ 2, 7 })
        vim.cmd("normal csTbutton" .. cr)
        check_curpos({ 2, 7 })

        set_lines({
            "hello 'world'",
        })
        set_curpos({ 1, 2 })
        vim.cmd("normal csqffoobar" .. cr)
        check_curpos({ 1, 2 })

        set_lines({
            "<div className='container'>hello</div> world",
        })
        set_curpos({ 1, 41 })
        vim.cmd("normal csTb" .. cr)
        check_curpos({ 1, 15 })

        assert.are.same(get_extmarks(), {})
    end)

    it("can partially define surrounds", function()
        require("nvim-surround").buffer_setup({
            surrounds = {
                ["t"] = {
                    delete = "^()().-()()$",
                },
            },
        })

        assert.are_not.same(require("nvim-surround.config").get_opts().surrounds.t.add, false)
        assert.are_not.same(require("nvim-surround.config").get_opts().surrounds.t.find, false)
        assert.are_not.same(require("nvim-surround.config").get_opts().surrounds.t.change, false)
    end)

    it("can disable keymaps", function()
        require("nvim-surround").buffer_setup({
            keymaps = {
                normal = false,
            },
        })

        set_lines({ "Hello, world!" })
        vim.cmd("normal ysiwb")
        check_lines({ "wbHello, world!" })
    end)

    it("can disable aliases", function()
        require("nvim-surround").buffer_setup({
            aliases = {
                s = false,
            },
        })

        set_lines({ "([{<>}])" })
        vim.cmd("normal dss")
        check_lines({ "([{<>}])" })
    end)

    it("can cancel surrounds, without moving the cursor", function()
        require("nvim-surround").buffer_setup({
            move_cursor = false,
        })

        set_lines({ "(some 'text')" })
        set_curpos({ 1, 5 })
        vim.cmd("normal ysiw" .. esc)
        vim.cmd("normal ds" .. esc)
        vim.cmd("normal cs'" .. esc)
        vim.cmd("normal csb" .. esc)
        assert.are.same(get_curpos(), { 1, 5 })
        check_lines({ "(some 'text')" })
    end)

    it("will clamp cursor position if deleting a surround invalidates the old position", function()
        require("nvim-surround").setup({
            move_cursor = false,
            surrounds = {
                ["c"] = {
                    add = function()
                        return { { "```", "" }, { "", "```" } }
                    end,
                    find = "(```[a-zA-Z]*\n)().-(\n```)()",
                    delete = "(```[a-zA-Z]*\n)().-(\n```)()",
                },
            },
        })

        set_lines({ "```lua", "print('foo')", "```" })
        set_curpos({ 3, 1 }) -- If we delete the ```, the cursor position won't be valid
        vim.cmd("normal dsc")
        assert.are.same(get_curpos(), { 1, 1 })
        check_lines({ "print('foo')" })
    end)

    it("will handle number prefixing as if the user used dot-repeat", function()
        require("nvim-surround").setup({ move_cursor = "sticky" })
        set_lines({ "foo bar baz" })
        set_curpos({ 1, 5 })
        vim.cmd("normal 3ysiwb")
        check_lines({ "foo (((bar))) baz" })
        check_curpos({ 1, 8 })
        vim.cmd("normal 2ySSa")
        check_lines({
            "<",
            "<",
            "foo (((bar))) baz",
            ">",
            ">",
        })

        set_lines({ "((foo) bar (baz))" })
        set_curpos({ 1, 9 })
        vim.cmd("normal 2dsb")
        check_lines({ "(foo) bar baz" })
        check_curpos({ 1, 8 })

        set_lines({ "((foo) bar (baz))" })
        set_curpos({ 1, 9 })
        vim.cmd("normal 2csbr")
        check_lines({ "[(foo) bar [baz]]" })
        check_curpos({ 1, 9 })
    end)
end)
