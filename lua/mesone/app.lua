local M = {}
local instance = nil
local settings = require('mesone.settings')
local utils = require('mesone.lib.utils')
local command = require('mesone.lib.command')
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

function M:_on_init_completed(status)
    self.running = false
    if status == 0 then
        self.project = project:new({folder = self.opts:get().build_folder})
        self.project:load()
    else
        self.project = nil
    end
end

function M:_init()
    -- FIXME is really necessary use 'meson setup' to initialize plugin?
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
    cmd:execute(args, "Init",
                function(status) self:_on_init_completed(status) end)
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
