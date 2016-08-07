-- lora registers
RegFifo     = 0x00
RegOpMode   = 0x01
RegFrMsb    = 0x06
RegFrMid    = 0x07
RegFrLsb    = 0x08
RegPaConfig = 0x09
RegPaRamp   = 0x0A
RegOcp      = 0x0B
RegLna      = 0x0C
RegFifoAddrPtr    = 0x0D
RegFifoTxBaseAddr = 0x0E
RegFifoRxBaseAddr = 0x0F
RegFifoRxCurrAddr = 0x10
RegIrqFlagMask    = 0x11
RegIrqFlags  = 0x12
RegRxNbBytes = 0x13
RegRxHeaderCntValueMsb = 0x14
RegRxHeaderCntValueLsb = 0x15
RegRxPacketCntValueMsb = 0x16
RegRxPacketCntValueLsb = 0x17
RegModemStat    = 0x18
RegPktSnrValue  = 0x19
RegPktRssiValue = 0x1A
RegRssiValue    = 0x1B
RegHopChannel   = 0x1C
RegModemConfig  = 0x1D
RegModemConfig2 = 0x1E
RegSymbTimeoutLsb = 0x1F
RegPreambleMsb    = 0x20
RegPreambleLsb    = 0x21
RegPayloadLength  = 0x22
RegMaxPayloadLength = 0x23
RegHopPeriod        = 0x24
RegFifoRxByteAddr = 0x25
RegModemConfig3   = 0x26
RegFeiMsb = 0x28
RegFeiMid = 0x29
RegFeiLsb = 0x2A
RegRssiWideband = 0x2C
RegDetectOptimize = 0x31
RegInvertIQ = 0x33
RegDetectionThreshold = 0x37
RegSyncWord = 0x39

function init_spi()
  clk=5
  miso=6
  mosi=7
  cs=3
  id=1
  gpio.mode(clk, gpio.OUTPUT)
  gpio.mode(miso, gpio.INPUT)
  gpio.mode(mosi, gpio.OUTPUT)
  gpio.mode(cs, gpio.OUTPUT)
  spi.setup(id, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 16, spi.HALFDUPLEX)
end

function init_i2c_display()
    -- SDA and SCL can be assigned freely to available GPIOs
    local sda = 2 -- GPIO14
    local scl = 1 -- GPIO12
    local sla = 0x3c
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
    disp:begin()
end

function prepare_display()
    disp:firstPage()
    disp:setFont(u8g.font_6x10r)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
end

function readreg(reg)
  gpio.write(cs, gpio.LOW)
  wrote = spi.send(id, reg)
  rdata = spi.recv(id, 1)
  gpio.write(cs, gpio.HIGH)
  return string.byte(rdata)
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

function lora_set_mode(mode)
  if mode=='SLEEP' then writereg(RegOpMode,0x88) end
  if mode=='STDBY' then writereg(RegOpMode,0x89) end
  if mode=='FSTX'  then writereg(RegOpMode,0x8A) end
  if mode=='TX'    then writereg(RegOpMode,0x8B) end
  if mode=='FSRX'  then writereg(RegOpMode,0x8C) end
  if mode=='RXC'   then writereg(RegOpMode,0x8D) end
  if mode=='RXS'   then writereg(RegOpMode,0x8E) end
  if mode=='CAD'   then writereg(RegOpMode,0x8F) end
end

function lora_reset_ptr_rx()
  lora_set_mode('STDBY')
  base_addr=readreg(RegFifoRxBaseAddr)
  writereg(RegFifoAddrPtr, base_addr)
end

function lora_get_rssi()
  v = readreg(RegRssiValue)
  return string.byte(v) - 157
end

function lora_get_flags()
 flags=readreg(RegIrqFlags)
 if bit.isset(flags, 7) then b7='RT' else b7='rt' end
 if bit.isset(flags, 6) then b6='RD' else b6='rd' end
 if bit.isset(flags, 5) then b5='CE' else b5='ce' end
 if bit.isset(flags, 4) then b4='VH' else b4='vh' end
 if bit.isset(flags, 3) then b3='TD' else b3='td' end
 if bit.isset(flags, 2) then b2='CD' else b2='cd' end
 if bit.isset(flags, 1) then b1='CC' else b1='cc' end
 if bit.isset(flags, 0) then b0='CT' else b0='ct' end
 flags=b7..b6..b5..b4..b3..b2..b1..b0
 return flags
end

-- start
init_i2c_display()
prepare_display()
init_spi()
lora_set_mode('SLEEP')
lora_reset_ptr_rx()
for i=1, 60 do
  tmr.delay(700000)
  rssi=tostring(lora_get_rssi())
  flags=lora_get_flags()
  print('RSSI: '..rssi..', ST: '..flags)
  disp:firstPage()
  repeat
    disp:drawStr(0, 0, 'RSSI: '..rssi)
    disp:drawStr(0, 10, 'ST: '..flags)
    disp:drawStr(0, 20, 'I: '..i)
  until disp:nextPage() == false
end
