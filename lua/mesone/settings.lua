local default_settings = {
    build_folder = "build",
    build_type = "debug",
    info_depth = 3
}

local settings = {}

function settings:new()
    local o = {inner = vim.deepcopy(default_settings)}
    setmetatable(o, self)
    self.__index = self
    return o
end

function settings:update(opts)
    self.inner = vim.tbl_deep_extend("force", self.inner, opts or {})
end

function settings:get() return self.inner end

return settings

