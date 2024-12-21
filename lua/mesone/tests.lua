local ntf = require("mesone.lib.notification")
local utils = require("mesone.lib.utils")
local window = require("mesone.ui.window")
local icons = require("mesone.ui.icons")
local testcases = require("mesone.testcases.testcase")
local signs = require("mesone.lib.signs")
local M = {}

function M:new(opts, project)
  local log_filename = os.tmpname()
  local o = {
    project = project or nil,
    log_filename = log_filename,
    opts = opts,
    buf = nil,
    win = nil,
    last_position = 0,
    test_links = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:_close_me()
  if self.buf ~= nil and vim.api.nvim_buf_is_valid(self.buf) then
    vim.api.nvim_buf_delete(self.buf, {})
    self.buf = nil
    self.win = nil
  end
end

function M:_set_keymaps()
  for _, key in ipairs({ "q", "<esc>" }) do
    vim.api.nvim_buf_set_keymap(self.buf, "n", key, "", {
      nowait = true,
      noremap = true,
      silent = true,
      callback = function()
        self:_close_me()
      end,
    })
  end
  vim.api.nvim_buf_set_keymap(self.buf, "n", "<enter>", "", {
    nowait = true,
    noremap = true,
    silent = true,
    callback = function()
      self:_goto_test()
    end,
  })
  vim.api.nvim_buf_set_keymap(self.buf, "n", "r", "", {
    nowait = true,
    noremap = true,
    silent = true,
    callback = function()
      self:_run_test()
    end,
  })
  vim.api.nvim_buf_set_keymap(self.buf, "n", "d", "", {
    nowait = true,
    noremap = true,
    silent = true,
    callback = function()
      self:_debug_test()
    end,
  })
  vim.api.nvim_buf_set_keymap(self.buf, "n", "R", "", {
    nowait = true,
    noremap = true,
    silent = true,
    callback = function()
      self:_run_all_tests()
    end,
  })
  vim.api.nvim_buf_set_keymap(self.buf, "n", "l", "", {
    nowait = true,
    noremap = true,
    silent = true,
    callback = function()
      self:_log_test()
    end,
  })
end

function M:_get_selected()
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  self.last_position = r
  if r > vim.tbl_count(self.test_links) then
    return nil
  end
  if vim.tbl_isempty(self.test_links[r]) then
    return nil
  end
  return self.test_links[r]
end

function M:_log_test()
  local test = self:_get_selected()
  if test == nil then
    return
  end
  if vim.tbl_isempty(test.test_list) or test.test_list[1].output == nil then
    ntf.notify("No log found for test " .. test.name, vim.log.levels.WARN)
    return
  end
  if vim.tbl_count(test.test_list) > 1 then
    ntf.notify(test.name .. " is a suite, please select single testcase to view log", vim.log.levels.WARN)
    return
  end
  window.messagebox(test.test_list[1].name, test.test_list[1].output)
end

function M:_run_all_tests()
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  self.last_position = r
  for _, testsuite in ipairs(self.project.tests) do
    testcases.run(testsuite, function(results)
      self.project:update_test_result(results)
      vim.schedule(function()
        self:_show_tests_status()
        vim.api.nvim_win_set_cursor(self.win, { self.last_position, 0 })
      end)
    end)
  end
end

function M:_run_test()
  local test = self:_get_selected()
  if test == nil then
    return
  end
  testcases.run(test, function(results)
    self.project:update_test_result(results)
    vim.schedule(function()
      self:_show_tests_status()
      vim.api.nvim_win_set_cursor(self.win, { self.last_position, 0 })
      self:_update_signs_all_buffers()
    end)
  end)
end

function M:_debug_test()
  local test = self:_get_selected()
  if test == nil then
    return
  end
  if vim.tbl_count(test.test_list) > 1 then
    ntf.notify(test.name .. " is a suite, please select single testcase to debug", vim.log.levels.WARN)
    return
  end
  self:_close_me()
  testcases.debug(test, self.opts:get().dap_adapter)
end

function M:_goto_test()
  local test = self:_get_selected()
  if test == nil then
    return
  end
  if not vim.api.nvim_win_is_valid(self.main_window) then
    ntf.notify("Main window has been close, please try again")
    pcall(vim.api.nvim_win_close, 0, true)
    self:_close_me()
    return
  end
  vim.api.nvim_set_current_win(self.main_window)

  if vim.tbl_count(test.test_list) > 1 then
    for _, testcase in ipairs(test.test_list) do
      if testcase.filename ~= nil then
        vim.cmd("edit " .. vim.fn.fnameescape(testcase.filename))
      end
    end
  else
    if test.test_list[1].filename ~= nil then
      vim.cmd("edit " .. vim.fn.fnameescape(test.test_list[1].filename) .. "|" .. test.test_list[1].line)
    end
  end
end

function M:_show_tests_status()
  self.test_links = {}
  if self.project == nil then
    self:_close_me()
    ntf.notify("No test found", vim.log.levels.WARN)
    return
  end

  local max_len = self.project:get_max_testcase_len() + 3

  vim.api.nvim_set_option_value("modifiable", true, { buf = self.buf })
  vim.api.nvim_set_option_value("readonly", false, { buf = self.buf })

  utils.buf_append_colorized(self.buf, { "Test suite", string.rep("󰇜", max_len), "" }, "start", true)
  table.insert(self.test_links, {})
  table.insert(self.test_links, {})
  table.insert(self.test_links, {})
  for _, testsuite in ipairs(self.project.tests) do
    utils.buf_append_colorized(self.buf, testsuite.name, "target", false)
    table.insert(self.test_links, testsuite)
    for _, test in ipairs(testsuite.test_list) do
      utils.buf_append_colorized(self.buf, icons.status_icon(test.status) .. " " .. test.name, test.status, false)
      table.insert(
        self.test_links,
        { test_list = { test }, name = testsuite.name, cmd = testsuite.cmd, type = testsuite.type }
      )
    end
  end
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = self.buf })
end

function M:show()
  if self.project == nil then
    self:_close_me()
    ntf.notify("No test found", vim.log.levels.WARN)
    return
  end
  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then
    local max_len = self.project:get_max_testcase_len() + 3
    self.main_window = vim.api.nvim_get_current_win()

    self.buf, self.win = window.panel_window(max_len)

    vim.api.nvim_set_option_value("buftype", "nofile", { buf = self.buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = self.buf })

    self:_set_keymaps()

    self:_show_tests_status()
  end
end

function M:update_project(project)
  self.project = project
  if self.buf ~= nil and vim.api.nvim_buf_is_valid(self.buf) then
    self:_show_tests_status()
  end
end

function M:refresh()
  if self.buf == nil or not vim.api.nvim_buf_is_valid(self.buf) then
    self:show()
  else
    self:_show_tests_status()
  end
end

function M:_update_signs_all_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local filename = vim.api.nvim_buf_get_name(bufnr)
    self:update_buffer_signs(bufnr, filename)
  end
end

function M:update_buffer_signs(bufnr, filename)
  if self.project == nil then
    return
  end
  if self.project.tests_status[filename] == nil then
    return
  end
  signs.show_sign(bufnr, self.project.tests_status[filename])
end

return M
