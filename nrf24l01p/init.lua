-- NRF24L01 test 
dofile('regs.lua') -- regs numbers

-- HW pins
cs1=0 -- 1st NRF Chip Select
cs2=1 -- 2nd NFR Chip Select
ce1=2 -- 1st NRF Chip Enable
ce2=3 -- 2nd NRF Chip Enable

cs=cs1
ce=ce1

-- HW init
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 8);
gpio.mode(cs1, gpio.OUTPUT)
gpio.mode(ce1, gpio.OUTPUT)
gpio.write(cs1, gpio.HIGH)
gpio.write(ce1, gpio.LOW)

gpio.mode(cs2, gpio.OUTPUT)
gpio.mode(ce2, gpio.OUTPUT)
gpio.write(cs2, gpio.HIGH)
gpio.write(ce2, gpio.LOW)

---------------
-- SPI Commands
---------------

function setmodule(modulenum)
  if modulenum == 2 then
    cs=cs2
    ce=ce2
  else
    cs=cs1
    ce=ce1
  end
end

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

function readpld() -- not impl
  -- 0110 0001, 1-32 bytes, LSByte first
end

function writepld(pld) -- not impl
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

function send_data(data)
  -- PWR_UP bit set high
  -- PRIM_RX bit set low
  -- payload in the TX FIFO
  -- high pulse on the CE > 10µs
  writereg(CONFIG, 0x02) -- NO MASK, NO CRC, PWR UP, PTX
  writepld(data)
  clear_bit(STATUS, 4) -- clear MAX_RT
  gpio.write(ce, gpio.HIGH)
  tmr.delay(1)
  gpio.write(ce, gpio.LOW)
end

function recv_data()
  --PWR_UP bit, PRIM_RX bit and the CE pin set high
  writereg(0x0,0x0B)
  tmr.delay(150)
end

function init_recv()
-- page 75
-- flush rx buffer
-- data rate
-- rf channel
-- src addr

end

function init_send()
-- page 76
-- data rate
-- rf channel
-- power amp
-- dst addr

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
 print('MASK_RX_DR:\t'..get_bit(cnf,6))
 print('MASK_TX_DS:\t'..get_bit(cnf,5))
 print('MASK_MAX_RT:\t'..get_bit(cnf,4))
 print('EN_CRC:\t'..get_bit(cnf,3))
 print('CRCO:\t'..get_bit(cnf,2))
 print('PWR_UP:\t'..get_bit(cnf,1))
 print('PRIM_RX:\t'..get_bit(cnf,0))
end

function print_status()
  st=string.byte(readreg(STATUS))
  print('RX_DR:\t'..get_bit(st,6))
  print('TX_DS:\t'..get_bit(st,5))
  print('MAX_RT:\t'..get_bit(st,4))
  print('RX_P_NO:\t'..get_bit(st,3)..get_bit(st,2)..get_bit(st,1))
  print('TX_FULL:\t'..get_bit(st,0))
end

function test_regs(modnum)
-- reg #   0     1     2     3     4     5     6     7
  defs={0x08, 0x3F, 0x03, 0x03, 0x03, 0x02, 0x0E, 0x0E}
  defs_len=8
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
