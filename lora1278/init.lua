clk=5
miso=6
mosi=7
cs=4
id=1
gpio.mode(clk, gpio.OUTPUT)
gpio.mode(miso, gpio.INPUT)
gpio.mode(mosi, gpio.OUTPUT)
gpio.mode(cs, gpio.OUTPUT)

spi.setup(id, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 16, spi.HALFDUPLEX)

function readreg(reg)
  gpio.write(cs, gpio.LOW)
  wrote = spi.send(id, reg)
  rdata = spi.recv(id, 1)
  gpio.write(cs, gpio.HIGH)
  return rdata
end

function writereg(reg, data)
  gpio.write(cs, gpio.LOW)
  reg=reg+0x80
  wrote = spi.send(id, reg, data)
  rdata = spi.recv(id, 1)
  gpio.write(cs, gpio.HIGH)
end

print(string.byte(readreg(0x01))..'\n')
writereg(0x01, 0x01)
print(string.byte(readreg(0x01))..'\n')
writereg(0x01, 0x09)
print(string.byte(readreg(0x01))..'\n')

print('RegTemp: '..string.format("0x%02X", string.byte(readreg(0x3C)))..'\n')

-- tx init (sleep/stdby)
-- write fifo (stdby)
-- -- Set FifoPtrAddr to FifoTxPtrBase.
-- -- Write PayloadLength bytes to the FIFO (RegFifo)
-- set mode tx
-- wait for irq txdone