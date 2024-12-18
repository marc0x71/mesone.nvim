# mesone.nvim
Simple NeoVim plugin for [Meson Build](https://mesonbuild.com/) system integration

![output](https://github.com/user-attachments/assets/9d963bf4-4ec3-4577-9296-ece69883f633)

# Description
Mesone is a NeoVim plugin that will allow you (easily) to manage your workflow with [Meson Build System](https://mesonbuild.com/) directly from your favorite editor.

You will be able to perform the `setup` of your project simply by pressing a button, as well as `compile` it or maybe run your tests.

You will also be able to debug your tests and even your applications, directly from NeoVim thanks to the help of `nvim-dap`, or perform the compilation of your code automagically when you save your changes!

So what are you waiting for? Install it and enjoy! 😀

## Requirements

This plugin requires:

- [`fidget.nvim`](https://github.com/j-hui/fidget.nvim) to show notification messages and execution progress.
- [`nvim-dap`](https://github.com/mfussenegger/nvim-dap) for debugging targets and tests
- [`telescope`](https://github.com/nvim-telescope/telescope.nvim) used for UI selections
- [`plenary`](https://github.com/nvim-lua/plenary.nvim) used also for async jobs

> [!NOTE]
> You also must have `meson` installed on your machine, please follow [this guide](https://mesonbuild.com/Quick-guide.html)

## Installation

You can use your preferred package manager, the following example is based on [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
  {
    'marc0x71/mesone.nvim',
    lazy = false,
    opts = {
      build_folder = "build",
      build_type = "debugoptimized",
      dap_adapter = "gdb",
      show_command_logs = false,
      auto_compile = true
    },
    dependencies = {
      "j-hui/fidget.nvim",
      "mfussenegger/nvim-dap",
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { '<leader>mi', '<cmd>Mesone init<cr>',             desc = "Initialize Mesone plugin" },
      { '<leader>ms', '<cmd>Mesone setup<cr>',            desc = "Initialize Meson project" },
      { '<leader>mc', '<cmd>Mesone compile<cr>',          desc = "Compile project" },
      { '<leader>mt', '<cmd>Mesone test<cr>',             desc = "Show tests" },
      { '<leader>mr', '<cmd>Mesone run<cr>',              desc = "Run target" },
      { '<leader>md', '<cmd>Mesone debug<cr>',            desc = "Debug target" },
      { '<leader>ml', '<cmd>Mesone log<cr>',              desc = "Show last log" },
      { '<leader>mS', '<cmd>Mesone project settings<cr>', desc = "Project settings" },
    }
  },
```

> [!NOTE]
> `Mesone` must be configured disabling *lazy* if you want auto-commands works at startup without using `lua require('mesone')`

## Configuration

`Mesone` comes with the following default configuration:

```lua
{
    -- Path used to compile
    build_folder = "build", 
    -- Default build type is 'debug', but can be: plain, debug,
    -- debugoptimized, release, minsize, custom
    build_type = "debug",
    -- The dap adapter used for debugging
    dap_adapter = "gdb",
    -- Show always meson log window
    show_command_logs = false,
    -- Automatically compile project if a source file has been changed
    auto_compile = false
}
```

You can overwrite using `setup` function or via `opts` if you are using [`lazy.nvim`](https://github.com/folke/lazy.nvim):

## Available Commands

You can execute Mesone in `command-mode` writing `:Mesone <action>` 

|Actions|Description|
|-|-|
|init|Initialize project. `build.meson` *must be* present in he current folder. This command is executed automatically on current folder change|
|setup|Execute `meson setup` command to configure the project|
|compile|Execute `meson compile` command to build the project|
|log|Show last `meson` execution log|
|test|Show all test cases found (show next paragraph for available shortcuts)|
|run|Run target|
|debug|Run target in debug (using DAP)|

The Mesone plugin will help you to compose the command via the auto-completion 😊

## Tests

Using `Mesone` you can easily execute test, the following keyboard shortcut are available:

- `r` - execute selected test
- `d` - debug selected test
- `l` - show last log of selected test
- `<CR>` - go to the source code of selected test
- `q` or `<ESC>` - close the testcases window

In the test source code a sign will appear, in the definition, which will indicate the status of the last execution

![test_signs](https://github.com/user-attachments/assets/53dfe22a-f214-4896-8f6c-b2afadc907b6)

Currently only for the following test framework is supported the "go-to" feature and test signs:

- [`GTest`](https://github.com/google/googletest)
- [`Catch2`](https://github.com/catchorg/Catch2)

## Troubleshooting

If this plugin isn't working, feel free to make an issue or a pull request.

