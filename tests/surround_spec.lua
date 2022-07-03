local cursor = vim.fn.cursor
local insert_surround = function(textobj, ins_char)
    if textobj then
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys("ys" .. esc, "x", false)
        vim.api.nvim_feedkeys("g@" .. textobj .. ins_char, "x", false)
    else
        require("nvim-surround").insert_surround()
        vim.api.nvim_feedkeys(ins_char, "x", false)
    end
end

local delete_surround = function(del_char)
    require("nvim-surround").delete_surround()
    vim.api.nvim_feedkeys(del_char, "x", false)
end

local change_surround = function(del_char, ins_char)
    require("nvim-surround").change_surround()
    vim.api.nvim_feedkeys(del_char .. ins_char, "x", false)
end

local set_lines = function(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local check_lines = function(lines)
    assert.are.same(lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

describe("nvim-surround", function()
    before_each(function()
        -- Setup default keybinds (can be overwritten with subsequent calls)
        require("nvim-surround").setup({})
    end)

    it("can be setup without a table", function()
        require("nvim-surround").setup()
    end)

    it("can surround text-objects", function()
        set_lines({ "local str = test" })
        cursor({ 1, 13 })
        insert_surround("iw", "\"")
        check_lines({ "local str = \"test\"" })
        insert_surround("a\"", "b")
        check_lines({ "local str = (\"test\")" })
    end)

    it("can delete surrounding quotes/parens", function()
        set_lines({ "local str = (\"test\")" })
        cursor({ 1, 13 })
        delete_surround("b")
        check_lines({ "local str = \"test\"" })
        delete_surround("\"")
        check_lines({ "local str = test" })
    end)

    it("can change surrounding delimiters", function()
        set_lines({
            "require'nvim-surround'.setup(",
            "",
            ")",
        })
        cursor({ 1, 8 })
        insert_surround("a'", "b")
        cursor({ 1, 9 })
        change_surround("'", '"')
        cursor({ 2, 1 })
        change_surround("b", "B")
        insert_surround("aB", "b")
        check_lines({
            "require(\"nvim-surround\").setup({",
            "",
            "})",
        })
    end)

    it("can delete quotes using aliases", function()
        set_lines({ "local str = \"test\"" })
        cursor({ 1, 13 })
        delete_surround("q")

        check_lines({ "local str = test" })
    end)

    it("can modify surrounds that appear at 1, 1", function()
        set_lines({ "({", "some text", "})" })
        delete_surround("b")
        change_surround("B", "b")
        check_lines({ "(", "some text", ")" })
    end)

    it("can dot-repeat insertions", function()
        set_lines({ "test" })
        insert_surround("iW", "b")
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

    it("can dot-repeat deletions (aliased)", function()
        set_lines({ "local str = \"This is 'a sentence `with a lot of` nested strings' in it\"" })
        cursor({ 1, 43 })
        change_surround("q", "r")
        vim.cmd("normal! ..")
        set_lines({ "local str = [This is [a sentence [with a lot of] nested strings] in it]" })
    end)

    it("can do the demonstration", function()
        set_lines({
            "# This is a demonstration for nvim-surround",
            "",
            "Some cool things you can do with this plugin:",
            "",
            "<ul id=\"This is an ordered list\">",
            "<div>This is an item in the list</div>",
            "</ul>",
            "",
            "```lua",
            "require'nvim-surround'.setup{",
            "aliases = {",
            "'b' = { 'q' },",
            "},",
            "}",
            "```",
        })
        cursor({ 1, 31 })
        insert_surround("iW", "'")
        change_surround("q", "`")
        cursor({ 3, 6 })
        vim.cmd("normal! ve")
        insert_surround(nil, "*")
        cursor({ 10, 9 })
        insert_surround("a'", "b")
        cursor({ 10, 11 })
        change_surround("'", "\"")
        cursor({ 11, 1 })
        insert_surround("aB", "b")
        cursor({ 12, 2 })
        delete_surround("'")
        cursor({ 12, 7 })
        change_surround("'", "\"")
        check_lines({
            "# This is a demonstration for `nvim-surround`",
            "",
            "Some *cool* things you can do with this plugin:",
            "",
            "<ul id=\"This is an ordered list\">",
            "<div>This is an item in the list</div>",
            "</ul>",
            "",
            "```lua",
            "require(\"nvim-surround\").setup({",
            "aliases = {",
            "b = { \"q\" },",
            "},",
            "})",
            "```",
        })
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
