local buffer = require("nvim-surround.buffer")
local config = require("nvim-surround.config")
local html = require("nvim-surround.html")
local strings = require("nvim-surround.strings")
local utils = require("nvim-surround.utils")

local M = {}

M.insert_char = nil
M.delete_char = nil
M.change_chars = nil

-- Setup the plugin with user-defined options
M.setup = function(user_opts)
    config.setup(user_opts)
end

-- API: Insert delimiters around a text object
M.insert_surround = function(args)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Save the current mode
        M.mode = vim.fn.mode()
        -- Clear the insert char (since it was user-called)
        M.insert_char = nil

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.insert_callback"
        vim.api.nvim_feedkeys("g@", "n", false)
        return
    end

    -- Define some local variables based on the arguments
    local delimiters = utils.get_delimiters(args.char) or {}
    local first_pos, last_pos = args.selection.first_pos, args.selection.last_pos
    local lines = buffer.get_lines(first_pos[1], last_pos[1])

    -- Insert the right delimiter first to ensure correct indexing
    local line = lines[#lines]
    lines[#lines] = strings.insert_string(line, delimiters[2], last_pos[2] + 1)
    line = lines[1]
    lines[1] = strings.insert_string(line, delimiters[1], first_pos[2])
    -- Update the buffer with the new lines
    buffer.set_lines(first_pos[1], last_pos[1], lines)
end

-- API: Insert delimiters around a visual selection
M.visual_surround = function(ins_char, mode)
    -- Call the operatorfunc if it has not been called yet
    if not ins_char then
        vim.go.operatorfunc = "v:lua.require'nvim-surround'.visual_callback"
        vim.api.nvim_feedkeys("g@", "n", false)
        return
    end

    -- Get the visual selection
    local selection = utils.get_selection(true)
    if not selection then
        return
    end

    -- Define some local variables based on the arguments
    local delimiters = utils.get_delimiters(ins_char) or {}
    local first_pos, last_pos = selection.first_pos, selection.last_pos
    local lines = buffer.get_lines(first_pos[1], last_pos[1])

    if mode == "line" then -- Visual line mode case (need to create new lines)
        -- Insert the delimiters at the first and last line of the selection
        table.insert(lines, 1, delimiters[1])
        table.insert(lines, #lines + 1, delimiters[2])
    else -- Regular visual mode case
        -- Insert the right delimiter first to ensure correct indexing
        local line = lines[#lines]
        lines[#lines] = strings.insert_string(line, delimiters[2], last_pos[2] + 1)
        line = lines[1]
        lines[1] = strings.insert_string(line, delimiters[1], first_pos[2])
    end
    -- Update the buffer with the new lines
    buffer.set_lines(first_pos[1], last_pos[1], lines)
    -- If the selection was in visual line mode, reformat
    if mode == "line" then
        vim.cmd("normal! `<v`>2j=")
    end
end

-- API: Delete a surrounding delimiter pair, if it exists
M.delete_surround = function(del_char)
    -- Call the operatorfunc if it has not been called yet
    if not del_char then
        -- Clear the insert char (since it was user-called)
        M.delete_char = nil

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.delete_callback"
        vim.api.nvim_feedkeys("g@l", "n", false)
        return
    end

    local selections = utils.get_nearest_selections(del_char)
    if not selections then
        return
    end

    -- Delete the right selection first to ensure selection positions are correct
    buffer.delete_selection(selections.right)
    buffer.delete_selection(selections.left)
    -- Set cache
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.delete_callback"
end

-- API: Change a surrounding delimiter pair, if it exists
M.change_surround = function(del_char, ins_char)
    -- Call the operatorfunc if it has not been called yet
    if not del_char or not ins_char then
        -- Clear the insert char (since it was user-called)
        M.change_chars = nil

        vim.go.operatorfunc = "v:lua.require'nvim-surround'.change_callback"
        vim.api.nvim_feedkeys("g@l", "n", false)
        return
    end

    local selections = utils.get_nearest_selections(del_char)

    -- Adjust the selections for changing if we are changing a HTML tag
    if utils.is_HTML(del_char) then
        selections = html.adjust_selections(selections)
    end

    -- Get the new surrounding pair
    local delimiters
    if utils.is_HTML(del_char) then
        delimiters = html.get_tag()
    else
        delimiters = utils.get_delimiters(ins_char)
    end

    if not delimiters or not selections then
        return
    end
    local left_sel = selections.left
    local right_sel = selections.right

    local lines = buffer.get_lines(left_sel.first_pos[1], right_sel.first_pos[1])
    -- Update the delimiting pair
    lines[#lines] = strings.replace_string(lines[#lines], delimiters[2], right_sel.first_pos[2], right_sel.last_pos[2])
    lines[1] = strings.replace_string(lines[1], delimiters[1], left_sel.first_pos[2], left_sel.last_pos[2])
    -- Update the range of lines
    buffer.set_lines(left_sel.first_pos[1], right_sel.first_pos[1], lines)
    -- Set cache
    vim.go.operatorfunc = "v:lua.require'nvim-surround'.change_callback"
end

--[============================================================================[
                               Callback Functions
--]============================================================================]

M.insert_callback = function()
    -- Get a character input and the positions of the selection
    M.insert_char = M.insert_char or utils.get_char()
    if not M.insert_char then
        return
    end
    local selection = utils.get_selection(false)

    local args = {
        char = M.insert_char,
        selection = selection,
    }
    -- Call the main insert function with some arguments
    M.insert_surround(args)
end

M.visual_callback = function(mode)
    -- Get a character input and the positions of the selection
    local char = utils.get_char()
    if not char then
        return
    end

    -- Call the main visual function with some arguments
    M.visual_surround(char, mode)
end

M.delete_callback = function()
    -- Get a character input
    M.delete_char = M.delete_char or utils.get_char()
    if not M.delete_char then
        return
    end
    M.delete_surround(M.delete_char)
end

M.change_callback = function()
    -- Get character inputs
    if not M.change_chars then
        local del_char = utils.get_char()
        if not del_char then
            return
        end

        local ins_char
        if utils.is_HTML(del_char) then
            ins_char = del_char
        else
            ins_char = utils.get_char()
        end
        if not ins_char then
            return
        end
        M.change_chars = { del_char, ins_char }
    end
    M.change_surround(M.change_chars[1], M.change_chars[2])
end

return M
