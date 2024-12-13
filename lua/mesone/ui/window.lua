local function close_me(buf, win)
  if buf ~= nil and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  if win ~= nil and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

local function win_buf_autocmd(buf, win)
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = buf,
    callback = function() vim.schedule(function() close_me(buf, win) end) end
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function() vim.schedule(function() close_me(buf, win) end) end
  })
end

local M = {
  centered_window = function()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

    local width = vim.api.nvim_get_option_value("columns", { scope = "global" })
    local height = vim.api.nvim_get_option_value("lines", { scope = "global" })

    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    local opts = {
      style = "minimal",
      relative = "editor",
      width = win_width,
      height = win_height,
      row = row,
      col = col,
      border = "rounded"
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    vim.api.nvim_set_option_value("readonly",   true,  { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    win_buf_autocmd(buf, win)

    return buf, win
  end,

  panel_window = function(min_width)
    local buf = vim.api.nvim_create_buf(false, true)
    local width = vim.api.nvim_get_option_value("columns", { scope = "global" })
    local win_width = math.min(math.ceil(width * 0.2), min_width)

    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

    local opts = { style = "minimal", split = "right", win = -1, width = win_width }
    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, {})

    vim.api.nvim_set_option_value("readonly",   true,  { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    return buf, win
  end,

  popup = function(title, width, height)
    width = width or 50
    height = height or 12
    local buf = vim.api.nvim_create_buf(false, true)

    local win = vim.api.nvim_open_win(buf, true, {
      style = "minimal",
      relative = "editor",
      border = "rounded",
      title = title,
      row = math.floor(((vim.o.lines - height) / 2) - 1),
      col = math.floor((vim.o.columns - width) / 2),
      width = width,
      height = height
    })
    return buf, win
  end,

  messagebox = function(title, content, width, height)
    width = width or 120
    height = height or 24

    local max_width = vim.api.nvim_get_option_value("columns", { scope = "global" })
    local max_height = vim.api.nvim_get_option_value("lines", { scope = "global" })

    width = math.min(width, max_width * 0.8)
    height = math.min(height, max_height * 0.8)

    local buf = vim.api.nvim_create_buf(false, true)

    local win = vim.api.nvim_open_win(buf, true, {
      style = "minimal",
      relative = "editor",
      border = "rounded",
      title = title,
      row = math.floor(((vim.o.lines - height) / 2) - 1),
      col = math.floor((vim.o.columns - width) / 2),
      width = math.floor(width),
      height = math.floor(height)
    })
    vim.api.nvim_set_option_value("readonly",   false,    { buf = buf })
    vim.api.nvim_set_option_value("modifiable", true,     { buf = buf })
    vim.api.nvim_set_option_value("bufhidden",  "delete", { buf = buf })
    vim.api.nvim_set_option_value("buftype",    "nofile", { buf = buf })
    vim.api.nvim_set_option_value("filetype",   "mesone", { buf = buf })
    vim.api.nvim_set_option_value("wrap",       false,    { win = win })

    -- press 'q' or 'esc' to close window
    for _, key in ipairs({ "q", "<esc>" }) do
      vim.api.nvim_buf_set_keymap(buf, "n", key, "<cmd>close<cr>", { nowait = true, noremap = true, silent = true })
    end

    local lines = vim.split(content, "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

    vim.api.nvim_set_option_value("readonly",   true,  { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    win_buf_autocmd(buf, win)
  end
}

return M
