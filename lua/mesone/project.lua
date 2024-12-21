local testcases = require("mesone.testcases.testcase")
local notification = require("mesone.lib.notification")
local utils = require("mesone.lib.utils")

local M = {}

function M:new(opts)
  local o = { folder = (opts.folder or vim.uv.cwd()) .. "/meson-info/", max_testcase_len = 0 }
  setmetatable(o, self)
  self.__index = self

  return o
end

function M:load()
  -- meson-info
  local meson_info = utils.read_json_file(self.folder .. "meson-info.json")
  if meson_info == nil then
    notification.notify("Meson introspect not found", "warn")
    return
  end
  self.meson_version = meson_info.meson_version.full

  self.options = {}
  self.targets = {}
  self.tests = {}
  self.tests_status = {}
  self.sources = {}

  -- option
  self:_parse_build_options(utils.read_json_file(self.folder .. meson_info.introspection.information.buildoptions.file))
  --
  -- targets
  self:_parse_targets(utils.read_json_file(self.folder .. meson_info.introspection.information.targets.file))

  -- tests
  self:_parse_tests(
    meson_info.directories.build,
    utils.read_json_file(self.folder .. meson_info.introspection.information.tests.file)
  )
end

function M:_parse_build_options(options)
  for _, option in ipairs(options) do
    if option.name == "backend" then
      self.options.backend = option.value
    elseif option.name == "buildtype" then
      self.options.build_type = option.value
      self.options.build_types = option.choices
    end
  end
end

function M:_parse_tests(path, tests)
  self.max_testcase_len = 0
  for _, test in ipairs(tests) do
    local test_list = {}
    if utils.file_exists(test.cmd[1]) then
      ---@diagnostic disable-next-line: cast-local-type
      test_list = testcases.get_testcases(path, test.cmd[1], function(name)
        return self:get_target(name)
      end)
    end
    local test_runner = test.protocol
    for _, testcase in ipairs(test_list) do
      if string.len(testcase.name) > self.max_testcase_len then
        self.max_testcase_len = string.len(testcase.name)
      end
      test_runner = testcase.type
      if self.tests_status[testcase.filename] == nil then
        self.tests_status[testcase.filename] =
          { { name = testcase.name, line = testcase.line, status = testcase.status } }
      else
        table.insert(
          self.tests_status[testcase.filename],
          { name = testcase.name, line = testcase.line, status = testcase.status }
        )
      end
    end
    table.insert(self.tests, {
      name = test.name,
      type = test_runner,
      cmd = test.cmd,
      test_list = test_list,
    })
  end
end

function M:_parse_targets(targets)
  for _, target in ipairs(targets) do
    -- skip custom, run and jar target type
    if target.type == "custom" or target.type == "run" or target.type == "jar" then
      goto continue
    end

    local sources_list = target.extra_files

    for _, detail in ipairs(target.target_sources) do
      if detail.generated_sources ~= nil then
        sources_list = utils.concat_array(sources_list, detail.generated_sources)
      end
      if detail.sources ~= nil then
        sources_list = utils.concat_array(sources_list, detail.sources)
      end
    end

    self.targets[target.filename[1]] = {
      name = target.name,
      type = target.type,
      subproject = target.subproject,
      sources = sources_list,
      -- A target usually generates only one file.
      -- Only 'custom' targets could have multiple outputs, but it will be filtered.
      target = target.filename[1],
    }

    if target.subproject == nil then
      self.sources = utils.concat_array(self.sources, sources_list)
    end

    ::continue::
  end
end

function M:get_max_testcase_len()
  return self.max_testcase_len
end

function M:get_target(name)
  return self.targets[name]
end

function M:update_test_result(results)
  for _, test_result in ipairs(results.test_list) do
    for _, testsuite in ipairs(self.tests) do
      if testsuite.name == results.name then
        local break_me = false
        for _, testcase in ipairs(testsuite.test_list) do
          if test_result.name == testcase.name then
            -- update testcase
            testcase.status = test_result.status
            testcase.output = test_result.output
            if self.tests_status[testcase.filename] ~= nil then
              -- update test status
              for _, test_state in ipairs(self.tests_status[testcase.filename]) do
                if test_state.name == testcase.name then
                  test_state.status = testcase.status
                  break
                end
              end
            end
            break_me = true
            break
          end
        end
        if break_me then
          break
        end
      end
    end
  end
end

function M:get_executable()
  local list = {}
  for _, target in pairs(self.targets) do
    if target.type == "executable" then
      list[target.name] = target
    end
  end
  return list
end

return M
