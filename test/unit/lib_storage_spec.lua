---@diagnostic disable: undefined-field
local storage = require("mesone.lib.storage")

describe("storage", function()
  it("should return saved values", function()
    math.randomseed(os.time())
    local my_random = math.random(1, 10000000)
    print(my_random)
    local value = {
      number = 42,
      string = "this is a string",
      list = { 1, 2, 3, 4, 5 },
      random = my_random,
    }
    storage.save("mykey", value)
    local got = storage.load("mykey", {})
    assert.are.same(got, value)
  end)

  it("should return default value if not already saved", function()
    math.randomseed(os.time())
    local my_random = math.random(1, 10000000)
    local if_missing = { missing = true, random = my_random }
    local got = storage.load("missing_key", if_missing)
    assert.are.same(got, if_missing)
  end)
end)
