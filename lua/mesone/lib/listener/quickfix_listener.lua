local listener = require('mesone.lib.listener.init')

local quickfix_listener = listener:new()

function quickfix_listener:new()
  vim.fn.setqflist({}, 'r', {title = "Meson errors", items = {}})
  local o = {items = {}, cwd = vim.uv.cwd()}
  setmetatable(o, self)
  self.__index = self
  return o
end

function quickfix_listener:update(line_type, content)
  local rule = "([^:]+):(%d+):.*:(.*)"
  if line_type == 'err' then
    local filename, row, error = content:match(rule)
    if filename ~= nil and vim.startswith(filename, self.cwd) then
      table.insert(self.items, {filename = filename, lnum = row, type = "E", text = error})
    end
  end
end

function quickfix_listener:success() end

function quickfix_listener:failure() vim.fn.setqflist({}, 'r', {title = "Meson errors", items = self.items}) end

return quickfix_listener
