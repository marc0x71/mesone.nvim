local utils = require('mesone.lib.utils')

local M = {}

local function _try_catch2(path, cmd)
    local command = {cmd, "--list-tests", "--reporter", "json"}
    local result = vim.system(command, {text = true}):wait()

    if (result.code ~= 0) then
        -- If there is an error is not catch2
        return nil
    end
    local tests = vim.json.decode(result.stdout,
                                  {luanil = {object = true, array = true}})

    local test_list = {}
    for _, testcase in ipairs(tests.listings.tests) do
        local filename = vim.fs.normalize(path .. "/" ..
                                              testcase['source-location']
                                                  .filename)
        table.insert(test_list, {
            name = testcase.name,
            filename = filename,
            line = testcase['source-location'].line
        })
    end
    return test_list
end

local function _try_gtest(path, cmd)
    local testlist_filename = os.tmpname()

    local command = {
        cmd, "--gtest_list_tests", "--gtest_output=json:" .. testlist_filename
    }
    local result = vim.system(command, {text = true}):wait()

    if (result.code ~= 0) then
        -- If there is an error is not gtest
        os.remove(testlist_filename)
        return nil
    end
    local tests = utils.read_json_file(testlist_filename)

    local test_list = {}
    for _, testsuite in ipairs(tests.testsuites) do
        local name_prefix = testsuite.name .. "."
        for _, testcase in ipairs(testsuite.testsuite) do
            local filename = vim.fs.normalize(path .. "/" .. testcase.file)
            table.insert(test_list, {
                name = name_prefix .. testcase.name,
                filename = filename,
                line = testcase.line
            })
        end
    end

    os.remove(testlist_filename)

    return test_list
end

function M.get_testcases(path, cmd)
    return _try_catch2(path, cmd) or _try_gtest(path, cmd)
end

return M
