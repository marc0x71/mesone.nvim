vim.api.nvim_create_user_command("Mesone", function(opts)
    require('mesone.app').get():parse_command(opts)
end, {
    nargs = "*",
    desc = "Mesone, a NeoVim plugin for Meson build system",
    complete = function(_, _, _)
        -- TODO command completer -- see :h command-completion-customlist
    end
})

