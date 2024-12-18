local scandir = require("plenary.scandir")
local dap = require("dap")

local window = require("mesone.ui.window")
local project = require("mesone.project")
local tests = require("mesone.tests")
local settings = require("mesone.settings")
local command = require("mesone.lib.command")
local notification = require("mesone.lib.notification")
local storage = require("mesone.lib.storage")
local utils = require("mesone.lib.utils")

local M = {}
local instance = nil

M.get = function()
  if not instance then
    instance = M:new(settings:new())
  end
  return instance
end

function M:new(opts)
  local log_filename = os.tmpname()
  local cwd = vim.uv.cwd()
  local o = {
    opts = opts,
    cwd = cwd,
    log_filename = log_filename,
    project = nil,
    tests = nil,
    full_build_folder = vim.fs.normalize(cwd .. "/" ..
      opts:get().build_folder)
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:_on_command_exit(status)
  self.running = false
  if status == 0 then
    self:_update_project()
  elseif status ~= 0 and not self.opts:get().show_command_logs then
    self:_show_log()
  end
end

function M:_update_project()
  self.project = project:new({ folder = self.opts:get().build_folder })
  self.project:load()
  self.opts:update({ build_type = self.project.options.build_type })
  if self.tests ~= nil then
    self.tests:update_project(self.project)
  end
end

function M:_on_init_completed()
  self:_update_project()
  notification.notify("Mesone initialized", vim.log.levels.INFO)
end

function M:init()
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
      search_pattern = { ".*meson.info" },
      on_insert = function(filename)
        filename = vim.fs.normalize(filename)
        if metainfo_dir == nil and vim.fs.basename(filename) ==
          "meson-info" then
          metainfo_dir = vim.fs.dirname(filename)
        end
      end,
      on_exit = function(_)
        if metainfo_dir ~= nil then
          self.opts:update({
            build_folder = utils.remove_prefix(metainfo_dir, pwd)
          })
          vim.schedule(function() self:_on_init_completed() end)
        end
      end
    })
  end
end

function M:_meson_setup()
  if self.running then
    notification.notify("Meson already running", "warn")
    return
  end
  local cmd = command:new({
    build_folder = self.full_build_folder,
    log_filename = self.log_filename,
    show_command_logs = self.opts:get().show_command_logs
  })
  local args = {
    "setup", "--reconfigure", "--buildtype", self.opts:get().build_type,
    self.opts:get().build_folder
  }
  self.running = true
  cmd:execute(args, "Setup",
    function(status) self:_on_command_exit(status) end)
end

function M:_meson_compile()
  if self.running then
    notification.notify("Meson already running", "warn")
    return
  end
  local cmd = command:new({
    build_folder = self.full_build_folder,
    log_filename = self.log_filename,
    show_command_logs = self.opts:get().show_command_logs
  })
  local args = { "compile", "-C", self.opts:get().build_folder }
  self.running = true
  cmd:execute(args, "Compile",
    function(status) self:_on_command_exit(status) end)
end

function M:setup(opts)
  local saved_opts = storage.load(vim.uv.cwd(), {})
  self.opts:update(vim.tbl_extend("force", opts, saved_opts))
  self.full_build_folder = vim.fs.normalize(
    vim.uv.cwd() .. "/" ..
    self.opts:get().build_folder)
end

function M:_show_log()
  local buf, _ = window.centered_window()

  -- press 'q' or 'esc' to close window
  for _, key in ipairs({ "q", "<esc>" }) do
    vim.api.nvim_buf_set_keymap(buf, "n", key, "<cmd>close<cr>", {
      nowait = true,
      noremap = true,
      silent = true
    })
  end

  vim.api.nvim_set_option_value("readonly",   false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true,  { buf = buf })
  local first = true

  utils.read_file(self.log_filename, function(line)
    local content_type = "out"
    if utils.is_failure_message(line) then content_type = "err" end
    utils.buf_append_colorized(buf, line, content_type, first)
    first = false
  end)

  vim.api.nvim_set_option_value("readonly",   true,  { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

function M:_tests()
  if self.tests == nil then
    self.tests = tests:new(self.opts, self.project)
    self.tests:show()
  else
    self.tests:update_project(self.project)
    self.tests:refresh()
  end
end

function M:_run_target()
  local executables = self.project:get_executable()
  utils.select_from_list("Select target to run", vim.tbl_keys(executables), function(name)
    vim.cmd("botright split term://" .. executables[name].target)
  end)
end

function M:_debug_target()
  local executables = self.project:get_executable()
  utils.select_from_list("Select target to run", vim.tbl_keys(executables), function(name)
    local dap_config = {
      args = {},
      cwd = vim.uv.cwd(),
      program = executables[name].target,
      request = "launch",
      name = "Debug " .. name,
      type = self.opts:get().dap_adapter
    }

    dap.run(dap_config)
  end)
end

function M:parse_command(opts)
  local action = opts.fargs[1]
  if action == "init" then
    self:init()
  elseif action == "setup" then
    self:_meson_setup()
  elseif action == "compile" then
    self:_meson_compile()
  elseif action == "test" then
    self:_tests()
  elseif action == "log" then
    self:_show_log()
  elseif action == "run" then
    self:_run_target()
  elseif action == "debug" then
    self:_debug_target()
  elseif action == "setting" then
    self:_show_settings()
  elseif action == "log" then
    self:_show_log()
  else
    notification.notify("Mesone: invalid arguments: " .. opts.args,
      vim.log.levels.ERROR)
  end
end

function M:check_auto_build(opts)
  if not self.opts:get().auto_compile then
    return
  end
  local found = false
  for _, filename in ipairs(self.project.sources) do
    if opts.match == filename then
      found = true
      break
    end
  end
  if found then
    self:_meson_compile()
  end
end

function M:check_focused_buffer(bufnr, filename)
  if self.tests ~= nil then
    self.tests:update_buffer_signs(bufnr, filename)
  end
end

function M:on_buffer_focused(ev)
  if self.project == nil or ev.file == "" then
    return
  end
  local buffer_filename = ev.file

  if not utils.file_exists(buffer_filename) then
    return
  end
  local found = false
  for _, filename in ipairs(self.project.sources) do
    if buffer_filename == filename then
      found = true
      break
    end
  end
  if found then
    local buffer_number = vim.fn.bufnr(buffer_filename)
    if vim.fn.buflisted(buffer_number) ~= 0 and vim.api.nvim_buf_is_valid(buffer_number) then
      self:check_focused_buffer(buffer_number, buffer_filename)
    end
  end
end

function M:_show_settings()
  self.opts:ui(function(opts)
    storage.save(vim.uv.cwd(), opts)
    notification.notify("Project setting saved", vim.log.levels.INFO)
  end)
end

return M
