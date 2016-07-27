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

function printreg(reg)
  gpio.write(cs, gpio.LOW)
  wrote = spi.send(id, reg)
  rdata = spi.recv(id, 1)
  gpio.write(cs, gpio.HIGH)
  print('Reg "'..string.format("0x%02X", reg)..'": '..string.format("0x%02X", string.byte(rdata)..'\n'))
end


function writereg(reg, data)
  gpio.write(cs, gpio.LOW)
  reg=reg+0x80
  wrote = spi.send(id, reg, data)
  rdata = spi.recv(id, 1)
  gpio.write(cs, gpio.HIGH)
end

-- tx init (sleep/stdby)
writereg(0x01, 0x08) -- fsk modem, sleep mode
printreg(0x01)
writereg(0x01, 0x88) -- lora modem, sleep mode
printreg(0x01)
writereg(0x01, 0x89) -- lora modem, stdby mode
printreg(0x01)
writereg(0x0E, 0x80) -- tx base address
writereg(0x0F, 0x00) -- rx base address

-- write fifo (stdby)
writereg(0x0D, 0x80) -- fifo pointer to tx base
writereg(0x00, 0x0A)
writereg(0x00, 0x0B)
writereg(0x00, 0x0C)
writereg(0x00, 0x0D)
writereg(0x0D, 0x80) -- fifo pointer to tx base
for i = 1,8 do
  printreg(0x00)
end

-- set mode tx
writereg(0x01, 0x8B) -- lora modem, tx mode
printreg(0x01)

-- wait for irq txdone
tmr.delay(100000)
printreg(0x12) -- show irq flags, 0x08 = tx done
writereg(0x12, 0xFF) -- clear all flags
printreg(0x12) -- show irq flags

-- misc
printreg(0x18) -- modem status 0x10 = modem clear
printreg(0x1D) -- modem config 1
printreg(0x1E) -- modem config 2
printreg(0x26) -- modem config 3
