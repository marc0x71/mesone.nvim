local _, testcase_runner = unpack(require("mesone.testcases.catch2_runner"))

describe("catch2 runner", function()
  it("parse testcases", function()
    local runner = testcase_runner:new()
    local testcases =
      runner:get_testcases("test/examples/meson_catch2", "test/examples/meson_catch2/build/test/unittest")
    assert.are.same(testcases, {
      {
        filename = "test/examples/test/unittest.cc",
        line = 4,
        name = "Simple test 1",
        status = "unk",
        type = "catch2",
      },
      {
        filename = "test/examples/test/unittest.cc",
        line = 9,
        name = "This test will be skipped",
        status = "unk",
        type = "catch2",
      },
      {
        filename = "test/examples/test/unittest.cc",
        line = 16,
        name = "This test will fail",
        status = "unk",
        type = "catch2",
      },
    })
  end)

  it("run tests", function()
    local results = {}
    local testsuite = {
      test_list = {
        {
          filename = "test/examples/test/unittest.cc",
          line = 4,
          name = "Simple test 1",
          status = "unk",
          type = "catch2",
        },
        {
          filename = "test/examples/test/unittest.cc",
          line = 9,
          name = "This test will be skipped",
          status = "unk",
          type = "catch2",
        },
        {
          filename = "test/examples/test/unittest.cc",
          line = 16,
          name = "This test will fail",
          status = "unk",
          type = "catch2",
        },
      },
      name = "my_testsuite",
      cmd = { "test/examples/meson_catch2/build/test/unittest" },
      type = "catch2",
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
            name = "Simple test 1",
            output = "simple test output\n\n\n",
            status = "run",
          },
        },
      },
      {
        name = "my_testsuite",
        test_list = {
          {
            name = "This test will be skipped",
            output = "failed test output\n\nfailed test error\n\n",
            status = "skipped",
          },
        },
      },
      {
        name = "my_testsuite",
        test_list = {
          {
            name = "This test will fail",
            output = "\n\n",
            status = "run",
          },
        },
      },
    })
  end)
end)
