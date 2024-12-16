local job = require("plenary.job")
local runner = require("mesone.testcases.init")

local runner_name = "catch2"

local catch2_runner = runner:new()

function catch2_runner:get_testcases(path, cmd, _)
  local command = { cmd, "--list-tests", "--reporter", "json" }
  local result = vim.system(command, { text = true }):wait()

  if (result.code ~= 0) then
    -- If there is an error is not catch2
    return nil
  end
  local success, tests = pcall(vim.json.decode, result.stdout,
    { luanil = { object = true, array = true } })

  if not success then
    return nil
  end

  local test_list = {}
  for _, testcase in ipairs(tests.listings.tests) do
    local filename = vim.fs.normalize(path .. "/" ..
      testcase["source-location"]
      .filename)
    table.insert(test_list, {
      name = testcase.name,
      filename = filename,
      line = testcase["source-location"].line,
      status = "unk",
      type = runner_name
    })
  end

  return test_list
end

local function _catch2_status(totals)
  if totals.failed ~= 0 then
    return "fail"
  end
  if totals.skipped ~= 0 then
    return "skipped"
  end
  if totals.passed ~= 0 then
    return "run"
  end
  return "unk"
end


function catch2_runner:run(testsuite, callback)
  for _, testcase in ipairs(testsuite.test_list) do
    job:new({
      command = table.concat(testsuite.cmd, ""),
      args = { "--reporter=json", testcase.name },
      on_exit = function(j, _)
        local stdout = table.concat(j:result(), "\n")
        local test_result = vim.json.decode(stdout, { luanil = { object = true, array = true } })
        local totals = test_result["test-run"].totals["test-cases"]
        local status = _catch2_status(totals)

        local output = test_result["test-run"]["test-cases"][1].runs[1]["captured-stdout"] or ""
        local errors = test_result["test-run"]["test-cases"][1].runs[1]["captured-stderr"] or ""

        local assertions_failed = ""
        if status == "fail" then
          for _, run_path in ipairs(test_result["test-run"]["test-cases"][1].runs[1].path) do
            for _, path in ipairs(run_path.path) do
              if not path.status and path.kind == "assertion" then
                assertions_failed = assertions_failed ..
                  "assertion failed at line " .. path["source-location"].line .. "\n"
              end
            end
          end
        end

        local test_list = { {
          name = testcase.name,
          status = status,
          output = output .. "\n" .. errors .. "\n" .. assertions_failed
        } }

        callback({ name = testsuite.name, test_list = test_list })
      end,

    }):start()
  end
end

function catch2_runner:debug_arguments(testcase)
  return { testcase.test_list[1].name }
end

return { runner_name, catch2_runner }
