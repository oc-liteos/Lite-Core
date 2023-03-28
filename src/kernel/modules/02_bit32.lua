local bit = {}

k.printk(k.L_INFO, " - 02_bit32")


-------------------------------------------------------------------------------

local function fold(init, op, ...)
  local result = init
  local args = table.pack(...)
  for i = 1, args.n do
    result = op(result, args[i])
  end
  return result
end

local function trim(n)
  return n & 0xFFFFFFFF
end

local function mask(w)
  return ~(0xFFFFFFFF << w)
end

function bit.arshift(x, disp)
  return x // (2 ^ disp)
end

function bit.band(...)
  return fold(0xFFFFFFFF, function(a, b) return a & b end, ...)
end

function bit.bnot(x)
  return ~x
end

function bit.bor(...)
  return fold(0, function(a, b) return a | b end, ...)
end

function bit.btest(...)
  return bit.band(...) ~= 0
end

function bit.bxor(...)
  return fold(0, function(a, b) return a ~ b end, ...)
end

local function fieldargs(f, w)
  w = w or 1
  assert(f >= 0, "field cannot be negative")
  assert(w > 0, "width must be positive")
  assert(f + w <= 32, "trying to access non-existent bits")
  return f, w
end

function bit.extract(n, field, width)
  local f, w = fieldargs(field, width)
  return (n >> f) & mask(w)
end

function bit.replace(n, v, field, width)
  local f, w = fieldargs(field, width)
  local m = mask(w)
  return (n & ~(m << f)) | ((v & m) << f)
end

function bit.lrotate(x, disp)
  if disp == 0 then
    return x
  elseif disp < 0 then
    return bit.rrotate(x, -disp)
  else
    disp = disp & 31
    x = trim(x)
    return trim((x << disp) | (x >> (32 - disp)))
  end
end

function bit.lshift(x, disp)
  return trim(x << disp)
end

function bit.rrotate(x, disp)
  if disp == 0 then
    return x
  elseif disp < 0 then
    return bit.lrotate(x, -disp)
  else
    disp = disp & 31
    x = trim(x)
    return trim((x >> disp) | (x << (32 - disp)))
  end
end

function bit.rshift(x, disp)
  return trim(x >> disp)
end

-------------------------------------------------------------------------------

_G.bit32 =  bit32 or bit 