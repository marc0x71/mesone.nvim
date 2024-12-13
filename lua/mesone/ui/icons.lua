local M = {}

local icons = { ok = "✓", running = "󱦟", failed = "✗", skipped = "⚐", unknown = "?" }

function M.status_icon(status)
  local icon = icons.unknown
  if status == "run" then
    icon = icons.ok
  elseif status == "running" then
    icon = icons.running
  elseif status == "fail" then
    icon = icons.failed
  elseif status == "skipped" then
    icon = icons.skipped
  end
  return icon
end

return M
