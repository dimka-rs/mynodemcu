-- NRF24L01 test 
dofile('regs.lua') -- regs numbers

-- HW pins
cs=1 -- NRF Chip Select
ce=2 -- NRF Chip Enable

-- HW init
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 16);
gpio.mode(cs, gpio.OUTPUT)
gpio.write(cs, gpio.HIGH)
gpio.mode(ce, gpio.OUTPUT)
gpio.write(ce, gpio.LOW)

-- constants
PAYLOAD_LEN=8

---------------
-- SPI Commands
---------------

function readreg(reg) -- R_REGISTER: 000A AAAA, 1-5 LSByte first
  gpio.write(cs, gpio.LOW)
  spi.send(1, reg)
  val = spi.recv(1, 1)
  gpio.write(cs, gpio.HIGH)
  return val
end

function read5reg(reg) -- R_REGISTER: 000A AAAA, 1-5 LSByte first
  gpio.write(cs, gpio.LOW)
  spi.send(1, reg)
  val=spi.recv(1, 5)
  gpio.write(cs, gpio.HIGH)
  return val
end

function writereg(reg, data) -- W_REGISTER: 001A AAAA, 1-5 LSByte first
  gpio.write(cs, gpio.LOW)
  spi.send(1, reg+0x20, data)
  gpio.write(cs, gpio.HIGH)
end

function write5reg(reg, data1, data2, data3, data4, data5) -- W_REGISTER: 001A AAAA, 1-5 LSByte first
  gpio.write(cs, gpio.LOW)
  spi.send(1, reg+0x20, data1, data2, data3, data4, data5)
  gpio.write(cs, gpio.HIGH)
end

function readpld(length) -- R_RX_PAYLOAD: 0110 0001, 1-32 LSByte first
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0x61)
  pld = spi.recv(1, length)
  gpio.write(cs, gpio.HIGH)
  return pld
end

function writepld(p1) -- W_TX_PAYLOAD: 1010 0000, 1 to 32 LSByte first
  gpio.write(cs, gpio.LOW)
  wrote=spi.send(1, 0xA0, 0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x63, 0x64)
  gpio.write(cs, gpio.HIGH)
  return wrote
end

function flushtx() -- FLUSH_TX: 1110 0001
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0xE1)
  gpio.write(cs, gpio.HIGH)
end

function flushrx() -- FLUSH_RX: 1110 0010
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0xE2)
  gpio.write(cs, gpio.HIGH)
end

function reusetxpl() -- REUSE_TX_PL: 1110 0011
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0xE3)
  gpio.write(cs, gpio.HIGH)
end

function rrxplwid() -- R_RX_PL_WID: 0110 0000
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0x60)
  val = spi.recv(1, 1)
  gpio.write(cs, gpio.HIGH)
  return val
  -- TODO: flush rx if val > 32
end

function wackpld(pipe) -- W_ACK_PAYLOAD: 1010 1PPP, 1 to 32 LSByte first
  -- pipe 000 to 101
  -- not impl
end

function wtxpldnoack() -- W_TX_PAYLOAD_NOACK: 1011 0000, 1 to 32 LSByte first
  -- not impl
end

function nop() -- NOP: 1111 1111, shifts out STATUS
  -- not imp
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

function wait_flag()
  -- while true
  -- read status
  -- and 0x70
  -- break if > 0
end

function clear_flags()
  clear_bit(STATUS, 6) -- clear RX_DR
  clear_bit(STATUS, 5) -- clear TX_DS
  clear_bit(STATUS, 4) -- clear MAX_RT
end

function init_common()
  writereg(SETUP_AW, 0x03) -- address width is 5 bytes
  writereg(SETUP_RETR, 0x5A) -- retr in 1500 us, up to 10 attempts
  writereg(RF_CH, 0x4C) -- channel 2400 + 76 MHz
  writereg(RF_SETUP, 0x03) -- 1 Mbit, -12 dBm, dontcare=1
  --writereg(0x50, 0x73) -- some magic dumped from arduino
  writereg(FEATURE, 0x00) -- disable all features
  writereg(DYNPD, 0x00) -- disable dynamic payload
  writereg(EN_AA, 0x03) -- enable autoack on pipe 0,1
end

function init_send()
  init_common()
  -- page 75
  writereg(CONFIG, 0x0E) -- EN_CRC 2 Bytes, PWRUP, PTX
  write5reg(TX_ADDR, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5) -- tx addr
  write5reg(RX_ADDR_P0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5) -- pipe 0 rx addr
  writereg(RX_PW_P0, PAYLOAD_LEN) -- payload len for pipe 0
  writereg(EN_RXADDR, 0x01) -- enable pipe 0
  flushtx()
end

function send_data()
  writepld(1)
  clear_flags()
  gpio.write(ce, gpio.HIGH)
  tmr.delay(1000000) -- more than 10 us
  gpio.write(ce, gpio.LOW)
  print_status()
  print_observe()
  flushtx()
end

function init_recv()
  init_common()
  -- page 76
  writereg(CONFIG, 0x0F) -- EN_CRC 2 Bytes, PWRUP, PRX
  write5reg(RX_ADDR_P1, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5) -- pipe 1 rx addr
  writereg(RX_PW_P1, PAYLOAD_LEN) -- payload len for pipe 1
  writereg(EN_RXADDR, 0x02) -- enable pipe 1
  flushtx()
end

function recv_data(timeout_us)
  clear_flags()
  gpio.write(ce, gpio.HIGH)
  tmr.delay(timeout_us)
  gpio.write(ce, gpio.LOW)
  print_status()
  print_fifo()
end

------------------
-- Debug functions
------------------

function printreg(reg)
  rreg=readreg(reg)
  print('\nReg:'..string.format("0x%02X", reg)..'='..string.format("0x%02X", string.byte(rreg)))
end

function print5reg(reg)
  rreg=read5reg(reg)
  rr='0x'
  for i=1,5 do
    rr=rr..string.format("%02X", string.byte(rreg,i))
  end
  print('\nReg:'..string.format("0x%02X", reg)..'='..rr)
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

function print_observe()
  st=string.byte(readreg(OBSERVE_TX))
  print('PLOS_CNT: '..get_bit(st,7)..get_bit(st,6)..get_bit(st,5)..get_bit(st,4))
  print('ARC_CNT:  '..get_bit(st,3)..get_bit(st,2)..get_bit(st,1)..get_bit(st,0))
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
