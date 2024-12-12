local function _file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function _sortedKeys(query, sortFunction)
    local keys = {}
    for k, _ in pairs(query) do table.insert(keys, k) end
    table.sort(keys, sortFunction)
    return keys
end

local function _read_all(filename)
    local f = io.open(filename, "r")
    if f == nil then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function _read_file(filename, callback)
    if _file_exists(filename) then
        for line in io.lines(filename) do callback(line) end
    end
end

local M = {
    file_exists = function(name) return _file_exists(name) end,

    create_file = function(name, content)
        content = content or ''
        local f = io.open(name, "w")
        if not f then
            print("unexpected error creating ", name)
            return false
        end
        f:write(content)
        f:close()
        return true
    end,

    get_path = function(path, sep)
        sep = sep or '/'
        return path:match("(.*" .. sep .. ")")
    end,

    read_all = function(filename) return _read_all(filename) end,

    read_file = function(filename, callback) _read_file(filename, callback) end,

    read_json_file = function(filename)
        return vim.json.decode(_read_all(filename) or "null",
                               {luanil = {object = true, array = true}})
    end,

    buf_append_colorized = function(buf, content, content_type)
        vim.api.nvim_buf_set_lines(buf, -1, -1, true, {content})
        local row = vim.api.nvim_buf_line_count(buf)
        local highlight = 'Normal'
        if content_type == "err" or content_type == "fail" then
            highlight = 'DiagnosticError'
        elseif content_type == "skipped" then
            highlight = 'DiagnosticInfo'
        elseif content_type == "run" then
            highlight = 'DiagnosticOk'
        elseif content_type == "start" or content_type == "end" then
            highlight = 'Title'
        end
        vim.api.nvim_buf_add_highlight(buf, -1, highlight, row - 1, 0,
                                       content:len())
        return row
    end,

    idict = function(tbl)
        local keys = {}
        for k in next, tbl do table.insert(keys, k) end
        return function(_, i)
            i = i + 1
            local k = keys[i]
            if k then return i, k, tbl[k] end
        end, keys, 0
    end,

    trim = function(s)
        if s == nil then return "" end
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end,

    orderedPairs = function(t) return _sortedKeys(t) end,

    select_from_list = function(title, list, callback, opts)
        local action_state = require("telescope.actions.state")
        local actions = require("telescope.actions")
        local conf = require("telescope.config").values
        local finders = require("telescope.finders")
        local pickers = require("telescope.pickers")

        opts = opts or {}

        pickers.new(opts, {
            prompt_title = title,
            finder = finders.new_table({results = list}),
            layout_config = {
                width = function(_, max_columns)
                    local percentage = 0.5
                    local max = 50
                    return math.min(math.floor(percentage * max_columns), max)
                end,
                height = function(_, _, max_lines)
                    local percentage = 0.3
                    local min = 15
                    return math.max(math.floor(percentage * max_lines), min)
                end
            },
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection ~= nil then
                        callback(selection[1])
                    end
                end)
                return true
            end
        }):find()
    end,

    split = function(str, sep)
        local lines = {}
        for s in str:gmatch("[^" .. sep .. "]+") do
            table.insert(lines, s)
        end
        return lines
    end,

    concat_array = function(table1, table2)
        for i = 1, #table2 do table1[#table1 + 1] = table2[i] end
        return table1

    end,

    remove_prefix = function(str, prefix)
        return (string.sub(str, 0, #prefix) == prefix) and
                   string.sub(str, #prefix + 1) or str
    end,

    is_failure_message = function(str)
        return string.match(str:lower(), "error") or
                   string.match(str:lower(), "failed")
    end

}

return M

