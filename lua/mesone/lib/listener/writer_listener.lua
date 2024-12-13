local listener = require("mesone.lib.listener.init")

local writer_listener = listener:new()

function writer_listener:new(filename)
  -- create empty file
  local f = io.open(filename, "w")
  io.close(f)

  local o = { filename = filename }
  setmetatable(o, self)
  self.__index = self
  return o
end

function writer_listener:update(_, content)
  local f = io.open(self.filename, "a")
  io.output(f)
  io.write(content .. "\n")
  io.close(f)
end

function writer_listener:success() end

function writer_listener:failure() end

return writer_listener
