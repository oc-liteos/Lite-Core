local vm = execute("/vm/cpu.lua")

k = {}

execute("/kernel/modules/00_base.lua")
execute("/kernel/modules/01_util.lua")
execute("/kernel/modules/02_bit32.lua")

function test1()
    local cpu = vm.create()
    cpu.bus[0x8000] = 0x40 -- JSR $0x6000
    cpu.bus[0x8001] = 0x00
    cpu.bus[0x8002] = 0x60
    cpu.bus[0x6000] = 0x42 -- HLT
    cpu:execute()
    assert(cpu.pc ==  0x6001, string.format("Invalid PC Value: 0x%x", cpu.pc))
    assert(cpu.sp == 0xFD, string.format("Invalid SP Value: 0x%x", cpu.sp))
    k.printk(k.L_INFO, "[SUCCESS] Test1")
    cpu:destroy()
end

function test2()
    local cpu = vm.create()
    cpu.bus[0x8000] = 0x40 -- JSR $0x6000
    cpu.bus[0x8001] = 0x00
    cpu.bus[0x8002] = 0x60
    cpu.bus[0x6000] = 0x41
    cpu.bus[0x8003] = 0x00 -- NOP
    cpu.bus[0x8004] = 0x42 -- HLT
    cpu:execute()
    assert(cpu.pc ==  0x8005, string.format("Invalid PC Value: 0x%x", cpu.pc))
    assert(cpu.sp == 0xFF, string.format("Invalid SP Value: 0x%x", cpu.sp))
    k.printk(k.L_INFO, "[SUCCESS] Test2")
    cpu:destroy()
end

function test3()
    local cpu = vm.create()
    cpu.bus[0x8000] = 0x04 -- LOD A $0x55
    cpu.bus[0x8001] = 0x01
    cpu.bus[0x8002] = 0x55
    cpu.bus[0x8003] = 0x42 -- HLT
    cpu:execute()
    assert(cpu.pc ==  0x8004, string.format("Invalid PC Value: 0x%x", cpu.pc))
    assert(cpu.A == 0x55, string.format("Invalid SP Value: 0x%x", cpu.sp))
    k.printk(k.L_INFO, "[SUCCESS] Test3")
    cpu:destroy()
end

function test4()
    local cpu = vm.create()
    cpu.bus[0x8000] = 0x05 -- LOD A $0x55
    cpu.bus[0x8001] = 0x01
    cpu.bus[0x8002] = 0x00
    cpu.bus[0x8003] = 0x60
    cpu.bus[0x8004] = 0x42 -- HLT

    cpu.bus[0x6000] = 0x55
    cpu:execute()
    assert(cpu.pc ==  0x8005, string.format("Invalid PC Value: 0x%x", cpu.pc))
    assert(cpu.A == 0x55, string.format("Invalid SP Value: 0x%x", cpu.sp))
    k.printk(k.L_INFO, "[SUCCESS] Test4")
    cpu:destroy()
end

function test5()
    local cpu = vm.create()
    cpu.bus[0x8000] = 0x05 -- LOD A, #0x6000
    cpu.bus[0x8001] = 0x01
    cpu.bus[0x8002] = 0x00
    cpu.bus[0x8003] = 0x60
    cpu.bus[0x8004] = 0x08 -- STO A, #0x7000
    cpu.bus[0x8005] = 0x01
    cpu.bus[0x8006] = 0x00
    cpu.bus[0x8007] = 0x70
    cpu.bus[0x8008] = 0x42 -- HLT

    cpu.bus[0x6000] = 0x55
    cpu:execute()
    assert(cpu.pc ==  0x8009, string.format("Invalid PC Value: 0x%x", cpu.pc))
    assert(cpu.bus[0x7000] == 0x55, string.format("Invalid SP Value: 0x%x", cpu.sp))
    k.printk(k.L_INFO, "[SUCCESS] Test5")
    cpu:destroy()
end

test1()
test2()
test3()
test4()
test5()

while true do
    -- k.printk(k.L_INFO, "TEST")
    k.printk(k.L_INFO, string.format("%.3fkb", (computer.totalMemory() - computer.freeMemory()) / 1024))
    computer.pullSignal(0.5)
end