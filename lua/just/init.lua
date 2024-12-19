local M = {
    config = {},
}

---@class defaults
local defaults = {
    -- Position of the output window
    -- 'aboce', 'right', 'below', 'left'
    ---@type string
    window = 'right',
    -- Function that executes the actual just command
    -- By default it creates a terminal window, with 1/3 of the height or width of the current window, and prints the
    -- output of the just recipe in there
    ---@param just_args [string]
    runner = function(just_args)
        local current_window_handle = vim.api.nvim_get_current_win()
        local current_window_config = vim.api.nvim_win_get_config(current_window_handle)
        print(vim.inspect(current_window_config))

        local buf_handle = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_open_win(buf_handle, true, {
            win = current_window_handle,
            width = math.floor(current_window_config.width / 5 * 2),
            height = math.floor(current_window_config.height / 5 * 2),
            split = M.config.window,
        })
        vim.fn.termopen(vim.list_extend({ 'just' }, just_args))
    end,
}

---@param opts defaults
M.setup = function(opts)
    M.config = opts or {}
    M.config = vim.tbl_extend('keep', M.config, defaults)

    vim.api.nvim_create_user_command('Just', function(input)
        M.run(input.fargs)
    end, {
        nargs = '*',
        complete = M.recipes,
        desc = 'Run the justfile in the current dir',
    })
end

---@return any
M.dump = function()
    if not M.can_just_run() then
        vim.notify('No justfile found', vim.log.levels.ERROR)
        return {}
    end

    local dump = vim.system({ 'just', '--dump', '--dump-format', 'json' }, { text = true }):wait()
    return vim.fn.json_decode(dump.stdout)
end

---@return [string]
M.recipes = function()
    if not M.can_just_run() then
        vim.notify('No justfile found', vim.log.levels.ERROR)
        return {}
    end

    local recipes = {}
    local index = 1
    for a, _ in pairs(M.dump().recipes) do
        recipes[index] = a
        index = index + 1
    end
    return recipes
end

---@param just_args [string]
M.run = function(just_args)
    if not M.can_just_run() then
        vim.notify('No justfile found', vim.log.levels.ERROR)
        return
    end

    M.config.runner(just_args)
end

---@return boolean
M.can_just_run = function()
    -- try a dry-run and check the return code
    local result = vim.system({ 'just', '--dry-run' }):wait()
    return result.code == 0
end

return M
