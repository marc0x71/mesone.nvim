local utils = require("mesone.lib.utils")
local job = require("plenary.job")
local dap = require("dap")

local generic_testcase_name = "<Unknown>"

local M = {}

local function _try_catch2(path, cmd)
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
      type = "catch2"
    })
  end

  return test_list
end

local function _try_gtest(path, cmd)
  local testlist_filename = os.tmpname()

  local command = {
    cmd, "--gtest_list_tests", "--gtest_output=json:" .. testlist_filename
  }
  local result = vim.system(command, { text = true }):wait()

  if (result.code ~= 0) then
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
        type = "gtest"
      })
    end
  end

  os.remove(testlist_filename)

  return test_list
end

local function _build_generic(path, cmd, target_provider)
  local filename = nil
  local target = target_provider(cmd)
  if target ~= nil then
    filename = target.sources[1]
  end
  return { {
    name = generic_testcase_name,
    filename = filename,
    line = 0,
    status = "unk",
    type = "generic"
  } }
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

local function _run_gtest(testsuite, callback)
  for _, testcase in ipairs(testsuite.test_list) do
    local output_filename = os.tmpname()
    job:new({
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
              output = stdout
            })
          end
        end

        os.remove(output_filename)

        callback({ name = testsuite.name, test_list = test_list })
      end,

    }):start()
  end
end

local function _run_catch2(testsuite, callback)
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

local function _run_generic(testsuite, callback)
  job:new({
    command = table.concat(testsuite.cmd, ""),
    args = {},
    on_exit = function(j, exit_code)
      local stdout = table.concat(j:result(), "\n")
      local status = "fail"
      if exit_code == 0 then
        status = "run"
      end

      local test_list = { {
        name = generic_testcase_name,
        status = status,
        output = stdout
      } }

      callback({ name = testsuite.name, test_list = test_list })
    end,

  }):start()
end

function M.get_testcases(path, cmd, target_provider)
  return _try_catch2(path, cmd) or _try_gtest(path, cmd) or _build_generic(path, cmd, target_provider)
end

function M.run(test, callback)
  if test.type == "gtest" then
    _run_gtest(test, callback)
  elseif test.type == "catch2" then
    _run_catch2(test, callback)
  else
    _run_generic(test, callback)
  end
end

local function _compose_args_gtest(test)
  return { "--gtest_filter=" .. test.test_list[1].name }
end

local function _compose_args_catch2(test)
  return { test.test_list[1].name }
end

local function _compose_args_generic(_)
  return {}
end

function M.debug(test, dap_adapter)
  local args = {}
  if test.type == "gtest" then
    args = _compose_args_gtest(test)
  elseif test.type == "catch2" then
    args = _compose_args_catch2(test)
  else
    args = _compose_args_generic(test)
  end
  local dap_config = {
    args = args,
    cwd = vim.uv.cwd(),
    program = test.cmd[1],
    request = "launch",
    name = "Debug " .. test.test_list[1].name,
    type = dap_adapter
  }

  dap.run(dap_config)
end

return M
