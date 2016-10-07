-- NRF24L01 test 
CONFIG_REG=0x00

csn=0 -- SPI Chip Select
ce=2  -- NFR Chip Enable
gpio.mode(csn, gpio.OUTPUT)
gpio.mode(ce, gpio.OUTPUT)
gpio.write(csn, gpio.HIGH)
gpio.write(ce, gpio.LOW)
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);

function readreg(reg)
  gpio.write(csn, gpio.LOW)
  tmr.delay(10)
  spi.send(1, reg)
  val = spi.recv(1, 1)
  gpio.write(csn, gpio.HIGH)
  return val
end

function printreg(reg)
  rreg=readreg(reg)
  print('\nReg:'..string.format("0x%02X", reg)..'='..string.format("0x%02X", string.byte(rreg)))
  
end

function writereg(reg, data)
  gpio.write(csn, gpio.LOW)
  tmr.delay(100)
  spi.send(1, reg+0x20, data)
  gpio.write(csn, gpio.HIGH)
end

function setrx()
  writereg(0x0,0x0B)
  tmr.delay(150)
end


function test_regs()
-- reg #   0     1     2     3     4     5     6     7
  defs={0x08, 0x3F, 0x03, 0x03, 0x03, 0x02, 0x0E, 0x0E}
  defs_len=8
  for i=1, defs_len do
    val=string.byte(readreg(i-1))
    if val == defs[i] then
      res="OK  "
    else
      res="Fail"
    end
    print("Reg "..tostring(i-1).." - ".. res.." reads "..val.."\tmust be "..defs[i])
  end
end

-- default values
-- 0x00 =  8 = 0x08 = 0000 1000
-- 0x01 = 63 = 0x3F = 0011 1111
-- 0x02 =  3 = 0x03 = 0000 0011
-- 0x03 =  3 = 0x03 = 0000 0011
-- 0x04 =  3 = 0x03 = 0000 0011
-- 0x05 =  2 = 0x02 = 0000 0010
-- 0x06 = 14 = 0x0E = 0000 1110
-- 0x07 = 14 = 0x0E = 0000 1110
-- 0xFF = 50 = 0x32 = 0011 0010

