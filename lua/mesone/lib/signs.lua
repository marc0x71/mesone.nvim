local icons = require("mesone.ui.icons")

local M = {}

local mesone_ns = vim.api.nvim_create_namespace("MesoneNs")

M.show_sign = function(bufnr, lines)
  vim.api.nvim_buf_clear_namespace(bufnr, mesone_ns, 0, -1)

  for _, line in ipairs(lines) do
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line.line > line_count then
      goto continue
    end

    local hl = ""
    local sign = icons.status_icon(line.status)
    if line.status == "run" then
      hl = "DiagnosticSignOk"
    elseif line.status == "fail" then
      hl = "DiagnosticSignError"
    elseif line.status == "skipped" then
      hl = "DiagnosticSignInfo"
    end

    if hl ~= "" then
      vim.api.nvim_buf_set_extmark(bufnr, mesone_ns, line.line - 1, 0, {
        virt_text_pos = "eol",
        virt_text = { { "   " .. line.status, hl } },
        sign_text = sign,
        sign_hl_group = hl,
      })
    end

    ::continue::
  end
end

return M
