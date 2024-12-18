local utils = require("mesone.lib.utils")
local ntf = require("mesone.lib.notification")
local window = require("mesone.ui.window")

local form_ns = vim.api.nvim_create_namespace("FormNs")
local M = {}

function M:new(opts)
  local o = { buf = nil, win = nil, opts = opts, closing = false, callback = nil, validator = nil, values = nil }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:_close()
  if self.closing then return end
  self.closing = true

  if self.buf ~= nil and vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_delete(self.buf, { force = true })
  end
  if self.win ~= nil and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win,
      true)
  end

  self.win = nil
  self.buf = nil
  self.closing = false
end

local function _eval(value)
  if value == nil then
    return nil
  elseif value == "" then
    return ""
  elseif value == "false" then
    return false
  elseif value == "true" then
    return true
  end
  local number = tonumber(value)
  if not number then
    return value
  end
  return number
end

function M:_parse_buffer()
  local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, true)
  local current_key = nil
  local result = {}
  local error = false
  for lineno, line in ipairs(lines) do
    local ms = vim.api.nvim_buf_get_extmarks(0, form_ns, { lineno - 1, 0 }, { lineno - 1, 0 }, {})
    if vim.tbl_isempty(ms) then
      if current_key ~= nil then
        result[current_key] = _eval(line)
        current_key = nil
      else
        ntf.notify("Unexpected value [" .. line .. "]", vim.log.levels.ERROR)
        error = true
      end
    else
      local key = line:match("(.+):.*")
      if self.opts.fields[key] ~= nil then
        current_key = key
      else
        ntf.notify("Unexpected field [" .. line .. "]", vim.log.levels.ERROR)
        error = true
      end
    end
  end
  for key, _ in pairs(self.opts.fields) do
    if result[key] == nil then
      ntf.notify("Missing field [" .. key .. "]", vim.log.levels.ERROR)
      error = true
    else
      local available = self.opts.fields[key]
      if vim.tbl_count(available) > 0 then
        if not vim.list_contains(available, result[key]) then
          local expected = table.concat(available, ",")
          ntf.notify("Invalid field [" .. key .. "] expected value [" .. expected .. "]", vim.log.levels.ERROR)
        end
      end
    end
  end
  if error then
    return nil
  end
  return result
end

function M:_save()
  if self.closing then return false end
  self.closing = true

  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then return false end

  local new_values = self:_parse_buffer()

  self.closing = false

  if new_values ~= nil and self.callback ~= nil then
    self.callback(new_values)
  end

  return new_values ~= nil
end

function M:_update_buffer()
  local content = {}
  for _, key in pairs(utils.orderedPairs(self.opts.fields)) do
    local label = key .. ":"
    if not vim.tbl_isempty(self.opts.fields[key]) then
      local tbl = vim.tbl_map(function(x) return tostring(x) end, self.opts.fields[key])
      local expected = table.concat(tbl, ",")
      label = label .. " (" .. tostring(expected) .. ")"
    end
    table.insert(content, label)
    table.insert(content, tostring(self.values[key]))
  end

  vim.api.nvim_buf_set_lines(self.buf, 0, #content, false, content)

  for line = 0, #vim.tbl_keys(self.opts.fields) * 2, 2 do
    vim.api.nvim_buf_set_extmark(self.buf, form_ns, line, 0,
      {
        line_hl_group = "Title",
        hl_eol = true
      })
  end
end

function M:show(title, values, callback)
  self.values = values
  self.buf, self.win = window.popup(title, 70, 20)
  vim.api.nvim_buf_set_name(self.buf, "mesone-settings-ui")
  vim.api.nvim_set_option_value("filetype",  "mesone-form", { buf = self.buf })
  vim.api.nvim_set_option_value("buftype",   "acwrite",     { buf = self.buf })
  vim.api.nvim_set_option_value("bufhidden", "delete",      { buf = self.buf })

  vim.keymap.set("n", "q", function() self:_close() end, { buffer = self.buf, silent = true })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = self.buf,
    callback = function()
      if self:_save() then
        vim.schedule(function() self:_close() end)
      end
    end
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = self.buf,
    callback = function() vim.schedule(function() self:_close() end) end
  })
  vim.keymap.set("i", "<CR>", "<Nop>", { noremap = true, silent = true })

  vim.cmd(string.format("autocmd BufModifiedSet <buffer=%s> set nomodified", M.config_buf))
  self:_update_buffer()

  self.callback = callback
end

return M
