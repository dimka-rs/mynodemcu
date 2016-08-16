clk=5
miso=6
mosi=7
cs=1
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
  print('\nReg "'..string.format("0x%02X", reg)..'": '..string.format("0x%02X", string.byte(rdata)..'\n\n'))
end

function writereg(reg, data)
  gpio.write(cs, gpio.LOW)
  reg=reg+0x80
  wrote = spi.send(id, reg, data)
  gpio.write(cs, gpio.HIGH)
end

function lora_init()
  writereg(0x01, 0x08) -- fsk modem, sleep mode
  writereg(0x01, 0x88) -- lora modem, sleep mode
  writereg(0x01, 0x89) -- lora modem, stdby mode
  writereg(0x0E, 0x80) -- tx base address
  writereg(0x0F, 0x00) -- rx base address
end

function load_payload(len)
  writereg(0x0D, 0x80) -- fifo pointer to tx base
  for i=1,len do
    writereg(0x00, i+48)
  end
end

function lora_send(len)
  writereg(0x22, len) -- RegPayloadLength  
  writereg(0x01, 0x8B) -- lora modem, tx mode
  tmr.delay(100000) -- wait for irq txdone
  irq=string.byte(readreg(0x12)) -- show irq flags, 0x08 = tx done
  if irq==0x08 then
    print('Tx Done:'..string.format("0x%02X", irq))
  else
    print('Tx ERROR:'..string.format("0x%02X", irq))
  end
end

-- START
payload_len=8
lora_init()

tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()    
  print('Load payload, size='..tostring(payload_len))
  load_payload(payload_len)
  print('Send data, size='..tostring(payload_len))
  lora_send(payload_len)
  end)
