-- NRF24L01 test 
dofile('regs.lua') -- regs numbers

-- HW pins
cs=8 -- NRF Chip Select
ce=2 -- NRF Chip Enable

-- HW init
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
gpio.mode(cs, gpio.OUTPUT)
gpio.write(cs, gpio.HIGH)
gpio.mode(ce, gpio.OUTPUT)
gpio.write(ce, gpio.LOW)

---------------
-- SPI Commands
---------------

function readreg(reg)
  gpio.write(cs, gpio.LOW)
  spi.send(1, reg)
  val = spi.recv(1, 1)
  gpio.write(cs, gpio.HIGH)
  return val
end

function writereg(reg, data)
  gpio.write(cs, gpio.LOW)
  spi.send(1, reg+0x20, data)
  gpio.write(cs, gpio.HIGH)
end

function readpld(length)
  -- 0110 0001, 1-32 bytes, LSByte first
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0x61)
  pld = spi.recv(1, length)
  gpio.write(cs, gpio.HIGH)
  return pld
end

function writepld(pld)
  -- 1010 0000, 1 to 32 LSByte first
  gpio.write(cs, gpio.LOW)
  wrote=spi.send(1, 0xA0, pld)
  gpio.write(cs, gpio.HIGH)
  return wrote
end

function flushtx()
  --1110 0001
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0xE1)
  gpio.write(cs, gpio.HIGH)
end

function flushrx()
  --1110 0010
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0xE2)
  gpio.write(cs, gpio.HIGH)
end

function reusetxpl()
  --1110 0011
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0xE3)
  gpio.write(cs, gpio.HIGH)
end

function rrxplwid()
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0x60)
  val = spi.recv(1, 1)
  gpio.write(cs, gpio.HIGH)
  return val
  -- TODO: flush rx if val > 32
end

function wackpld() -- not impl
  -- 1010 1PPP
end

function wtxpldnoack() -- not impl
  -- 1011 0000
end

function nop() -- not imp
 -- 1111 1111
end

------------------
-- Other functions 
------------------

function get_bit(val, num)
 return (bit.isclear(val,num) and 0 or 1)
end

function clear_bit(reg, bitn)
  val=string.byte(readreg(reg))
  bit.set(val, bitn)
  writereg(reg, val)
end

function init_send()
  -- page 75
  writereg(CONFIG, 0x0E) -- EN_CRC 2 Bytes, PWRUP, PTX
  writereg(EN_AA, 0x01) -- enable autoack on pipe 0
  writereg(EN_RXADDR, 0x01) -- enable pipe 0
  writereg(SETUP_AW, 0x03) -- address width is 5 bytes
  writereg(SETUP_RETR, 0x13) -- retr in 500 us, up to 3 attempts
  writereg(RF_CH, 0x02) -- channel 2400 + 2 MHz
  writereg(RF_SETUP, 0x00) -- 1 Mbit, min power
  writereg(RX_ADDR_P0, 0xB1B2B3B4B5) -- pipe 0 rx addr
  writereg(RX_PW_P0, 8) -- payload len for pipe 0, actually prx only
  writereg(TX_ADDR, 0xB1B2B3B4B5) -- tx addr
end

function send_data(data)
  writepld(data)
  clear_bit(STATUS, 4) -- clear MAX_RT
  gpio.write(ce, gpio.HIGH)
  tmr.delay(100) -- more than 10 us
  gpio.write(ce, gpio.LOW)
end

function recv_data(timeout_us)
  writereg(CONFIG,0x0B) -- PWR_UP=1, PRIM_RX=1
  gpio.write(ce, gpio.HIGH)
  tmr.delay(timeout_us)
  gpio.write(ce, gpio.LOW)
  print_status()
end

function init_recv()
-- page 76
-- flush rx buffer
-- data rate
-- rf channel
-- src addr

end

------------------
-- Debug functions
------------------

function printreg(reg)
  rreg=readreg(reg)
  print('\nReg:'..string.format("0x%02X", reg)..'='..string.format("0x%02X", string.byte(rreg)))
end


function print_config()
 cnf=string.byte(readreg(CONFIG))
 print('MASK_RX_DR:  '..get_bit(cnf,6))
 print('MASK_TX_DS:  '..get_bit(cnf,5))
 print('MASK_MAX_RT: '..get_bit(cnf,4))
 print('EN_CRC:      '..get_bit(cnf,3))
 print('CRCO:        '..get_bit(cnf,2))
 print('PWR_UP:      '..get_bit(cnf,1))
 print('PRIM_RX:     '..get_bit(cnf,0))
end

function print_status()
  st=string.byte(readreg(STATUS))
  print('RX_DR:   '..get_bit(st,6))
  print('TX_DS:   '..get_bit(st,5))
  print('MAX_RT:  '..get_bit(st,4))
  print('RX_P_NO: '..get_bit(st,3)..get_bit(st,2)..get_bit(st,1))
  print('TX_FULL: '..get_bit(st,0))
end

function print_fifo()
  st=string.byte(readreg(FIFO_STATUS))
  print('TX_REUSE: '..get_bit(st,6))
  print('TX_FULL:  '..get_bit(st,5))
  print('TX_EMPTY: '..get_bit(st,4))
  print('RX_FULL:  '..get_bit(st,1))
  print('RX_EMPTY: '..get_bit(st,0))
end

function test_regs()
-- reg #   0     1     2     3     4     5     6     7     8     9
  defs={0x08, 0x3F, 0x03, 0x03, 0x03, 0x02, 0x0F, 0x0E, 0x00, 0x00}
  defs_len=10
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
