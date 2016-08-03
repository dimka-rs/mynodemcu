pin=0 
gpio.mode(pin, gpio.OUTPUT)
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 0);

function printreg(reg)
  gpio.write(pin, gpio.LOW)
  spi.send(1, reg)
  read1 = spi.recv(1, 1)
  print('\nReg:'..string.format("0x%02X", reg)..'='..string.format("0x%02X", string.byte(read1)))
  gpio.write(pin, gpio.HIGH)
end

function writereg(reg, data)
  gpio.write(pin, gpio.LOW)
  tmr.delay(1000)
  spi.send(1, reg+0x20, data)
  gpio.write(pin, gpio.HIGH)
end

function setrx()
  writereg(0x0,0x0B)
  tmr.delay(150)
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

