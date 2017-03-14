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
  print('Test module. Reg 0x42 must read 0x12.')
  printreg(0x42)
  writereg(0x01, 0x08) -- fsk modem, sleep mode
  writereg(0x01, 0x88) -- lora modem, sleep mode
  writereg(0x01, 0x89) -- lora modem, stdby mode
  -- 6c8000 - 434 MHz, D90024 - 868 MHz
  writereg(0x06, 0xd9) -- lora modem, stdby mode
  writereg(0x07, 0x00) -- lora modem, stdby mode
  writereg(0x08, 0x24) -- lora modem, stdby mode
  writereg(0x09, 0xff) -- MAX POWER!!!
  writereg(0x0E, 0x80) -- tx base address
  writereg(0x0F, 0x00) -- rx base address
  writereg(0x1D, 0x72) -- BW125kHz,CR4/5,ExplHdr (Def: 0x72)
  writereg(0x1E, 0x74) -- SF7,CRCon (Def: 0x70)
  writereg(0x22, payload_len) -- RegPayloadLength  
end

function load_payload(data)
  writereg(0x0D, 0x80) -- fifo pointer to tx base
  payload=string.format('%08d', data)
  writereg(0x00, payload)
  print('Payload:'..payload)
end

function lora_send()
  writereg(0x01, 0x8B) -- lora modem, tx mode
  gpio.write(pin, gpio.LOW)
  tmr.delay(100000) -- wait for irq txdone
  irq=string.byte(readreg(0x12)) -- show irq flags, 0x08 = tx done
  if irq==0x08 then
    print('Tx Done:'..string.format("0x%02X", irq))
    gpio.write(pin, gpio.HIGH)
  else
    print('Tx ERROR:'..string.format("0x%02X", irq))
  end
end

-- START
pktcnt=1
payload_len=8 -- mind format in load_payload
lora_init()
pin=4
gpio.mode(pin, gpio.OUTPUT)

tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()
  load_payload(pktcnt)
  lora_send(payload_len)
  pktcnt=pktcnt+1
  end)

--RegFifoRxCurrentAddr
-- generate init file
--file.remove("init.lua");
--file.open("init.lua","w+");
--w = file.writeline
--w('dofile("tx-test.lua")');
--file.close();

