local listener = require('mesone.lib.listener.init')
local utils = require('mesone.lib.utils')
local window = require('mesone.lib.window')

local window_listener = listener:new()

function window_listener:new(action)
    local buf, win = window.centered_window()

    -- press 'q' or 'esc' to close window
    for _, key in ipairs({'q', '<esc>'}) do
        vim.api.nvim_buf_set_keymap(buf, 'n', key, '<cmd>close<cr>', {
            nowait = true,
            noremap = true,
            silent = true
        })
    end

    local o = {action = action, win = win, buf = buf}
    setmetatable(o, self)
    self.__index = self
    self.first_line = true
    return o
end

function window_listener:update(content_type, content)
    if not vim.api.nvim_buf_is_valid(self.buf) and
        not vim.api.nvim_win_is_valid(self.win) then return end
    vim.api.nvim_set_option_value("readonly", false, {buf = self.buf})
    vim.api.nvim_set_option_value("modifiable", true, {buf = self.buf})
    local row = utils.buf_append_colorized(self.buf, content, content_type,
                                           self.first_line)
    self.first_line = false
    vim.api.nvim_win_set_cursor(self.win, {row, 0})
    vim.api.nvim_set_option_value("readonly", true, {buf = self.buf})
    vim.api.nvim_set_option_value("modifiable", false, {buf = self.buf})
end

function window_listener:success()
    if not vim.api.nvim_buf_is_valid(self.buf) and
        not vim.api.nvim_win_is_valid(self.win) then return end
    vim.api.nvim_set_option_value("readonly", false, {buf = self.buf})
    vim.api.nvim_set_option_value("modifiable", true, {buf = self.buf})
    utils.buf_append_colorized(self.buf, "Success!", "end")
    vim.api.nvim_set_option_value("readonly", true, {buf = self.buf})
    vim.api.nvim_set_option_value("modifiable", false, {buf = self.buf})
end

function window_listener:failure()
    if not vim.api.nvim_buf_is_valid(self.buf) and
        not vim.api.nvim_win_is_valid(self.win) then return end
    vim.api.nvim_set_option_value("readonly", false, {buf = self.buf})
    vim.api.nvim_set_option_value("modifiable", true, {buf = self.buf})
    utils.buf_append_colorized(self.buf, "Failure!", "end")
    vim.api.nvim_set_option_value("readonly", true, {buf = self.buf})
    vim.api.nvim_set_option_value("modifiable", false, {buf = self.buf})
end

return window_listener
