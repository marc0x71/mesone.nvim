local signs = require("mesone.lib.signs")

---@diagnostic disable: undefined-field
local eq = assert.are.same

describe("signs", function()
  it("show signs", function()
    local lines = {
      {
        status = "run",
        line = 1,
      },
      {
        status = "unk",
        line = 2,
      },
      {
        status = "fail",
        line = 3,
      },
      {
        status = "skipped",
        line = 4,
      },
    }
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "1", "2", "3", "4" })

    signs.show_sign(buf, lines)

    local marks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })

    local _, row, _, details = unpack(marks[1])
    eq(0, row)
    eq("DiagnosticSignOk", details.sign_hl_group)
    eq("✓ ", details.sign_text)
    eq("   run", details.virt_text[1][1])
    eq("DiagnosticSignOk", details.virt_text[1][2])

    local _, row, _, details = unpack(marks[2])
    eq(2, row)
    eq("DiagnosticSignError", details.sign_hl_group)
    eq("✗ ", details.sign_text)
    eq("   fail", details.virt_text[1][1])
    eq("DiagnosticSignError", details.virt_text[1][2])

    local _, row, _, details = unpack(marks[3])
    eq(3, row)
    eq("DiagnosticSignInfo", details.sign_hl_group)
    eq("⚐ ", details.sign_text)
    eq("   skipped", details.virt_text[1][1])
    eq("DiagnosticSignInfo", details.virt_text[1][2])
  end)
end)
