local dap = require("dap")
local _, default_runner = unpack(require("mesone.testcases.generic_runner"))

local function _build_runners(...)
  local map = {}
  for _, module_name in ipairs({ ... }) do
    local name, runner = unpack(require(module_name))
    map[name] = runner:new()
  end
  return map
end

local M = {
  runners = _build_runners("mesone.testcases.gtest_runner", "mesone.testcases.catch2_runner"),
  default_runner = default_runner:new(),
}

function M.get_testcases(path, cmd, target_provider)
  for _, runner in pairs(M.runners) do
    local testcases = runner:get_testcases(path, cmd, target_provider)
    if testcases ~= nil then
      return testcases
    end
  end
  return M.default_runner:get_testcases(path, cmd, target_provider)
end

function M.run(test, callback)
  if M.runners[test.type] ~= nil then
    return M.runners[test.type]:run(test, callback)
  else
    return M.default_runner:run(test, callback)
  end
end

function M.debug(test, dap_adapter)
  local args = M.default_runner:debug_arguments(test)
  if M.runners[test.type] ~= nil then
    args = M.runners[test.type]:debug_arguments(test)
  end
  local dap_config = {
    args = args,
    cwd = vim.uv.cwd(),
    program = test.cmd[1],
    request = "launch",
    name = "Debug " .. test.test_list[1].name,
    type = dap_adapter,
  }

  dap.run(dap_config)
end

return M
