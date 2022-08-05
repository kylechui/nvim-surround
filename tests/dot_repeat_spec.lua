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

describe("dot-repeat", function()
    before_each(function()
        local bufnr = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(0, bufnr)
    end)

    it("can add static delimiter pairs", function()
        set_lines({ "test" })
        vim.cmd("normal ysiWb")
        vim.cmd("normal! ..")
        check_lines({ "(((test)))" })
    end)

    it("can delete static delimiter pairs", function()
        set_lines({ "(((test)))" })
        vim.cmd("normal dsb")
        vim.cmd("normal! ..")
        check_lines({ "test" })
    end)

    it("can change static delimiter pairs", function()
        set_lines({ "(((test)))" })
        vim.cmd("normal csba")
        vim.cmd("normal! ..")
        check_lines({ "<<<test>>>" })
    end)

    it("can add non-static delimiter pairs based on user input", function()
        set_lines({ "here", "are", "some", "lines" })
        vim.cmd("normal ysiwffunc_name" .. cr)
        set_curpos({ 2, 3 })
        vim.cmd("normal! .")
        set_curpos({ 3, 4 })
        vim.cmd("normal! .")
        set_curpos({ 4, 2 })
        vim.cmd("normal! .")
        check_lines({
            "func_name(here)",
            "func_name(are)",
            "func_name(some)",
            "func_name(lines)",
        })
    end)

    it("can delete non-static delimiter pairs", function()
        set_lines({
            [[<div id="test"]],
            [[     class="another"]],
            [[     some="other stuff">]],
            [[    <div id="bruh"]],
            [[         class="hi"]],
            [[         some="more things">]],
            [[        hello]],
            [[        <h2>]],
            [[            hello world]],
            [[        </h2>]],
            [[    </div>]],
            [[</div>]],
        })
        set_curpos({ 9, 5 })
        vim.cmd("normal dsT..")
        check_lines({
            [[]],
            [[    ]],
            [[        hello]],
            [[        ]],
            [[            hello world]],
            [[        ]],
            [[    ]],
            [[]],
        })
    end)

    it("can change non-static delimiter pairs", function()
        set_lines({
            [[<div id="test"]],
            [[     class="another"]],
            [[     some="other stuff">]],
            [[    <div id="bruh"]],
            [[         class="hi"]],
            [[         some="more things">]],
            [[        hello]],
            [[        <h2>]],
            [[            hello world]],
            [[        </h2>]],
            [[    </div>]],
            [[</div>]],
        })
        set_curpos({ 4, 15 })
        vim.cmd("normal csTh1" .. cr)
        check_lines({
            [[<div id="test"]],
            [[     class="another"]],
            [[     some="other stuff">]],
            [[    <h1>]],
            [[        hello]],
            [[        <h2>]],
            [[            hello world]],
            [[        </h2>]],
            [[    </h1>]],
            [[</div>]],
        })
        set_curpos({ 1, 5 })
        vim.cmd("normal! .")
        check_lines({
            [[<h1>]],
            [[    <h1>]],
            [[        hello]],
            [[        <h2>]],
            [[            hello world]],
            [[        </h2>]],
            [[    </h1>]],
            [[</h1>]],
        })
    end)

    it("can replace non-static delimiter pairs based on user input", function()
        set_lines({
            "func_name(here)",
            "func_name(are)",
            "func_name(some)",
            "func_name(lines)",
        })
        vim.cmd("normal csfnew_name" .. cr)
        vim.cmd("normal j.j.j.")
        set_lines({
            "new_name(here)",
            "new_name(are)",
            "new_name(some)",
            "new_name(lines)",
        })
    end)
end)
