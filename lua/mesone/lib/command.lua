local job = require("plenary.job")
local uv = vim.uv
local windows_listener = require("mesone.lib.listener.window_listener")
local notification_listener = require("mesone.lib.listener.notification_listener")
local writer_listener = require("mesone.lib.listener.writer_listener")
local quickfix_listener = require("mesone.lib.listener.quickfix_listener")
local utils = require("mesone.lib.utils")

local M = {}

function M:new(opts)
  local o = {
    build_folder = opts.build_folder or vim.uv.cwd(),
    command = opts.command or "meson",
    success_message = opts.success_message or "Done",
    failure_message = opts.failure_message or "Failed",
    log_filename = opts.log_filename or os.tmpname(),
    show_log_window = opts.show_command_logs,
    silent_mode = opts.silent_mode,
    run_sync = opts.run_sync or false,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:_task(args, on_progress, on_complete)
  local parse_data = function(kind, data)
    if data then
      for line in data:gmatch("[^\r\n]+") do
        vim.schedule(function()
          on_progress(kind, line)
        end)
      end
    end
  end
  local terminating = function(_, status)
    if self.run_sync then
      on_complete(status)
    else
      vim.schedule(function()
        on_complete(status)
      end)
    end
  end
  return job
    ---@diagnostic disable-next-line: missing-fields
    :new({
      command = self.command,
      args = args,
      on_stdout = function(_, data, _)
        parse_data("out", data)
      end,
      on_stderr = function(_, data, _)
        parse_data("err", data)
      end,
      on_exit = function(j, status)
        terminating(j, status)
      end,
    })
end

function M:_build_listeners(action)
  local listeners = { writer_listener:new(self.log_filename), quickfix_listener:new(self.build_folder) }
  if not self.silent_mode then
    vim.list_extend(listeners, { notification_listener:new(action) })
  end
  if self.show_log_window then
    vim.list_extend(listeners, { windows_listener:new(action) })
  end
  return listeners
end

function M:execute(args, action, on_terminate, build_listeners)
  local listeners = {}
  if build_listeners ~= nil then
    listeners = build_listeners(action)
  else
    listeners = self:_build_listeners(action)
  end

  local full_command = self.command .. " " .. table.concat(args, " ")
  for _, listener in ipairs(listeners) do
    listener:update("start", full_command)
  end

  local on_progress = function(line_type, line)
    if utils.is_failure_message(line) then
      line_type = "err"
    end
    for _, listener in ipairs(listeners) do
      listener:update(line_type, line)
    end
  end

  local on_complete = function(status)
    if status == 0 then
      for _, listener in ipairs(listeners) do
        listener:success()
      end
    else
      for _, listener in ipairs(listeners) do
        listener:failure()
      end
    end
    on_terminate(status)
  end
  if self.run_sync then
    self:_task(args, on_progress, on_complete):sync()
  else
    self:_task(args, on_progress, on_complete):start()
  end
end

return M
