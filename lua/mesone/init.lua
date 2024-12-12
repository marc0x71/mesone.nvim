local M = {}

function M.setup(opts)
  require('mesone.app').get():setup(opts)
end

return M
