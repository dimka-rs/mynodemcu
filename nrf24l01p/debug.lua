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

function print_payload(length)
  pld=readpld(length)
  for i, v in ipairs(pld) do print(i, tostring(v)) end
end