local uv = vim.uv
local windows_listener = require('mesone.lib.listener.window_listener')
local notification_listener = require('mesone.lib.listener.notification_listener')
local writer_listener = require('mesone.lib.listener.writer_listener')
local quickfix_listener = require('mesone.lib.listener.quickfix_listener')
local utils = require('mesone.lib.utils')

local M = {}

function M:new(opts)
  local o = {
    build_folder = opts.build_folder or vim.uv.cwd(),
    command = opts.command or "meson",
    success_message = opts.success_message or "Done",
    failure_message = opts.failure_message or "Failed",
    log_filename = opts.log_filename or os.tmpname(),
    show_log_window = opts.show_command_logs,
    silent_mode = opts.silent_mode
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:_task(args, on_progress, on_complete)
  local handle;
  local stdin = nil;
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  handle, _ = uv.spawn(self.command, {args = args, stdio = {stdin, stdout, stderr}}, function(status, _)
    ---@diagnostic disable-next-line: param-type-mismatch
    uv.close(handle)
    vim.schedule(function() on_complete(status) end)
  end)

  uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if data then for line in data:gmatch("[^\r\n]+") do vim.schedule(function() on_progress("out", line) end) end end
  end)

  uv.read_start(stderr, function(err, data)
    assert(not err, err)
    if data then for line in data:gmatch("[^\r\n]+") do vim.schedule(function() on_progress("err", line) end) end end
  end)
end

function M:execute(args, action, on_terminate)
  local listeners = {writer_listener:new(self.log_filename), quickfix_listener:new(self.build_folder)}
  if not self.silent_mode then vim.list_extend(listeners, {notification_listener:new(action)}) end
  if self.show_log_window then vim.list_extend(listeners, {windows_listener:new(action)}) end

  local full_command = self.command .. " " .. table.concat(args, " ")
  for _, listener in ipairs(listeners) do listener:update("start", full_command) end

  local on_progress = function(line_type, line)
    if utils.is_failure_message(line) then
      line_type = "err"
    end
    for _, listener in ipairs(listeners) do listener:update(line_type, line) end
  end

  local on_complete = function(status)
    if (status == 0) then
      for _, listener in ipairs(listeners) do listener:success() end
    else
      for _, listener in ipairs(listeners) do listener:failure() end
    end
    on_terminate(status)
  end
  self:_task(args, on_progress, on_complete)
end

return M
