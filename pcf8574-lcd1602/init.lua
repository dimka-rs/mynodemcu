-- D7 D6 D5 D4 BL  E RW RS
--  7  6  5  4  3  2  1  0
-- 4bit: High nibble first
-- RS RW Function
-- 0  0  Instruction write
-- 0  1  Status read
-- 1  0  Data write
-- 1  1  Data read

C=0
D=1
W=0
R=2
E=4
BL=8
-- 0 to off
dev=0x27
id = 0
sda = 5
scl = 6
i2c.setup(id, sda, scl, i2c.SLOW)

function lcd_init(dev)
  i2c.start(id)
  i2c.address(id, dev, i2c.TRANSMITTER)
  -- 4 bit
  i2c.write(id, 0x20)
  tmr.delay(1)
  i2c.write(id, 0x24)
  tmr.delay(1)
  i2c.write(id, 0x20)
  -- 4 bit and 2 lines
  i2c.write(id, 0x20)
  tmr.delay(1)
  i2c.write(id, 0x24)
  tmr.delay(1)
  i2c.write(id, 0x20)
  tmr.delay(1)
  i2c.write(id, 0x80)
  tmr.delay(1)
  i2c.write(id, 0x84)
  tmr.delay(1)
  i2c.write(id, 0x80)
  tmr.delay(1)
  -- turn on
  i2c.write(id, 0x00)
  tmr.delay(1)
  i2c.write(id, 0x04)
  tmr.delay(1)
  i2c.write(id, 0x00)
  tmr.delay(1)
  i2c.write(id, 0xE0)
  tmr.delay(1)
  i2c.write(id, 0xE4)
  tmr.delay(1)
  i2c.write(id, 0xE0)
  tmr.delay(1)
  -- set mode
  i2c.write(id, 0x00)
  tmr.delay(1)
  i2c.write(id, 0x04)
  tmr.delay(1)
  i2c.write(id, 0x00)
  tmr.delay(1)
  i2c.write(id, 0x60)
  tmr.delay(1)
  i2c.write(id, 0x64)
  tmr.delay(1)
  i2c.write(id, 0x60+BL)
  tmr.delay(1)
  i2c.stop(id)
end

function lcd_set_cgram(dev, addr)
  -- line1: 0x00...0x27 => 0x80...0xA7
  -- line2: 0x40...0x67 => 0xC0...0xE7
  lcd_write(dev, addr+64, C, W)
end

function lcd_clear(dev)
  lcd_write(dev, 0x01, C, W)
end

function lcd_home(dev)
  lcd_write(dev, 0x02, C, W)
end

function lcd_home2(dev)
  lcd_write(dev, 0xC0, C, W)
end

function get_nibbles(byte)
  if (byte > 255) then
    byte = byte % 255
  end
  high = math.floor(byte/16)*16
  low = math.floor(byte%16)*16
  return high, low
end

function lcd_write(dev, byte, rs, rw)
  high, low = get_nibbles(byte)
  high = high + rs + rw + BL
  high_e = high + E
  low = low + rs + rw + BL
  low_e = low + E
  i2c.start(id)
  i2c.address(id, dev, i2c.TRANSMITTER)
  i2c.write(id, high)
  tmr.delay(1)
  i2c.write(id, high_e)
  tmr.delay(1)
  i2c.write(id, high)
  tmr.delay(1)
  i2c.write(id, low)
  tmr.delay(1)
  i2c.write(id, low_e)
  tmr.delay(1)
  i2c.write(id, low)
  tmr.delay(1)
  i2c.stop(id)
end

function lcd_string(dev, str)  
  for i = 1, #str do
    local c = string.byte(str,i)
    lcd_write(dev, c, D, W)
  end
end

str1='Hello, world!'
str2='#Nodemcu#ESP8266'
function lcd_test()
  lcd_clear(0x27)
  lcd_home(0x27)
  lcd_string(0x27, str1)
  lcd_home2(0x27)
  lcd_string(0x27, str2)
end

function lcd_test2()
  lcd_clear(dev)
  lcd_home(dev)
  for i = 0, 14 do
    lcd_home(dev)
    for j = 0, 15 do
      lcd_write(dev, i*16+j, D, W)
    end
    lcd_home2(dev)
    for j = 0, 15 do
      lcd_write(dev, (i+1)*16+j, D, W)
    end
    tmr.delay(5000000)
  end
end
