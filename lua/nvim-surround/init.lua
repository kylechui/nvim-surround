local utils = require("nvim-surround.utils")

local M = {}

M._mode = nil

M.setup = function(opts)
    -- TODO: Implement setup function for user configuration
end

-- API: Insert delimiters around the given selection
M.insert_surround = function(char, positions)
    if not positions then
        vim.go.operatorfunc = "v:lua.require'nvim-surround.callbacks'._insert"
        M._mode = vim.api.nvim_get_mode()["mode"]
        vim.api.nvim_feedkeys("g@", "n", false)
        return
    end
    -- If there is no valid key input, then we cancel the operation
    if not char then
        return nil
    end

    -- Get the associated delimiter pair to the user input
    local delimiters = utils._aliases[char] or { char, char }

    local lines = utils._get_lines(positions[1], positions[3])
    if M._mode == "V" then -- Visual line mode case (create new lines)
        -- Get the user-preferred tab character(s) to indent the lines
        local tab
        if vim.o.expandtab then
            tab = string.rep(" ", vim.o.softtabstop)
        else
            tab = vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
        end
        -- Indent the lines by the tab character(s)
        for key, line in ipairs(lines) do
            lines[key] = tab .. line
        end
        -- Insert the delimiters at the first and last line of the selection
        table.insert(lines, 1, delimiters[1])
        table.insert(lines, #lines + 1, delimiters[2])
    else -- Default case for normal mode and visual mode
        -- Insert the right delimiter first to ensure correct indexing
        local line = lines[#lines]
        lines[#lines] = utils.insert_string(line, delimiters[2], positions[4] + 1)
        line = lines[1]
        lines[1] = utils.insert_string(line, delimiters[1], positions[2])
    end
    -- Update the buffer with the new lines
    utils._set_lines(positions[1], positions[3], lines)
end

-- API: Delete a surrounding delimiter pair, if it exists
M.delete_surround = function(positions)
    if not positions then
        -- Get a character input
        local char = utils._get_char()
        if not char then
            return nil
        end
        if not utils._is_valid_alias(char) then
            print("Invalid surrounding pair to delete!")
            return
        end
        vim.go.operatorfunc = "v:lua.require'nvim-surround.callbacks'._delete"
        vim.api.nvim_feedkeys("g@a" .. char, "n", false)
        return
    end

    -- print(vim.inspect(positions))
    local lines = utils._get_lines(positions[1], positions[3])
    -- Adjust the positions if they're on whitespace
    if lines[1]:sub(positions[2], positions[2]) == " " then
        positions[2] = positions[2] + 1
    end
    if lines[#lines]:sub(positions[4], positions[4]) == " " then
        positions[4] = positions[4] - 1
    end
    -- Remove the delimiting pair
    local to_delete = { "G", "G" } -- TODO: Make this work with multichar delimiters
    lines[#lines] = utils.delete_string(lines[#lines], to_delete[2], positions[4])
    lines[1] = utils.delete_string(lines[1], to_delete[1], positions[2])
    -- Update the range of lines
    utils._set_lines(positions[1], positions[3], lines)
end

-- API: Delete a surrounding delimiter pair, if it exists
M.change_surround = function(positions)
    if not positions then
        -- Get a character input
        local char = utils._get_char()
        if not char then
            return nil
        end
        if not utils._is_valid_alias(char) then
            print("Invalid surrounding pair to change!")
            return
        end
        vim.go.operatorfunc = "v:lua.require'nvim-surround.callbacks'._change"
        vim.api.nvim_feedkeys("g@a" .. char, "n", false)
        return
    end

    local lines = utils._get_lines(positions[1], positions[3])
    -- Replace the delimiting pair
    local to_replace = { "G", "G" } -- TODO: Make this work with multichar delimiters
    local to_insert = utils._get_delimiters()
    if to_insert == nil then
        return
    end
    lines[#lines] = utils.change_string(lines[#lines], to_insert[2], to_replace[2], positions[4])
    lines[1] = utils.change_string(lines[1], to_insert[1], to_replace[1], positions[2])
    -- Update the range of lines
    utils._set_lines(positions[1], positions[3], lines)
end

return M
