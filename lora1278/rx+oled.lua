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
    local sda = 2
    local scl = 1
    local sla = 0x3c
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
    disp:begin()
end

function prepare_display()
    disp:firstPage()
    disp:setFont(u8g.font_6x10)
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
  base_addr=readreg(RegFifoRxBaseAddr)
  writereg(RegFifoAddrPtr, base_addr)
  print('Ptr set to '..string.format('0x0%X', base_addr))
end

function lora_get_rxcdr()
   cdr=readreg(RegModemStat)/32+4 -- 4/cdr., 5-8
   return cdr
end

function lora_get_rssi()
  v = readreg(RegRssiValue)
  return string.byte(v) - 157 -- LF:-164, HF:-157
end

function lora_get_pkt_rssi()
  v = readreg(RegPktRssiValue)
  return string.byte(v) - 157 -- LF:-164, HF:-157
end

function lora_get_pkt_snr()
  v=readreg(RegPktSnrValue)
--  return (256-v)/4 -- https://github.com/mayeranalytics/pySX127x/blob/master/SX127x/LoRa.py :478
  if v > 127 then v=v-256 end
  return v/4
end

function lora_get_flags()
  flags=readreg(RegIrqFlags)
  return flags
end

function print_flags()
 flags=readreg(RegIrqFlags)
 if bit.isset(flags, 7) then b7='RT' else b7='rt' end --RxTimeout
 if bit.isset(flags, 6) then b6='RD' else b6='rd' end --RxDone
 if bit.isset(flags, 5) then b5='CE' else b5='ce' end --CrcError
 if bit.isset(flags, 4) then b4='VH' else b4='vh' end --ValidHeader
 if bit.isset(flags, 3) then b3='TD' else b3='td' end --TxDone
 if bit.isset(flags, 2) then b2='CD' else b2='cd' end --CadDone
 if bit.isset(flags, 1) then b1='CC' else b1='cc' end --FhssChangeChannel
 if bit.isset(flags, 0) then b0='CT' else b0='ct' end --CadDetected
 flags=b7..b6..b5..b4..b3..b2..b1..b0
 return flags
end

-- init
init_i2c_display()
prepare_display()
init_spi()
lora_set_mode('SLEEP')
lora_set_mode('STDBY')
lora_reset_ptr_rx()
-- 868 MHz - 0xd90024
writereg(0x06, 0xd9)
writereg(0x07, 0x00)
writereg(0x08, 0x24)
writereg(0x0C, 0x20) -- lna gain. Def: 0x20 - max.
writereg(0x1D, 0x72) -- BW,CR,ImplHdr. Def: 0x72
writereg(0x1E, 0xC0) -- dis crc, SF7. Def: 0x70
lora_set_mode('RXC')

pktnum=0
pktsnr=0
pktrssi=0
pktlen=0
pktdata=''
pktdata2=''
pktdata3=''
pktdata4=''
crcerr=true

-- START
tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()    
  flags=lora_get_flags()
  if bit.isset(flags, 6) then
    print('Rx Done!')
    crcerr = bit.isset(flags, 5)
    pktnum=pktnum+1
    if pktnum > 999 then pktnum = 0 end
    print('RxCdr:'..tostring(lora_get_rxcdr()))
    pktsnr=lora_get_pkt_snr()
    pktrssi=lora_get_pkt_rssi()
    pktlen=readreg(RegRxNbBytes)
    rxcurr=readreg(RegFifoRxCurrAddr)
    writereg(RegFifoAddrPtr, rxcurr)
    print('Set fifo ptr to '..string.format('0x%X',rxcurr))
    print('Compare to '..string.format('0x%X', (readreg(RegFifoRxByteAddr)-pktlen)))
    pktdata4=pktdata3
    pktdata3=pktdata2
    pktdata2=pktdata
    pktdata=string.format('%3d ', pktnum)
    for i=1, pktlen do
      byte=string.char(readreg(RegFifo))
      pktdata=pktdata..byte
      --if i%4 == 0 then pktdata=pktdata..' ' end --separate groups of 4 with spaces
    end
    print('Data:'..pktdata)
    writereg(RegIrqFlags, 0xFF)
  end
  -- get draw data
  rssi=tostring(lora_get_rssi())
  print('Rssi:'..rssi)
  mode=readreg(RegOpMode)
  if crcerr then crcstr=' ER' else crcstr=' OK' end
  if s == 'rssi' then s='RSSI' else s='rssi' end
  -- draw screen
  disp:firstPage()
  repeat
    disp:drawStr(0,  0, s..'  PKT SNR LEN CRC')
    disp:drawStr(0, 10, string.format('%4d %4d %3d %3d %s', rssi, pktrssi, pktsnr, pktlen, crcstr))
    disp:drawStr(0, 20, pktdata)
    disp:drawStr(0, 30, pktdata2)
    disp:drawStr(0, 40, pktdata3)
    disp:drawStr(0, 50, pktdata4)
  until disp:nextPage() == false
end)

-- generate init file
--file.remove("init.lua");
--file.open("init.lua","w+");
--w = file.writeline
--w('dofile("rx+oled.lua")');
--file.close();
