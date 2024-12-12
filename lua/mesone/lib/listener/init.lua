local listener = {}

function listener:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function listener:update(content_type, content) end
function listener:success() end
function listener:failure() end

return listener

