local runner = require("mesone.testcases.init")
local job = require("plenary.job")

local runner_name = "generic"
local generic_testcase_name = "<Unknown>"

local generic_runner = runner:new()

function generic_runner:get_testcases(_, command, target_provider)
  local filename = nil
  local target = target_provider(command)
  if target ~= nil then
    filename = target.sources[1]
  end
  return {
    {
      name = generic_testcase_name,
      filename = filename,
      line = 0,
      status = "unk",
      type = runner_name,
    },
  }
end

function generic_runner:run(testsuite, callback)
  job
    :new({
      command = table.concat(testsuite.cmd, ""),
      args = {},
      on_exit = function(j, exit_code)
        local stdout = table.concat(j:result(), "\n")
        local status = "fail"
        if exit_code == 0 then
          status = "run"
        end

        local test_list = {
          {
            name = generic_testcase_name,
            status = status,
            output = stdout,
          },
        }

        callback({ name = testsuite.name, test_list = test_list })
      end,
    })
    :start()
end

function generic_runner:debug_arguments(testcase)
  return {}
end

return { runner_name, generic_runner }
