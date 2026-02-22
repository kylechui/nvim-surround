--[====================================================================================================================[
                                                    DEFAULT KEYMAPS
--]====================================================================================================================]
if not vim.g.nvim_surround_disable_default_keymaps then
    vim.keymap.set("i", "<C-g>s", "<Plug>(nvim-surround-insert)", {
        desc = "Add a surrounding pair around the cursor (insert mode)",
    })
    vim.keymap.set("i", "<C-g>S", "<Plug>(nvim-surround-insert-line)", {
        desc = "Add a surrounding pair around the cursor, on new lines (insert mode)",
    })
    vim.keymap.set("n", "ys", "<Plug>(nvim-surround-normal)", {
        desc = "Add a surrounding pair around a motion (normal mode)",
    })
    vim.keymap.set("n", "yss", "<Plug>(nvim-surround-normal-cur)", {
        desc = "Add a surrounding pair around the current line (normal mode)",
    })
    vim.keymap.set("n", "yS", "<Plug>(nvim-surround-normal-line)", {
        desc = "Add a surrounding pair around a motion, on new lines (normal mode)",
    })
    vim.keymap.set("n", "ySS", "<Plug>(nvim-surround-normal-cur-line)", {
        desc = "Add a surrounding pair around the current line, on new lines (normal mode)",
    })
    vim.keymap.set("x", "S", "<Plug>(nvim-surround-visual)", {
        desc = "Add a surrounding pair around a visual selection",
    })
    vim.keymap.set("x", "gS", "<Plug>(nvim-surround-visual-line)", {
        desc = "Add a surrounding pair around a visual selection, on new lines",
    })
    vim.keymap.set("n", "ds", "<Plug>(nvim-surround-delete)", {
        desc = "Delete a surrounding pair",
    })
    vim.keymap.set("n", "cs", "<Plug>(nvim-surround-change)", {
        desc = "Change a surrounding pair",
    })
    vim.keymap.set("n", "cS", "<Plug>(nvim-surround-change-line)", {
        desc = "Change a surrounding pair, putting replacements on new lines",
    })
end

--[====================================================================================================================[
                                                     <PLUG> KEYMAPS
--]====================================================================================================================]
vim.keymap.set("i", "<Plug>(nvim-surround-insert)", function()
    require("nvim-surround").insert_surround({ line_mode = false })
end, {
    desc = "Add a surrounding pair around the cursor (insert mode)",
    silent = true,
})
vim.keymap.set("i", "<Plug>(nvim-surround-insert-line)", function()
    require("nvim-surround").insert_surround({ line_mode = true })
end, {
    desc = "Add a surrounding pair around the cursor, on new lines (insert mode)",
    silent = true,
})
vim.keymap.set("n", "<Plug>(nvim-surround-normal)", function()
    return require("nvim-surround").normal_surround({ line_mode = false })
end, {
    desc = "Add a surrounding pair around a motion (normal mode)",
    expr = true,
    silent = true,
})
vim.keymap.set("n", "<Plug>(nvim-surround-normal-cur)", function()
    return "<Plug>(nvim-surround-normal)Vg_"
end, {
    desc = "Add a surrounding pair around the current line (normal mode)",
    expr = true,
    silent = true,
})
vim.keymap.set("n", "<Plug>(nvim-surround-normal-line)", function()
    return require("nvim-surround").normal_surround({ line_mode = true })
end, {
    desc = "Add a surrounding pair around a motion, on new lines (normal mode)",
    expr = true,
    silent = true,
})
vim.keymap.set("n", "<Plug>(nvim-surround-normal-cur-line)", function()
    return "^" .. tostring(vim.v.count1) .. "<Plug>(nvim-surround-normal-line)g_"
end, {
    desc = "Add a surrounding pair around the current line, on new lines (normal mode)",
    expr = true,
    silent = true,
})
vim.keymap.set("x", "<Plug>(nvim-surround-visual)", function()
    local curpos = require("nvim-surround.buffer").get_curpos()
    return string.format(
        ":lua require'nvim-surround'.visual_surround({ line_mode = false, curpos = { %d, %d }, curswant = %d })<CR>",
        curpos[1],
        curpos[2],
        vim.fn.winsaveview().curswant
    )
end, {
    desc = "Add a surrounding pair around a visual selection",
    silent = true,
    expr = true,
})
vim.keymap.set("x", "<Plug>(nvim-surround-visual-line)", function()
    local curpos = require("nvim-surround.buffer").get_curpos()
    return string.format(
        ":lua require'nvim-surround'.visual_surround({ line_mode = true, curpos = { %d, %d }, curswant = 0 })<CR>",
        curpos[1],
        curpos[2]
    )
end, {
    desc = "Add a surrounding pair around a visual selection, on new lines",
    silent = true,
    expr = true,
})
vim.keymap.set("n", "<Plug>(nvim-surround-delete)", require("nvim-surround").delete_surround, {
    desc = "Delete a surrounding pair",
    expr = true,
    silent = true,
})
vim.keymap.set("n", "<Plug>(nvim-surround-change)", function()
    return require("nvim-surround").change_surround({ line_mode = false })
end, {
    desc = "Change a surrounding pair",
    expr = true,
    silent = true,
})
vim.keymap.set("n", "<Plug>(nvim-surround-change-line)", function()
    return require("nvim-surround").change_surround({ line_mode = true })
end, {
    desc = "Change a surrounding pair, putting replacements on new lines",
    expr = true,
    silent = true,
})
