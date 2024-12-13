local notification = require("fidget.notification")
local progress = require("fidget.progress")

M = { handle = nil, percentage = -1 }

M.progress = function(title, message, percentage)
  percentage = percentage or 1

  if M.handle == nil then
    M.handle = progress.handle.create({ title = title, message = message, lsp_client = { name = "Mesone" } })
    M.percentage = percentage
    return
  end

  M.handle.message = message
  if M.percentage < percentage then
    -- update percentage only if greater than previous
    M.percentage = percentage
    M.handle.percentage = percentage
  end
end

M.progress_complete = function()
  if M.handle == nil then return end

  M.handle:finish()
  M.handle = nil
  M.percentage = -1
end

M.notify = function(message, level) notification.notify(message, level) end

return M
