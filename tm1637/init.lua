id = 0
scl = 1
sda = 2
gpio.mode(scl, gpio.OUTPUT)
gpio.mode(sda, gpio.OUTPUT)
i2c.setup(id, sda, scl, i2c.SLOW)


function i2c_discover()
  for i = 0, 127 do
    i2c.start(id)
    ack = i2c.address(id, i, i2c.RECEIVER)
    print(string.format('0x%02X', i)..': '..tostring(ack))
    i2c.stop(id)
  end
end

function test_me()
i2c.start(id)
i2c.write(id, 0x42) -- read data
keys = i2c.read(id, 0x1)
i2c.stop(id)

i2c.start(id)
i2c.write(id, 0x40) -- write data
i2c.stop(id)

i2c.start(id)
i2c.write(id, 0xC0) -- set addr to 0x00
i2c.write(id, 0xAA) -- write data 0
i2c.write(id, 0x55) -- write data 1
i2c.write(id, 0xAA) -- write data 2
i2c.write(id, 0x55) -- write data 3
i2c.write(id, 0xAA) -- write data 4
i2c.write(id, 0x55) -- write data 5
i2c.stop(id)

i2c.start(id)
i2c.write(id, 0x8c) -- ctl display
i2c.stop(id)
end

