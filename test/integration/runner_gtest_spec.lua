local _, testcase_runner = unpack(require("mesone.testcases.gtest_runner"))

local function sort_by_line(a, b)
  return a.line < b.line
end

local function normalize_output(output)
  return (output:gsub("googletest%-%d+%.%d+%.%d+", "googletest-VERSION"))
end

local function normalize_results(t)
  for _, suite in ipairs(t) do
    for _, test in ipairs(suite.test_list) do
      if test.output then
        test.output = normalize_output(test.output)
      end
    end
  end
end

describe("gtest runner", function()
  it("parse testcases", function()
    local runner = testcase_runner:new()
    local testcases = runner:get_testcases("test/examples/meson_gtest", "test/examples/meson_gtest/build/test/unittest")
    local expected = {
      {
        filename = "test/examples/test/unittest.cc",
        line = 4,
        name = "FooTest.Simple",
        status = "unk",
        type = "gtest",
      },
      {
        filename = "test/examples/test/unittest.cc",
        line = 6,
        name = "FooTest.Skipped",
        status = "unk",
        type = "gtest",
      },
      {
        filename = "test/examples/test/unittest.cc",
        line = 11,
        name = "FooTest.Fault",
        status = "unk",
        type = "gtest",
      },
    }
    table.sort(testcases, sort_by_line)
    table.sort(expected,  sort_by_line)
    assert.are.same(expected, testcases)
  end)

  it("run tests", function()
    local results = {}
    local testsuite = {
      test_list = {
        {
          filename = "test/examples/test/unittest.cc",
          line = 4,
          name = "FooTest.Simple",
          status = "unk",
          type = "gtest",
        },
        {
          filename = "test/examples/test/unittest.cc",
          line = 6,
          name = "FooTest.Skipped",
          status = "unk",
          type = "gtest",
        },
        {
          filename = "test/examples/test/unittest.cc",
          line = 11,
          name = "FooTest.Fault",
          status = "unk",
          type = "gtest",
        },
      },
      name = "my_testsuite",
      cmd = { "test/examples/meson_gtest/build/test/unittest" },
      type = "gtest",
    }
    local runner = testcase_runner:new()
    runner:run(testsuite, function(result)
      table.insert(results, result)
    end, true)
    local expected = {
      {
        name = "my_testsuite",
        test_list = {
          {
            name = "FooTest.Simple",
            output =
            "Running main() from ../subprojects/googletest-VERSION/googletest/src/gtest_main.cc\nNote: Google Test filter = FooTest.Simple\n[==========] Running 1 test from 1 test suite.\n[----------] Global test environment set-up.\n[----------] 1 test from FooTest\n[ RUN      ] FooTest.Simple\n[       OK ] FooTest.Simple (0 ms)\n[----------] 1 test from FooTest (0 ms total)\n\n[----------] Global test environment tear-down\n[==========] 1 test from 1 test suite ran. (0 ms total)\n[  PASSED  ] 1 test.",
            status = "run",
          },
        },
      },
      {
        name = "my_testsuite",
        test_list = {
          {
            name = "FooTest.Skipped",
            output =
            "Running main() from ../subprojects/googletest-VERSION/googletest/src/gtest_main.cc\nNote: Google Test filter = FooTest.Skipped\n[==========] Running 1 test from 1 test suite.\n[----------] Global test environment set-up.\n[----------] 1 test from FooTest\n[ RUN      ] FooTest.Skipped\n../test/unittest.cc:7: Skipped\nSkipping single test\n\n[  SKIPPED ] FooTest.Skipped (0 ms)\n[----------] 1 test from FooTest (0 ms total)\n\n[----------] Global test environment tear-down\n[==========] 1 test from 1 test suite ran. (0 ms total)\n[  PASSED  ] 0 tests.\n[  SKIPPED ] 1 test, listed below:\n[  SKIPPED ] FooTest.Skipped",
            status = "skipped",
          },
        },
      },
      {
        name = "my_testsuite",
        test_list = {
          {
            name = "FooTest.Fault",
            output =
            "Running main() from ../subprojects/googletest-VERSION/googletest/src/gtest_main.cc\nNote: Google Test filter = FooTest.Fault\n[==========] Running 1 test from 1 test suite.\n[----------] Global test environment set-up.\n[----------] 1 test from FooTest\n[ RUN      ] FooTest.Fault\n[       OK ] FooTest.Fault (0 ms)\n[----------] 1 test from FooTest (0 ms total)\n\n[----------] Global test environment tear-down\n[==========] 1 test from 1 test suite ran. (0 ms total)\n[  PASSED  ] 1 test.",
            status = "run",
          },
        },
      },
    }
    local sort_by_name = function(a, b)
      return a.test_list[1].name < b.test_list[1].name
    end
    table.sort(results,  sort_by_name)
    table.sort(expected, sort_by_name)
    for i = 1, #results do
      table.sort(results[i].test_list,  function(a, b) return a.name < b.name end)
      table.sort(expected[i].test_list, function(a, b) return a.name < b.name end)
    end
	normalize_results(results)
	print("-- RESULTS --")
	print(vim.inspect(results))
	print("-- EXPECTED --")
	print(vim.inspect(expected))
    assert.are.same(expected, results)
  end)
end)
