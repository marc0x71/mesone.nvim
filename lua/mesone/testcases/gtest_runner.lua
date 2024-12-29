local utils = require("mesone.lib.utils")
local job = require("plenary.job")
local runner = require("mesone.testcases.init")

local runner_name = "gtest"
local gtest_runner = runner:new()

function gtest_runner:debug_arguments(testcase)
  return { "--gtest_filter=" .. testcase.test_list[1].name }
end

function gtest_runner:get_testcases(path, cmd, _)
  local testlist_filename = os.tmpname()

  local command = {
    cmd,
    "--gtest_list_tests",
    "--gtest_output=json:" .. testlist_filename,
  }
  local result = vim.system(command, { text = true }):wait()

  if result.code ~= 0 then
    -- If there is an error is not gtest
    os.remove(testlist_filename)
    return nil
  end
  local success, tests = pcall(utils.read_json_file, testlist_filename)

  if not success then
    return nil
  end

  local test_list = {}
  for _, testsuite in ipairs(tests.testsuites) do
    local name_prefix = testsuite.name .. "."
    for _, testcase in ipairs(testsuite.testsuite) do
      local filename = vim.fs.normalize(path .. "/" .. testcase.file)
      table.insert(test_list, {
        name = name_prefix .. testcase.name,
        filename = filename,
        line = testcase.line,
        status = "unk",
        type = runner_name,
      })
    end
  end

  os.remove(testlist_filename)

  return test_list
end

local function _gtest_status(result, failures)
  if result == "COMPLETED" and failures == nil then
    return "run"
  elseif result == "COMPLETED" and failures ~= nil then
    return "fail"
  elseif result == "FAIL" then
    return "fail"
  elseif result == "SKIPPED" then
    return "skipped"
  else
    return "unk"
  end
end

function gtest_runner:run(testsuite, callback, run_sync)
  run_sync = run_sync or false
  for _, testcase in ipairs(testsuite.test_list) do
    local output_filename = os.tmpname()
    local my_job = job
      ---@diagnostic disable-next-line: missing-fields
      :new({
        command = table.concat(testsuite.cmd, ""),
        args = { "--gtest_filter=" .. testcase.name, "--gtest_output=json:" .. output_filename },
        on_exit = function(j, _)
          local stdout = table.concat(j:result(), "\n")

          local test_result = utils.read_json_file(output_filename)

          local test_list = {}
          for _, testsuite_result in ipairs(test_result.testsuites) do
            local name_prefix = testsuite_result.name .. "."
            for _, testcase_result in ipairs(testsuite_result.testsuite) do
              table.insert(test_list, {
                name = name_prefix .. testcase_result.name,
                status = _gtest_status(testcase_result.result, testcase_result.failures),
                output = stdout,
              })
            end
          end

          os.remove(output_filename)

          callback({ name = testsuite.name, test_list = test_list })
        end,
      })
    if run_sync then
      my_job:sync()
    else
      my_job:start()
    end
  end
end

return { runner_name, gtest_runner }
