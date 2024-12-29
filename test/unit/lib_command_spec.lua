local command = require("mesone.lib.command")
local listener = require("mesone.lib.listener.init")

---@diagnostic disable: undefined-field
local eq = assert.are.same

local mock_listener = listener:new()
function mock_listener:new()
  local o = { updates = {}, completed_successfully = false }
  setmetatable(o, self)
  self.__index = self
  return o
end

function mock_listener:update(content_type, content)
  table.insert(self.updates, { type = content_type, content = content })
end

function mock_listener:success()
  self.completed_successfully = true
end

function mock_listener:failure()
  self.completed_successfully = false
end

describe("command", function()
  it("should return stdout", function()
    local co = coroutine.running()
    local return_status = -1
    local my_listener = mock_listener:new()
    local listener_builder = function(_)
      return { my_listener }
    end
    local on_terminate = function(state)
      return_status = state
      coroutine.resume(co)
    end

    local cmd = command:new({ command = "/usr/bin/bash" })
    cmd:execute({ "-c", "echo 123" }, "myaction", on_terminate, listener_builder)
    coroutine.yield()

    eq(return_status, 0)
    eq(my_listener.completed_successfully, true)
    eq(my_listener.updates, {
      {
        content = "/usr/bin/bash -c echo 123",
        type = "start",
      },
      {
        content = "123",
        type = "out",
      },
    })
  end)

  it("should return stderr", function()
    local co = coroutine.running()
    local return_status = -1
    local my_listener = mock_listener:new()
    local listener_builder = function(_)
      return { my_listener }
    end
    local on_terminate = function(state)
      return_status = state
      coroutine.resume(co)
    end

    local cmd = command:new({ command = "/usr/bin/cat" })
    cmd:execute({ "-invalid_parameter" }, "myaction", on_terminate, listener_builder)
    coroutine.yield()

    eq(return_status, 1)
    eq(my_listener.completed_successfully, false)
    eq(my_listener.updates, {
      {
        content = "/usr/bin/cat -invalid_parameter",
        type = "start",
      },
      {
        content = "/usr/bin/cat: invalid option -- 'i'",
        type = "err",
      },
      {
        content = "Try '/usr/bin/cat --help' for more information.",
        type = "err",
      },
    })
  end)
end)
