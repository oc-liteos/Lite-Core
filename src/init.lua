do
    local addr, invoke = computer.getBootAddress(), component.invoke
    
    _G.loadfile = function(file)
        local handle = assert(invoke(addr, "open", file))
        local buffer = ""
        repeat
            local data = invoke(addr, "read", handle, math.huge)
            buffer = buffer .. (data or "")
        until not data
        invoke(addr, "close", handle)
        return load(buffer, "=" .. file, "bt", _G)
    end

    _G.execute = function(file)
        local f, err = _G.loadfile(file)
        if f == nil then
            error("Cannot load '"..file.."': " .. err)
        end
        return f()
    end

    execute("/kernel/kernel.lua")
    
end