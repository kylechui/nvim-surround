local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
local cursor = vim.fn.cursor
local config = require("nvim-surround.config")

local get_curpos = function()
    local curpos = vim.api.nvim_win_get_cursor(0)
    return { curpos[1], curpos[2] + 1 }
end

local normal_surround = function(textobj, ins_char)
    vim.cmd("normal ys" .. textobj .. ins_char)
end

local visual_surround = function(ins_char)
    vim.cmd("normal S" .. ins_char)
end

local delete_surround = function(del_char)
    vim.cmd("normal ds" .. del_char)
end

local change_surround = function(del_char, ins_char)
    vim.cmd("normal cs" .. del_char .. ins_char)
end

local set_lines = function(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local check_lines = function(lines)
    assert.are.same(lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

describe("nvim-surround", function()
    before_each(function()
        cursor({ 1, 1 })
        vim.bo.filetype = "lua"
        vim.bo.shiftwidth = 4
        -- Setup defaults
        require("nvim-surround").buffer_setup(require("nvim-surround.config").default_opts)
    end)

    it("can be setup without a table", function()
        require("nvim-surround").setup()
    end)

    it("can surround text-objects", function()
        set_lines({ "local str = test" })
        cursor({ 1, 13 })
        normal_surround("iw", '"')
        check_lines({ 'local str = "test"' })
        normal_surround('a"', "b")
        check_lines({ 'local str = ("test")' })
    end)

    it("can delete surrounding quotes/parens", function()
        set_lines({ 'local str = ("test")' })
        cursor({ 1, 13 })
        delete_surround("b")
        check_lines({ 'local str = "test"' })
        delete_surround('"')
        check_lines({ "local str = test" })
    end)

    it("can change surrounding delimiters", function()
        set_lines({
            "require'nvim-surround'.setup(",
            "",
            ")",
        })
        cursor({ 1, 8 })
        normal_surround("a'", "b")
        cursor({ 1, 9 })
        change_surround("'", '"')
        cursor({ 2, 1 })
        change_surround("b", "B")
        normal_surround("aB", "b")
        check_lines({
            'require("nvim-surround").setup({',
            "",
            "})",
        })
    end)

    it("can delete quotes using aliases", function()
        set_lines({ 'local str = "test"' })
        cursor({ 1, 13 })
        delete_surround("q")

        check_lines({ "local str = test" })
    end)

    it("can modify surrounds that appear at 1, 1", function()
        set_lines({ "({", "some text", "})" })
        delete_surround("b")
        change_surround("B", "b")
        check_lines({ "(", "    some text", ")" })
    end)

    it("can dot-repeat normal additions", function()
        set_lines({ "test" })
        normal_surround("iW", "b")
        vim.cmd("normal! ..")
        check_lines({ "(((test)))" })
    end)

    it("can dot-repeat deletions", function()
        set_lines({ "(((test)))" })
        delete_surround("b")
        vim.cmd("normal! .")
        check_lines({ "(test)" })
        vim.cmd("normal! .")
        check_lines({ "test" })
    end)

    it("can dot-repeat changes", function()
        set_lines({ "(((test)))" })
        cursor({ 1, 4 })
        change_surround("b", "r")
        vim.cmd("normal! .")
        check_lines({ "([[test]])" })
        vim.cmd("normal! .")
        check_lines({ "[[[test]]]" })
    end)

    it("can dot-repeat deletions (aliased)", function()
        set_lines({ "local str = \"This is 'a sentence `with a lot of` nested strings' in it\"" })
        cursor({ 1, 43 })
        delete_surround("q")
        vim.cmd("normal! ..")
        set_lines({ "local str = This is a sentence with a lot of nested strings in it" })
    end)

    it("can dot-repeat changes (aliased)", function()
        set_lines({ "local str = \"This is 'a sentence `with a lot of` nested strings' in it\"" })
        cursor({ 1, 43 })
        change_surround("q", "r")
        vim.cmd("normal! ..")
        set_lines({ "local str = [This is [a sentence [with a lot of] nested strings] in it]" })
    end)

    it("can do the demonstration", function()
        vim.bo.filetype = "markdown"
        vim.bo.shiftwidth = 4
        set_lines({
            "# This is a demonstration for nvim-surround",
            "",
            "Some cool things you can do with this plugin:",
            "",
            '<ul id="This is an ordered list">',
            "<div>This is an item in the list</div>",
            "</ul>",
            "",
            "```lua",
            "require'nvim-surround'.setup{",
            "    aliases = {",
            "        'b' = { 'q' },",
            "    },",
            "}",
            "```",
        })
        cursor({ 1, 31 })
        normal_surround("iW", "'")
        change_surround("q", "`")
        cursor({ 3, 6 })
        vim.cmd("normal! ve")
        visual_surround("'")
        cursor({ 10, 9 })
        normal_surround("a'", "b")
        cursor({ 10, 11 })
        change_surround("'", '"')
        cursor({ 11, 1 })
        normal_surround("aB", "b")
        cursor({ 12, 2 })
        delete_surround("'")
        cursor({ 12, 7 })
        change_surround("'", '"')
        check_lines({
            "# This is a demonstration for `nvim-surround`",
            "",
            "Some 'cool' things you can do with this plugin:",
            "",
            '<ul id="This is an ordered list">',
            "<div>This is an item in the list</div>",
            "</ul>",
            "",
            "```lua",
            'require("nvim-surround").setup({',
            "    aliases = {",
            '        b = { "q" },',
            "    },",
            "})",
            "```",
        })
    end)

    it("can visual-line surround", function()
        set_lines({
            "'hello',",
            "'hello',",
            "'hello',",
        })
        vim.cmd("normal! V")
        visual_surround("B")
        check_lines({
            "{",
            "    'hello',",
            "}",
            "'hello',",
            "'hello',",
        })
        cursor({ 5, 1 })
        vim.cmd("normal! V")
        visual_surround("B")
        check_lines({
            "{",
            "    'hello',",
            "}",
            "'hello',",
            "{",
            "    'hello',",
            "}",
        })
        vim.cmd("normal! ggVG")
        visual_surround("b")
        check_lines({
            "(",
            "{",
            "    'hello',",
            "}",
            "'hello',",
            "{",
            "    'hello',",
            "}",
            ")",
        })
    end)

    it("can deal with different whitespace characters", function()
        set_lines({
            "local str1 = 	'some text'",
            "local str2 = 		    	`some text`",
        })
        change_surround("q", "b")
        cursor({ 2, 1 })
        change_surround("q", "B")
        check_lines({
            "local str1 = 	(some text)",
            "local str2 = 		    	{some text}",
        })
    end)

    it("can add user-inputted delimiters", function()
        set_lines({ "some text" })
        cursor({ 1, 3 })
        vim.cmd("normal! vwl")
        visual_surround("i" .. "|left|" .. cr .. "|right|" .. cr)
        check_lines({ "so|left|me te|right|xt" })
        cursor({ 1, 9 })
        normal_surround("iw", "f" .. "func_name" .. cr)
        check_lines({ "so|left|func_name(me) te|right|xt" })
    end)

    for _, tag in ipairs({ "div", "<div>", "<div" }) do
        it("can surround with an HTML tag " .. tag, function()
            set_lines({ "some text" })
            cursor({ 1, 3 })
            normal_surround("s", "t" .. tag .. cr)
            check_lines({ "<div>some text</div>" })
        end)
    end

    for _, tag in ipairs({ 'div class="test"', '<div class="test"', '<div class="test">' }) do
        it("can surround with an HTML tag with attributes " .. tag, function()
            set_lines({ "some text" })
            cursor({ 1, 3 })
            normal_surround("s", "t" .. tag .. cr)
            check_lines({ '<div class="test">some text</div>' })
        end)
    end

    it("can dot-repeat user-inputted delimiters", function()
        set_lines({ "here", "are", "some", "lines" })
        normal_surround("iw", "f" .. "func_name" .. cr)
        cursor({ 2, 3 })
        vim.cmd("normal! .")
        cursor({ 3, 4 })
        vim.cmd("normal! .")
        cursor({ 4, 2 })
        vim.cmd("normal! .")
        check_lines({
            "func_name(here)",
            "func_name(are)",
            "func_name(some)",
            "func_name(lines)",
        })
    end)

    it("can jump to the deletion properly", function()
        set_lines({
            "local str = 'some text'",
            "-- Some comment string",
            "local tab = { 'a', 'table' }",
        })
        cursor({ 2, 1 })
        delete_surround("'")
        check_lines({
            "local str = 'some text'",
            "-- Some comment string",
            "local tab = { 'a', 'table' }",
        })
        cursor({ 3, 5 })
        delete_surround("'")
        check_lines({
            "local str = 'some text'",
            "-- Some comment string",
            "local tab = { a, 'table' }",
        })
        cursor({ 3, 26 })
        delete_surround("'")
        check_lines({
            "local str = 'some text'",
            "-- Some comment string",
            "local tab = { a, table }",
        })
        set_lines({ [[local str = "this has 'nested' strings"]] })
        cursor({ 1, 12 })
        delete_surround("q")
        check_lines({ "local str = this has 'nested' strings" })

        set_lines({ [[local str = "this has 'nested' strings"]] })
        cursor({ 1, 22 })
        delete_surround("q")
        check_lines({ "local str = this has 'nested' strings" })

        set_lines({ [[local str = "this has 'nested' strings"]] })
        cursor({ 1, 23 })
        delete_surround("q")
        check_lines({ [[local str = "this has nested strings"]] })

        set_lines({ [[local str = "this has 'nested' strings"]] })
        cursor({ 1, 31 })
        delete_surround("q")
        check_lines({ "local str = this has 'nested' strings" })

        set_lines({ [[local str = "this has 'nested' strings" -- Some comment]] })
        cursor({ 1, 44 })
        delete_surround("q")
        check_lines({ "local str = this has 'nested' strings -- Some comment" })
    end)

    it("can dot-repeat jumps properly", function()
        set_lines({
            [[And jump "forwards" and `backwards` to 'the' "nearest" surround.]],
        })
        cursor({ 1, 27 })
        delete_surround("q")
        check_lines({
            [[And jump "forwards" and backwards to 'the' "nearest" surround.]],
        })
        vim.cmd("normal! .")
        check_lines({
            [[And jump "forwards" and backwards to the "nearest" surround.]],
        })
        vim.cmd("normal! .")
        check_lines({
            [[And jump "forwards" and backwards to the nearest surround.]],
        })
        vim.cmd("normal! .")
        check_lines({
            [[And jump forwards and backwards to the nearest surround.]],
        })
    end)

    it("can refuse to jump properly", function()
        require("nvim-surround").buffer_setup({ move_cursor = false })
        set_lines({
            [[And jump "forwards" and `backwards` to 'the' "nearest" surround.]],
        })
        cursor({ 1, 27 })

        delete_surround("q")
        assert.are.same(get_curpos(), { 1, 27 })
        check_lines({
            [[And jump "forwards" and backwards to 'the' "nearest" surround.]],
        })

        normal_surround("a'", '"')
        check_lines({
            [[And jump "forwards" and backwards to "'the'" "nearest" surround.]],
        })

        delete_surround("q")
        vim.cmd("normal! ..")
        assert.are.same(get_curpos(), { 1, 27 })
        check_lines({
            [[And jump "forwards" and backwards to the nearest surround.]],
        })

        change_surround("q", "b")
        assert.are.same(get_curpos(), { 1, 27 })
        check_lines({
            [[And jump (forwards) and backwards to the nearest surround.]],
        })
    end)

    it("can handle quotes smartly", function()
        set_lines({ "'quote 1', 'quote 2', 'quote 3'" })
        cursor({ 1, 9 })
        delete_surround("'")
        check_lines({ "quote 1, 'quote 2', 'quote 3'" })

        set_lines({ "'quote 1', 'quote 2', 'quote 3'" })
        cursor({ 1, 10 })
        delete_surround("'")
        check_lines({ "'quote 1', quote 2, 'quote 3'" })

        set_lines({ "'quote 1', 'quote 2', 'quote 3'" })
        cursor({ 1, 21 })
        delete_surround("'")
        check_lines({ "'quote 1', 'quote 2', quote 3" })

        set_lines({ [["'quote 1', 'quote 2', 'quote 3'"]] })
        cursor({ 1, 10 })
        delete_surround("q")
        check_lines({ [["quote 1, 'quote 2', 'quote 3'"]] })

        set_lines({ [["'quote 1', 'quote 2', 'quote 3'"]] })
        cursor({ 1, 11 })
        delete_surround("q")
        check_lines({ [['quote 1', 'quote 2', 'quote 3']] })
    end)

    it("can delete close/empty pairs", function()
        set_lines({ "{}''()" })
        delete_surround("s")
        vim.cmd("normal! ..")
        check_lines({ "" })

        set_lines({ "({", "})" })
        delete_surround("B")
        delete_surround("b")
        check_lines({ "", "" })
    end)

    it("can disable default delimiters", function()
        require("nvim-surround").setup({
            delimiters = {
                HTML = {
                    ["t"] = false,
                },
            },
        })

        assert.are.same(false, config.user_opts.delimiters.HTML.t)
    end)

    it("can modify aliases", function()
        require("nvim-surround").setup({
            delimiters = {
                pairs = {
                    ["b"] = false,
                },
                aliases = {
                    ["b"] = { ")", "}" },
                },
            },
        })

        assert.are.same(false, config.user_opts.delimiters.pairs.b)
        assert.are.same({ ")", "}" }, config.user_opts.delimiters.aliases.b)
    end)
end)
