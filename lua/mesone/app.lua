local M = {}
local instance = nil
local settings = require('mesone.settings')
local scandir = require("plenary.scandir")
local command = require('mesone.lib.command')
local utils = require('mesone.lib.utils')
local notification = require('mesone.lib.notification')
local project = require('mesone.project')

M.get = function()
    if not instance then instance = M:new(settings:new()) end
    return instance
end

function M:_on_command_exit(status)
    self.running = false
    if status ~= 0 and not self.opts:get().show_command_logs then
        self:show_log()
    end
end

function M:_on_init_completed()
    self.project = project:new({folder = self.opts:get().build_folder})
    self.project:load()
end

function M:_init()
    self.project = nil
    local pwd = vim.uv.cwd() .. "/"
    if utils.file_exists(pwd .. "meson.build") then
        local metainfo_dir = nil
        scandir.scan_dir_async(pwd, {
            hidden = true,
            respect_gitignore = false,
            silent = true,
            depth = self.opts:get().info_depth,
            only_dirs = true,
            add_dirs = true,
            search_pattern = {".*meson.info"},
            on_insert = function(filename)
                filename = vim.fs.normalize(filename)
                if metainfo_dir == nil and vim.fs.basename(filename) ==
                    "meson-info" then
                    metainfo_dir = vim.fs.dirname(filename)
                end
            end,
            on_exit = function(_)
                self.opts:update({
                    build_folder = utils.remove_prefix(metainfo_dir, pwd)
                })
                vim.schedule(function() self:_on_init_completed() end)
            end
        })
    end
end

function M:_build_setup()
    if self.running then
        notification.notify("Meson already running", "warn")
        return
    end
    local cmd = command:new({
        log_filename = self.log_filename,
        show_command_logs = self.opts:get().show_command_logs
    })
    local args = {
        "setup", "--buildtype", self.opts:get().build_type,
        self.opts:get().build_folder
    }
    self.running = true
    cmd:execute(args, "Setup",
                function(status) self:_on_command_exit(status) end)
end

function M:_compile()
    if self.running then
        notification.notify("Meson already running", "warn")
        return
    end
    local cmd = command:new({
        log_filename = self.log_filename,
        show_command_logs = self.opts:get().show_command_logs
    })
    local args = {"compile", "-C", self.opts:get().build_folder}
    self.running = true
    cmd:execute(args, "Compile",
                function(status) self:_on_command_exit(status) end)
end

function M:new(opts)
    local log_filename = os.tmpname()
    local cwd = vim.uv.cwd()
    local o = {
        opts = opts,
        cwd = cwd,
        log_filename = log_filename,
        project = nil
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function M:setup(opts) self.opts:update(opts) end

function M:parse_command(opts)
    local action = opts.fargs[1]
    if action == "init" then
        self:_init()
    elseif action == "setup" then
        self:_build_setup()
    elseif action == "compile" then
        self:_compile()
    else
        vim.notify("Mesone: invalid arguments: " .. opts.args,
                   vim.log.levels.ERROR)
    end
end

return M
