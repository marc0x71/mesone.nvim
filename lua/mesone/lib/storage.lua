local utils = require("mesone.lib.utils")

local M = { path = vim.fn.stdpath("data") .. "/mesone/" }

local function _hash(folder)
  return vim.fn.sha256(folder)
end

M.load = function(folder, default)
  local saved = nil
  vim.fn.mkdir(M.path, "p")
  local filename = M.path .. _hash(folder)
  if utils.file_exists(filename) then
    local success, content = pcall(utils.read_json_file, filename)
    if success then
      saved = content
    end
  end
  return saved or vim.deepcopy(default)
end

M.save = function(folder, content)
  vim.fn.mkdir(M.path, "p")
  local filename = M.path .. _hash(folder)
  utils.create_file(filename, vim.json.encode(content))
end

return M
