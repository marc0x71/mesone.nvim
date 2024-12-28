local _, testcase_runner = unpack(require("mesone.testcases.generic_runner"))

describe("generic runner", function()
  it("parse testcases", function()
    local runner = testcase_runner:new()
    local testcases = runner:get_testcases(
      "test/examples/meson_generic",
      "test/examples/meson_generic/build/test/success_test",
      function()
        return { sources = { "test_source.cc" } }
      end
    )
    assert.are.same(testcases, {
      {
        filename = "test_source.cc",
        line = 0,
        name = "<Unknown>",
        status = "unk",
        type = "generic",
      },
    })
  end)

  it("run success tests", function()
    local results = {}
    local testsuite = {
      test_list = {
        {
          filename = "test_source.cc",
          line = 0,
          name = "<Unknown>",
          status = "unk",
          type = "generic",
        },
      },
      name = "my_testsuite",
      cmd = { "test/examples/meson_generic/build/test/success_test" },
      type = "generic",
    }
    local runner = testcase_runner:new()
    runner:run(testsuite, function(result)
      table.insert(results, result)
    end, true)
    assert.are.same(results, {
      {
        name = "my_testsuite",
        test_list = {
          {
            name = "<Unknown>",
            output = "successful run custom test",
            status = "run",
          },
        },
      },
    })
  end)
  it("run fail tests", function()
    local results = {}
    local testsuite = {
      test_list = {
        {
          filename = "test_source.cc",
          line = 0,
          name = "<Unknown>",
          status = "unk",
          type = "generic",
        },
      },
      name = "my_testsuite",
      cmd = { "test/examples/meson_generic/build/test/fail_test" },
      type = "generic",
    }
    local runner = testcase_runner:new()
    runner:run(testsuite, function(result)
      table.insert(results, result)
    end, true)
    assert.are.same(results, {
      {
        name = "my_testsuite",
        test_list = {
          {
            name = "<Unknown>",
            output = "successful run failing test",
            status = "fail",
          },
        },
      },
    })
  end)
end)
