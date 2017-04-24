CLK=5
DAT=6
LED=4
MAX=25 -- 25 - A128, 26 - B32, 27 - A64

gpio.mode(DAT, gpio.INPUT)
gpio.mode(CLK, gpio.OUTPUT)
gpio.write(CLK, gpio.LOW)
gpio.mode(LED, gpio.OUTPUT)

tmr.alarm(0, 1000, tmr.ALARM_AUTO, function ()
  gpio.write(LED, gpio.LOW)
  if gpio.read(DAT) == 0 then
    result=''
    for i=1,MAX do
      gpio.write(CLK, gpio.HIGH)
      gpio.write(CLK, gpio.LOW)
      result=result..tostring(gpio.read(DAT))
    end
  print('Done '..tmr.time())
  print('123456789012345678901234567890')
  print(result)
  end
  gpio.write(LED, gpio.HIGH)
end)
