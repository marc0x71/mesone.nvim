local testcases = require('mesone.testcases')
local notification = require('mesone.lib.notification')
local utils = require('mesone.lib.utils')

local M = {}

function M:new(opts)
    local o = {folder = (opts.folder or vim.uv.cwd()) .. "/meson-info/"}
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

    self.targets = {}
    self.tests = {}
    self.sources = {}

    -- targets
    self:_parse_targets(utils.read_json_file(self.folder ..
                                                 meson_info.introspection
                                                     .information.targets.file))

    -- tests
    self:_parse_tests(meson_info.directories.build, utils.read_json_file(self.folder ..
                                               meson_info.introspection
                                                   .information.tests.file))

end

function M:_parse_tests(path, tests)
    for _, test in ipairs(tests) do
        local test_list = {}
        if utils.file_exists(test.cmd[1]) then
            ---@diagnostic disable-next-line: cast-local-type
            test_list = testcases.get_testcases(path, test.cmd[1])
        end
        table.insert(self.tests, {
            name = test.name,
            type = test.protocol,
            cmd = test.cmd,
            test_list = test_list
        })
    end
end

function M:_parse_targets(targets)
    for _, target in ipairs(targets) do

        -- skip custom, run and jar target type
        if target.type == "custom" or target.type == "run" or target.type ==
            "jar" then goto continue end

        local sources_list = target.extra_files

        for _, detail in ipairs(target.target_sources) do
            if detail.generated_sources ~= nil then
                sources_list = utils.concat_array(sources_list,
                                                  detail.generated_sources)
            end
            if detail.sources ~= nil then
                sources_list = utils.concat_array(sources_list, detail.sources)
            end
        end

        table.insert(self.targets, {
            name = target.name,
            type = target.type,
            subproject = target.subproject,
            sources = sources_list,
            -- A target usually generates only one file.
            -- Only 'custom' targets could have multiple outputs, but it will be filtered.
            target = target.filename[1]
        })

        if target.subproject == nil then
            self.sources = utils.concat_array(self.sources, sources_list)
        end

        ::continue::
    end
end

return M
