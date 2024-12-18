print('blub')
return {
    setup = function(opts)
        opts = opts or {}
        print('called setup')
    end,
}
