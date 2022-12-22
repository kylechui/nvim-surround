---@class Selection
---@field first_pos integer[]
---@field last_pos integer[]

---@class Selections
---@field left Selection?
---@field right Selection?

---@class Surround
---@field add string[]|string[][]|function
---@field find string|function
---@field delete string|function
---@field change { target: string|function, replacement: string[]|string[][]|function? }

---@class Options
---@field keymaps table<string, false|string>
---@field surrounds table<string, false|Surround>
---@field aliases table<string, false|string|string[]>
---@field highlight { duration: false|integer }
---@field move_cursor false|string
---@field indent_lines false|function
