pin=8 
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8, spi.FULLDUPLEX);
gpio.mode(pin, gpio.OUTPUT)

gpio.write(pin, gpio.LOW)
wrote, rdata = spi.send(1, 0x20, 0x08)
print(wrote, rdata)
read = spi.recv(1, 2)
print(string.byte(read))
gpio.write(pin, gpio.HIGH)
tmr.delay(100)

gpio.write(pin, gpio.LOW)
wrote, rdata, rdata2 =  spi.send(1, 0x00, 0x00) -- read 0x00
print(wrote, rdata, rdata2)
read = spi.recv(1, 2)
print(string.byte(read))
read = spi.recv(1, 2)
print(string.byte(read))
gpio.write(pin, gpio.HIGH)
tmr.delay(100)

spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, spi.DATABITS_8, 0);
gpio.write(pin, gpio.LOW)
print(spi.send(1, 0x00))
read = spi.recv(1, 2)
print(string.byte(read))
gpio.write(pin, gpio.HIGH)
tmr.delay(100)
-- 0x00 =  8 = 0000 1000
-- 0x01 = 63 = 0011 1111
-- 0x02 =  3 = 0000 0011
-- 0x03 =  3 = 0000 0011
-- 0xFF = 50 = 0011 0010
-- read = 14 = 0000 1110
