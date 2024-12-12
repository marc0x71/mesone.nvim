local listener = require('mesone.lib.listener.init')

local quickfix_listener = listener:new()

function quickfix_listener:new(build_folder)
    vim.fn.setqflist({}, 'r', {title = "Meson errors", items = {}})
    local o = {items = {}, cwd = build_folder}
    setmetatable(o, self)
    self.__index = self
    return o
end

function quickfix_listener:update(line_type, content)
    local rule = "([^:]+):(%d+):.*:(.*)"
    if line_type == 'err' then
        local filename, row, error = content:match(rule)
        if filename ~= nil then
            table.insert(self.items, {
                filename = vim.fs.normalize(self.cwd .. "/" .. filename),
                lnum = row,
                type = "E",
                text = error
            })
        end
    end
end

function quickfix_listener:success() end

function quickfix_listener:failure()
    vim.fn.setqflist({}, 'r', {title = "Meson errors", items = self.items})
end

return quickfix_listener
