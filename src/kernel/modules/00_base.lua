local screen = component.list("screen", true)()
k.gpu = screen and component.list("gpu", true)()
k.screen = { y = 1, x = 1 }

if k.gpu then 
    k.gpu = component.proxy(k.gpu)

    if k.gpu then
        if not k.gpu.getScreen() then 
            k.gpu.bind(screen)
        end

        local w, h = k.gpu.getResolution()

        k.screen.w = w
        k.screen.h = h

        k.gpu.setResolution(w, h)
        k.gpu.setForeground(0xFFFFFF)
        k.gpu.setBackground(0x000000)
        k.gpu.fill(1, 1, w, h, " ")
    end
end
if computer.getArchitecture() ~= "Lua 5.3" then
    error("Failed to Boot: OS requires Lua 5.3")
    _G.computer.shutdown()
end
-- _G.lib.loadfile("/system/kernel/stdlib.lua")()

function k.write(msg, newLine)
    msg = msg == nil and "" or msg
    newLine = newLine == nil and true or newLine
    if  k.gpu then
        local sw, sh = k.gpu.getResolution() 

        k.gpu.set(k.screen.x, k.screen.y, msg)
        if k.screen.y == sh and newLine == true then
            k.gpu.copy(1, 2, sw, sh - 1, 0, -1)
            k.gpu.fill(1, sh, sw, 1, " ")
        else
            if newLine then
                k.screen.y = k.screen.y + 1
            end
        end
        if newLine then
            k.screen.x = 1
        else
            k.screen.x = k.screen.x + string.len(msg)
        end
    end
end
k.L_EMERG   = 0
k.L_ALERT   = 1
k.L_CRIT    = 2
k.L_ERROR   = 3
k.L_WARNING = 4
k.L_SUCCESS = 5
k.L_INFO    = 6
k.L_NOTICE  = 7
k.L_DEBUG   = 8
k.cmdline = {}
k.cmdline.loglevel = 5

local reverse = {}
for name,v in pairs(k) do
    if name:sub(1,2) == "L_" then
        reverse[v] = name:sub(3)
    end
end

function k.printk(level, fmt, ...)
    checkArg(1, level, "number")
    local message = string.format("[%08.02f] %s: ", computer.uptime(),
        reverse[level]) .. string.format(fmt, ...)

    if level <= k.cmdline.loglevel then
        k.write(message)
    end

    -- log_to_buffer(message)
end

-- k.printk(k.L_INFO, "Booting...")
k.printk(k.L_INFO, "Loading Modules...")
k.printk(k.L_INFO, " - 00_base")


function k.scall(func, ...)
    checkArg(1, func, "function")
    local c = coroutine.create(func)
    local result = table.pack(coroutine.resume(c, ...))
    local ok = result[1]
    table.remove(result, 1)
    return ok, result[1]
end

k.panic = function(e)

    k.printk(k.L_EMERG, "#### stack traceback ####")

    for line in e:gsub("\t", "    "):gmatch("[^\n]+") do
        if line ~= "stack traceback:" then
            k.printk(k.L_EMERG, "%s", line)
        end
    end

    k.printk(k.L_EMERG, "#### end traceback ####")
    k.printk(k.L_EMERG, "kernel panic - not syncing")
    while true do coroutine.yield() end
end
