local listener = require("mesone.lib.listener.init")
local ntf = require("mesone.lib.notification")

local notification_listener = listener:new()

local function _extract_percentage(str)
  local current, total = string.match(str, ".*%[(%d+)/(%d+)%].*")
  if current ~= nil and total ~= nil then
    return 100 / tonumber(total) * tonumber(current)
  else
    return 0
  end
end

function notification_listener:new(action)
  ntf.progress("Meson", action, 0)
  local o = { action = action }
  setmetatable(o,       self)
  self.__index = self
  return o
end

function notification_listener:update(_, content)
  local perc = _extract_percentage(content)
  if perc ~= 100 then ntf.progress("Meson", self.action, perc) end
end

function notification_listener:success()
  ntf.progress_complete()
  ntf.notify(self.action .. " completed successfully", vim.log.levels.INFO)
end

function notification_listener:failure()
  ntf.progress_complete()
  ntf.notify(self.action .. " failed", vim.log.levels.ERROR)
end

return notification_listener
