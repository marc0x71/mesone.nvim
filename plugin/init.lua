vim.api.nvim_create_user_command("Mesone", function(opts)
    require('mesone.app').get():parse_command(opts)
end, {
    nargs = "*",
    desc = "Mesone, a NeoVim plugin for Meson build system",
    complete = function(_, _, _)
        -- TODO command completer -- see :h lua-guide-commands-create
    end
})

local mesone_augroup = vim.api.nvim_create_augroup("mesone_augroup",
                                                   {clear = true})

vim.api.nvim_create_autocmd({"VimEnter", "DirChanged"}, {
    callback = function(_) require('mesone.app').get():init() end,
    group = mesone_augroup
})

