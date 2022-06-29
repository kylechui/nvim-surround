local buffer = require("nvim-surround.buffer")
local config = require("nvim-surround.config")
local html = require("nvim-surround.html")
local strings = require("nvim-surround.strings")
local utils = require("nvim-surround.utils")

local M = {}

M.delete_char = nil
M.mode = nil

-- Setup the plugin with user-defined options
M.setup = function(user_opts)
    config.setup(user_opts)
end

-- API: Insert delimiters around the given selection
M.insert_surround = function(args)
    -- Call the operatorfunc if it has not been called yet
    if not args then
        -- Save the current mode
        M.mode = vim.fn.mode()
        vim.go.operatorfunc = "v:lua.require'nvim-surround'.insert_callback"
        vim.api.nvim_feedkeys("g@", "n", false)
        return
    end

    -- Define some local variables based on the arguments
    local delimiters = utils.get_delimiters(args.char) or {}
    local first_pos, last_pos = args.selection.first_pos, args.selection.last_pos
    local lines = buffer.get_lines(first_pos[1], last_pos[1])

    if M.mode == "V" then -- Visual line mode case (need to create new lines)
        -- Indent the inner lines
        lines = strings.indent_lines(lines)
        -- Insert the delimiters at the first and last line of the selection
        table.insert(lines, 1, delimiters[1])
        table.insert(lines, #lines + 1, delimiters[2])
    else -- Default case for normal mode and visual mode
        -- Insert the right delimiter first to ensure correct indexing
        local line = lines[#lines]
        lines[#lines] = strings.insert_string(line, delimiters[2], last_pos[2] + 1)
        line = lines[1]
        lines[1] = strings.insert_string(line, delimiters[1], first_pos[2])
    end
    -- Update the buffer with the new lines
    buffer.set_lines(first_pos[1], last_pos[1], lines)
end

-- API: Delete a surrounding delimiter pair, if it exists
M.delete_surround = function()
    local char = utils.get_char()
    local selections = utils.get_nearest_selections(char)
    if not selections then
        return
    end

    local left_sel = selections.left
    local right_sel = selections.right

    local lines = buffer.get_lines(left_sel.first_pos[1], right_sel.first_pos[1])
    -- Remove the delimiting pair
    lines[#lines] = strings.delete_string(lines[#lines], right_sel.first_pos[2], right_sel.last_pos[2])
    lines[1] = strings.delete_string(lines[1], left_sel.first_pos[2], left_sel.last_pos[2])
    -- Update the range of lines
    buffer.set_lines(left_sel.first_pos[1], right_sel.first_pos[1], lines)
end

-- API: Change a surrounding delimiter pair, if it exists
M.change_surround = function()
    local char = utils.get_char()
    local selections = utils.get_nearest_selections(char)

    -- Adjust the selections for changing if we are changing a HTML tag
    if utils.is_HTML(char) then
        selections = utils.adjust_HTML_selections(selections)
    end

    -- Get the new surrounding pair
    local delimiters
    if utils.is_HTML(char) then
        delimiters = html.get_tag()
    else
        char = utils.get_char()
        delimiters = utils.get_delimiters(char)
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
end

--[============================================================================[
                               Callback Functions
--]============================================================================]
M.insert_callback = function()
    -- Get a character input and the positions of the selection
    local char = utils.get_char()
    if not char then
        return
    end
    local selection = utils.get_selection(M.mode)

    local args = {
        char = char,
        selection = selection,
    }
    -- Call the main insert function with some arguments
    M.insert_surround(args)
end

return M
