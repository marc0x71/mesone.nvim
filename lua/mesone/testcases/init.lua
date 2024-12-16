local runner = {}

function runner:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function runner:name() end

function runner:get_testcases(path, command) end

function runner:run(testsuite, callback) end

function runner:debug_arguments(testcase) end

return runner
