local set_lines = function(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local check_lines = function(lines)
  assert.are.same(lines, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

describe("custom surrounds", function()
  before_each(function()
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(0, bufnr)
  end)

  it("deletes surrounding code block", function()
    require("nvim-surround").buffer_setup({
      surrounds = {
        c = {
          add = function()
            return { { '```', '' }, { '', '```' } }
          end,
          find = '(```[a-zA-Z]*\n)().-(\n```)()',
          delete = '(```[a-zA-Z]*\n)().-(\n```)()',
        },
      },
    })

    set_lines({
      [[```lua]],
      [[print('foo')]],
      [[```]],
    })

    -- The out of bounds issue doesn't occur on the first line
    vim.cmd("normal j")
    local success, err = pcall(vim.cmd.normal, "dsc")

    assert(success, err)
    check_lines({ "print('foo')" })
  end)
end)
