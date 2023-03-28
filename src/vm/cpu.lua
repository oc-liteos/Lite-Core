local constants = loadfile("/vm/constants.lua")()
local cpu = {}

local function byte(a) return bit32.band(a, 0xFF) end
local function word(a) return bit32.band(a, 0xFFFF) end

cpu.createBus = function()
    local memory = {}
    for i = 0, constants.MAX_ADDRESS do
        memory[i] = 0
    end
    return memory
end

cpu.create = function()
    local data = {
        pc = 0x0000,
        sp = 0x00,
        A = 0,
        B = 0,
        C = 0,
        D = 0,
        flags = {
            C = false,
            Z = false,
            G = false,
            E = false,
            I = false,
            B = false,
            O = false,
            N = false,
        }, 
        bus = cpu.createBus()
    }
    data.pc = 0x8000
    data.sp = 0xFF
    return setmetatable(data, {
        __index = cpu
    })
end

-- function cpu:reset()
-- end

function cpu:fetchByte()
    local data = self:readByte(self.pc)
    self.pc = word(self.pc + 1)
    return data
end

function cpu:fetchWord()
    local data = self:fetchByte()
    data = bit32.bor(bit32.lshift(self:fetchByte(), 8), data)
    return data
end

function cpu:readByte(addr)
    return self.bus[word(addr)]
end

function cpu:loadRegister(id, v)
    if id == 1 then
        self.A = byte(v)
    elseif id == 2 then
        self.B = byte(v)
    elseif id == 3 then
        self.C = byte(v)
    elseif id == 4 then
        self.D = byte(v)
    elseif id == 9 then
        self.sp = byte(v)
    else
        error("Invalid Register")
    end
end

function cpu:sign_ext(value, bits)
    local sign_bit = bit32.lshift(1, bits - 1)
    return bit32.band(value, sign_bit - 1) - bit32.band(value, sign_bit)
end

function cpu:getRegister(id)
    if id == 1 then
        return byte(self.A)
    elseif id == 2 then
        return byte(self.B)
    elseif id == 3 then
        return byte(self.C)
    elseif id == 4 then
        return byte(self.D)
    elseif id == 9 then
        return byte(self.sp)
    else
        error("Invalid Register")
    end
end

function cpu:execute()
    local running = true
    while running do
        local ins = self:fetchByte()
        -- k.write(dump(ins))
        if ins == 0x00 then -- NOP
        elseif ins == 0x04 then -- LOD
            local r = self:fetchByte()
            local value = self:fetchByte()
            self:loadRegister(r, value)
        elseif ins == 0x05 then -- LOD
            local r = self:fetchByte()
            local addr = self:fetchWord()
            local value = self:readByte(addr)
            self:loadRegister(r, value)
        elseif ins == 0x08 then -- STO
            local v = self:getRegister(self:fetchByte())
            local addr = self:fetchWord()
            assert(0 <= addr and addr <= 0xFFFF, tostring(addr))
            self.bus[addr] = v
        elseif ins == 0x0c then -- JMP
            self.pc = self:fetchWord()
        elseif ins == 0x10 then -- CMP
            local v = self:fetchByte()
            if v == byte(self.A) then self.flags.E = true end
            if v > byte(self.A) then self.flags.G = true end
            if bit32.band(v, 128) ~= 0 then self.flags.N = true end

        elseif ins == 0x14 then -- BEQ
            local offset = self:sign_ext(self:fetchByte(), 8)
            if self.flags.E then self.pc = self.pc + offset end
        elseif ins == 0x18 then -- BNE
            local offset = self:sign_ext(self:fetchByte(), 8)
            if not self.flags.E then self.pc = self.pc + offset end
        elseif ins == 0x19 then -- BZ
            local offset = self:sign_ext(self:fetchByte(), 8)
            if self.flags.Z then self.pc = self.pc + offset end
        elseif ins == 0x1a then -- BGT
            local offset = self:sign_ext(self:fetchByte(), 8)
            if self.flags.G then self.pc = self.pc + offset end
        elseif ins == 0x1b then -- BN
            local offset = self:sign_ext(self:fetchByte(), 8)
            if self.flags.N then self.pc = self.pc + offset end
        elseif ins == 0x1c then -- BC
            local offset = self:sign_ext(self:fetchByte(), 8)
            if self.flags.C then self.pc = self.pc + offset end
        elseif ins == 0x1d then -- BO
            local offset = self:sign_ext(self:fetchByte(), 8)
            if self.flags.O then self.pc = self.pc + offset end
        
        elseif ins == 0x20 then -- PSH <u8>
            local value = self:fetchByte()
            self.bus[0x0100 + byte(self.sp)] = value
            self.sp = byte(self.sp - 1)
        elseif ins == 0x21 then -- PSH <R>
            local value = byte(self:getRegister(self:fetchByte()))         
            self.bus[0x0100 + byte(self.sp)] = value
            self.sp = byte(self.sp - 1)
        elseif ins == 0x24 then -- POP <R>
            local r = self:fetchByte()
            self.sp = byte(self.sp + 1)
            self:loadRegister(r, self.bus[self.sp])

        elseif ins == 0x28 then -- ADD
            local value = self:getRegister(self:fetchByte())          
            self.A = self.A + value
            self.flags.O = self.A > 255
            self.A = byte(self.A)

            self.flags.Z = self.A == 0
            self.flags.C = bit32.band(self.A, 128) ~= 0
        elseif ins == 0x29 then -- SUB
            local value = self:getRegister(self:fetchByte())          
            self.A = self.A - value
            self.flags.O = self.A > 255
            self.A = byte(self.A)

            self.flags.C = bit32.band(self.A, 128) ~= 0
            self.flags.Z = self.A == 0
        elseif ins == 0x2a then -- ADC
            local value = self:getRegister(self:fetchByte())          
            self.A = self.A + value
            if self.flags.C then self.A = self.A + 1 end
            self.flags.O = self.A > 255
            self.A = byte(self.A)

            self.flags.C = bit32.band(self.A, 128) ~= 0
            self.flags.Z = self.A == 0

        elseif ins == 0x2c then -- AND
            local value = self:getRegister(self:fetchByte())          
            self.A = byte(bit32.band(self.A, value))
        elseif ins == 0x2d then -- OR
            local value = self:getRegister(self:fetchByte())          
            self.A = byte(bit32.bor(self.A, value))
        elseif ins == 0x2e then -- NOT
            self.A = byte(bit32.bnot(self.A))

        elseif ins == 0x30 then -- Left Rotate Register
            local v = self:getRegister(self:fetchByte())
            self.A = byte(bit32.lrotate(self.A, v))
        elseif ins == 0x33 then -- Left Rotate u8
            local v = self:fetchByte()
            self.A = byte(bit32.lrotate(self.A, v))
        elseif ins == 0x31 then -- right rotate register
            local v = self:getRegister(self:fetchByte())
            self.A = byte(bit32.rrotate(self.A, v))
        elseif ins == 0x34 then -- right rotate u8
            local v = self:fetchByte()
            self.A = byte(bit32.rrotate(self.A, v))

        elseif ins == 0x34 then -- Left shift Register
            local v = self:getRegister(self:fetchByte())
            self.A = byte(bit32.lshift(self.A, v))
        elseif ins == 0x36 then -- Left shift u8
            local v = self:fetchByte()
            self.A = byte(bit32.lshift(self.A, v))
        elseif ins == 0x35 then -- right shift register
            local v = self:getRegister(self:fetchByte())
            self.A = byte(bit32.rshift(self.A, v))
        elseif ins == 0x37 then -- right shift u8
            local v = self:fetchByte()
            self.A = byte(bit32.rshift(self.A, v))

        elseif ins == 0x38 then -- TR
            local v = self:getRegister(self:fetchByte())
            self:loadRegister(self:fetchByte(), v)
        elseif ins == 0x39 then -- SF
            local v = self:fetchByte()
            self.flags.C = bit32.band(v, 1) ~= 0
            self.flags.Z = bit32.band(v, 2) ~= 0
            self.flags.G = bit32.band(v, 4) ~= 0
            self.flags.E = bit32.band(v, 8) ~= 0
            self.flags.I = bit32.band(v, 16) ~= 0
            self.flags.B = bit32.band(v, 32) ~= 0
            self.flags.O = bit32.band(v, 64) ~= 0
            self.flags.N = bit32.band(v, 128) ~= 0
        elseif ins == 0x3c then -- INT
            error("Interupts not enabled!")
        elseif ins == 0x40 then -- JSR
            local addr = self:fetchWord()
            self.bus[0x0100 + byte(self.sp)] = bit32.band(self.pc + 1, 0x00FF)
            self.sp = byte(self.sp - 1)
            self.bus[0x0100 + byte(self.sp)] = bit32.rshift(bit32.band(self.pc + 1, 0xFF00), 8)
            self.sp = byte(self.sp - 1)
            self.pc = addr
        elseif ins == 0x41 then -- RTS
            self.sp = byte(self.sp + 1)
            local h = self.bus[0x0100 + self.sp]
            self.sp = byte(self.sp + 1)
            local l = self.bus[0x0100 + self.sp]
            self.pc = bit32.bor(bit32.lshift(h, 8), l)
            -- error(dump(self.pc))
        elseif ins == 0x42 then
            break
        else
            error(string.format("Invalid Instruction %s at 0x%x", tostring(ins), self.pc))
        end
    end
end

function cpu:destroy()
    self.bus = nil
    self.A = nil
    self.B = nil
    self.C = nil
    self.D = nil
    self.flags = nil
    self.sp = nil
    self.pc = nil
end
return cpu