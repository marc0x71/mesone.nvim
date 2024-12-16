local M = {
  command = {
    Mesone = {
      init = {}, setup = {}, compile = {}, test = {}, run = {}, debug = {}, setting = {}, log = {}
    }
  }
}

M.evaluate = function(lead, cmd, cursor)
  local current = M.command
  local last_word = nil
  for word in cmd:gmatch("%S+") do
    if current[word] == nil then
      last_word = word
      break
    end
    current = current[word]
  end
  local available = {}
  if last_word ~= nil then
    for key, _ in pairs(current) do
      if vim.startswith(key, last_word) then
        table.insert(available, key)
      end
    end
  else
    for key, _ in pairs(current) do
      table.insert(available, key)
    end
  end
  return available
end

return M
