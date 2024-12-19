local M = {}

M.setup = function(opts)
    opts = opts or {}
    vim.api.nvim_create_user_command('Just', function(input)
        M.run(input.fargs)
    end, {
        nargs = '*',
        complete = function() -- has optional varargs
            return M.recipes()
        end,
        desc = 'Just',
    })
end

M.dump = function()
    if not M.can_just_run() then
        vim.notify('No justfile found', vim.log.levels.ERROR)
        return {}
    end

    local dump = vim.system({ 'just', '--dump', '--dump-format', 'json' }, { text = true }):wait()
    return vim.fn.json_decode(dump.stdout)
end

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

M.run = function(just_args)
    if not M.can_just_run() then
        vim.notify('No justfile found', vim.log.levels.ERROR)
        return
    end

    local args = vim.list_extend({ 'just' }, just_args)
    if vim.api.nvim_get_option_value('modified', { buf = vim.api.nvim_get_current_buf() }) then
        vim.api.nvim_command([[new]])
    end
    vim.fn.termopen(args)
end

M.can_just_run = function()
    -- try a dry-run and check the return code
    local result = vim.system({ 'just', '--dry-run' }):wait()
    return result.code == 0
end

return M
