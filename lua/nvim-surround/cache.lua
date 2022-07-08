local M = {}

-- These variables hold cache values for dot-repeating the three actions

-- Insert only caches the delimiters to be inserted (table for left/right)
M.insert = {}
-- Delete only caches the character to be deleted
M.delete = {}
-- Change caches both the character to be deleted and also the delimiters to be inserted
M.change = {}

return M
