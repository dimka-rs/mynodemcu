-- i2c
id = 0
scl = 1
sda = 2
addr = 0x3C
i2c.setup(id, sda, scl, i2c.SLOW)

function read_reg(dev_addr, reg_addr)
    i2c.start(id)
    ack=i2c.address(id, dev_addr, i2c.TRANSMITTER)
    i2c.write(id, reg_addr)
    i2c.stop(id)
    i2c.start(id)
    i2c.address(id, dev_addr, i2c.RECEIVER)
    c = i2c.read(id, 1)
    i2c.stop(id)
    return c
end

i2c.start(id)
print('addr: '..i2c.address(id, addr, i2c.TRANSMITTER))
print('write: '..i2c.write(id, 0xa6))
i2c.stop(id)


for i=0,127 do
 print(string.format("0x%02X", i)..'='..string.format("0x%02X", string.byte(read_reg(addr,i))))
end 