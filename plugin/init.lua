vim.api.nvim_create_user_command("Mesone", function(opts)
  require("mesone.app").get():parse_command(opts)
end, {
  nargs = "*",
  desc = "Mesone, a NeoVim plugin for Meson build system",
  complete = function(lead, cmd, cursor)
      return require('mesone.lib.cmdparse').evaluate(lead, cmd, cursor)
    -- TODO command completer -- see :h lua-guide-commands-create
    local valid_args = { "init", "setup", "compile", "test", "run", "debug", "setting", "log" }
      print(lead, cmd, cursor)
      return {}
  end
})

local mesone_augroup = vim.api.nvim_create_augroup("mesone_augroup",
  { clear = true })

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  callback = function(_) require("mesone.app").get():init() end,
  group = mesone_augroup
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = { "*.c", "*.h", "*.cc", "*.cxx", "*.cpp", "*.C", "*.hpp", "*.jnl" },
  callback = function(opts) require("mesone.app").get():check_auto_build(opts) end,
  group = mesone_augroup
})
