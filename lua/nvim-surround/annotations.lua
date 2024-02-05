--[====================================================================================================================[
                                                   Basic Definitions
--]====================================================================================================================]

---@alias text string[] A list of lines of text in the buffer
---@alias position integer[] A 1-indexed position in the buffer
---@alias delimiter string[] The text representation of a delimiter
---@alias delimiter_pair delimiter[] A pair of delimiters
---@alias add_func fun(char: string|nil): delimiter_pair|nil
---@alias find_func fun(char: string|nil): selection|nil
---@alias delete_func fun(char: string|nil): selections|nil
---@alias change_table { target: delete_func, replacement: add_func|nil }

---@class selection
---@field first_pos position
---@field last_pos position

---@class selections
---@field left selection|nil
---@field right selection|nil

---@class offsets
---@field col_offset integer?
---@field row_offset integer?

---@class delimiters_params
---@field pair delimiter_pair
---@field placeholder_offset offsets?

---@alias regions selection[]
---@alias regions_func fun(node: TSNode): regions
---@alias delimiters_params_func fun(): delimiters_params
---@alias filetype_spec table<string, regions_func|delimiters_params_func|boolean>

---@class TS_kinds
---@field fields string[] TS fields names
---@field types string[] TS types names

--[====================================================================================================================[
                                                    Internal Options
--]====================================================================================================================]

-- TODO: Come up with a better name for `change_table`?
---@class surround
---@field add add_func
---@field find find_func
---@field delete delete_func
---@field change change_table

---@class options
---@field keymaps table<string, string>
---@field surrounds table<string, surround>
---@field aliases table<string, string|string[]>
---@field highlight { duration: integer }
---@field move_cursor false|"begin"|"end"
---@field indent_lines function
---@field filetypes_extensions filetype_spec

--[====================================================================================================================[
                                                 User-provided options
--]====================================================================================================================]

---@alias user_add false|string[]|string[][]|add_func
---@alias user_find false|string|find_func
---@alias user_delete false|string|delete_func
---@alias user_change false|{ target: user_delete, replacement: user_add|nil }

---@class user_surround
---@field add user_add
---@field find user_find
---@field delete user_delete
---@field change user_change

---@class user_options
---@field keymaps table<string, false|string>
---@field surrounds table<string, false|string|user_surround>
---@field aliases table<string, false|string|string[]>
---@field highlight { duration: false|integer }
---@field move_cursor false|"begin"|"end"
---@field indent_lines false|function
---@field filetypes_extensions false|filetype_spec
