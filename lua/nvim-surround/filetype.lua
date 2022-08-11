local config = require("nvim-surround.config")

local M = {}

M.nvim_surround_filetype_setup = vim.api.nvim_create_augroup("NvimSurroundFileTypeSetup", { clear = true })

M.set_autocmd = function(filetype, callback)
    vim.api.nvim_create_autocmd("FileType", {
        pattern = filetype,
        callback = callback,
        group = M.nvim_surround_filetype_setup,
    })
end

M.c = {
    setup = function()
        M.set_autocmd("c", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call_expression" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.cs = {
    setup = function()
        M.set_autocmd("cs", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "invocation_expression" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.cpp = {
    setup = function()
        M.set_autocmd("cpp", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call_expression" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.go = {
    setup = function()
        M.set_autocmd("go", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call_expression" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.java = {
    setup = function()
        M.set_autocmd("java", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "method_invocation" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.javascript = {
    setup = function()
        M.set_autocmd("javascript", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call_expression" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.lua = {
    setup = function()
        M.set_autocmd("lua", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "function_call" })
                        end,
                        delete = "^([^=%s]+%()().-(%))()$",
                    },
                },
            })
        end)
    end,
}

M.python = {
    setup = function()
        M.set_autocmd("python", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.r = {
    setup = function()
        M.set_autocmd("r", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.ruby = {
    setup = function()
        M.set_autocmd("ruby", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.rust = { -- TODO: Try to add support for macros?
    setup = function()
        M.set_autocmd("rust", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call_expression" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.typescriptreact = {
    setup = function()
        M.set_autocmd("typescriptreact", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["t"] = {
                        find = function()
                            return config.get_selection({ node = "jsx_element" })
                        end,
                    },
                    ["T"] = {
                        find = function()
                            return config.get_selection({ node = "jsx_element" })
                        end,
                    },
                },
            })
        end)
    end,
}

M.vim = {
    setup = function()
        M.set_autocmd("vim", function()
            require("nvim-surround").buffer_setup({
                surrounds = {
                    ["f"] = {
                        find = function()
                            return config.get_selection({ node = "call_expression" })
                        end,
                    },
                },
            })
        end)
    end,
}

return M
