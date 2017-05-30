-- NRF24L01 test 
dofile('regs.lua') -- regs numbers
dofile('debug.lua') -- debug functions

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
PAYLOAD_LEN=32

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
  pld = {}
  spi.send(1, 0x61)
  for i=1,length do
    table.insert(pld, spi.recv(1, 1))
  end
  gpio.write(cs, gpio.HIGH)
  flushrx()
  clear_flags()
  return pld
end

function writepld(pld) -- W_TX_PAYLOAD: 1010 0000, 1 to 32 LSByte first
  gpio.write(cs, gpio.LOW)
  spi.send(1, 0xA0)
  for k,v in pairs(pld) do spi.send(1, v) end
  gpio.write(cs, gpio.HIGH)
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

function send_data(pld)
  writepld(pld)
  clear_flags()
  gpio.write(ce, gpio.HIGH)
  tmr.delay(100000) -- more than 10 us
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

function starttx()
  init_send()
  tmr.alarm(0, 5000, tmr.ALARM_AUTO, function()
  uptime=string.format("%08d", tmr.time())
  pld={}
  uptime:gsub(".",function(c) table.insert(pld, c) end)
  for k,v in pairs(pld) do print(k, v) end
  send_data(pld)
  end)
end

function startrx()
  init_recv()
  gpio.write(ce, gpio.HIGH)
  tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()
  print('.')
  r=bit.band(string.byte(readreg(STATUS)), 0x70)
  if r > 0 then print_payload(PAYLOAD_LEN) end
  end)
end
