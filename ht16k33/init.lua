-- i2c
id = 0
dev = 0x70
sda = 5
scl = 6
i2c.setup(id, sda, scl, i2c.SLOW)

function ht16k33_init()
  i2c.start(id)
  i2c.address(id, dev, i2c.TRANSMITTER)
  i2c.write(id, 0x21) --Active
  i2c.stop(id)
  tmr.delay(1)
  
  i2c.start(id)
  i2c.address(id, dev, i2c.TRANSMITTER)
  i2c.write(id, 0xA0) --Row
  i2c.stop(id)
  tmr.delay(1)
  
  i2c.start(id)
  i2c.address(id, dev, i2c.TRANSMITTER)
  i2c.write(id, 0x81) --On
  i2c.stop(id)
end

function ht16k33_demo()
  i2c.start(id)
  i2c.address(id, dev, i2c.TRANSMITTER)
  i2c.write(id, 0x00) --addr
  for i=0,7 do
    i2c.write(id, 0xAA) --data
    i2c.write(id, 0x55) --data
    tmr.delay(100000)
  end
  i2c.stop(id)
  --tmr.delay(1000000)
  i2c.start(id)
  i2c.address(id, dev, i2c.TRANSMITTER)
  i2c.write(id, 0x00) --addr
  for i=0,7 do
    i2c.write(id, 0x55) --data
    i2c.write(id, 0xAA) --data
    tmr.delay(100000)
  end
  i2c.stop(id)
  --tmr.delay(1000000)
end