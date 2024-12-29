---@diagnostic disable: duplicate-set-field
local present, fidget = pcall(require, "fidget")
if present then
  local notification = fidget.notification
  local progress_fdg = fidget.progress

  M = { handle = nil, percentage = -1 }

  M.progress = function(title, message, percentage)
    percentage = percentage or 1

    if M.handle == nil then
      M.handle = progress_fdg.handle.create({ title = title, message = message, lsp_client = { name = "Mesone" } })
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
    if M.handle == nil then
      return
    end

    M.handle:finish()
    M.handle = nil
    M.percentage = -1
  end

  M.notify = function(message, level)
    notification.notify(message, level)
  end

  return M
else
  M = {}
  M.progress = function(_, _, _) end
  M.progress_complete = function() end
  M.notify = function(_, _) end
  return M
end
