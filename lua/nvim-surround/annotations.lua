---@alias text string[] A list of lines of text in the buffer
---@alias position integer[] A 1-indexed position in the buffer
---@alias delimiter string[] The text representation of a delimiter
---@alias delimiter_pair delimiter[] A pair of delimiters
---@alias add_func fun(char?: string): delimiter_pair?
---@alias find_func fun(char?: string): selection?
---@alias delete_func fun(char?: string): selections?

---@class selection
---@field first_pos position
---@field last_pos position

---@class selections
---@field left selection?
---@field right selection?

--[====================================================================================================================[
                                                    Internal Options
--]====================================================================================================================]

---@class surround
---@field add add_func
---@field find find_func
---@field delete delete_func
---@field change { target: delete_func, replacement: add_func? }

---@class options
---@field keymaps table<string, false|string>
---@field surrounds table<string, false|surround>
---@field aliases table<string, string|string[]>
---@field highlight { duration: integer }
---@field move_cursor false|string
---@field indent_lines function

--[====================================================================================================================[
                                                 User-provided options
--]====================================================================================================================]

---@class user_surround
---@field add string[]|string[][]|add_func
---@field find string|find_func
---@field delete string|delete_func
---@field change { target: string|delete_func, replacement: string[]|string[][]|add_func? }

---@class user_options
---@field keymaps table<string, false|string>
---@field surrounds table<string, false|user_surround>
---@field aliases table<string, false|string|string[]>
---@field highlight { duration: false|integer }
---@field move_cursor false|string
---@field indent_lines false|function
