local form = require("mesone.ui.form")

local default_settings = {
  build_folder = "build",
  build_type = "debug",
  info_depth = 3,
  show_command_logs = false,
  auto_compile = true,
  dap_adapter = "gdb",
}

local M = {}

function M:new(opts)
  local o = { inner = opts or vim.deepcopy(default_settings), myform = nil }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:update(opts)
  self.inner = vim.tbl_deep_extend("force", self.inner, opts or {})
end

function M:get()
  return self.inner
end

function M:ui(on_changed)
  if self.myform == nil then
    self.myform = form:new({
      fields = {
        build_folder = {},
        build_type = {
          "plain",
          "debug",
          "debugoptimized",
          "release",
          "minsize",
          "custom",
        },
        info_depth = {},
        show_command_logs = { true, false },
        auto_compile = { true, false },
        dap_adapter = {},
      },
    })
  end
  self.myform:show("Mesone project settings", self.inner, function(conf)
    if conf ~= nil then
      self.inner = vim.deepcopy(conf)
      on_changed(conf)
    end
  end)
end

return M
