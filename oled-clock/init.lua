id   = 0
sda  = 1
scl  = 2
rtc  = 0x51
oled = 0x3c
eeprom = 0x53 -- or 0x57 if B0 is high

function i2c_print_slaves()
  for i=0x00,0x7F do
    i2c.start(id)
    ack=i2c.address(id, i, i2c.RECEIVER)
    if ack==true then print("ACK: "..string.format('0x%02X',i)) end
    i2c.stop(id)
  end
end

function init_rtc()
  i2c.start(id)
  ack=i2c.address(id, rtc, i2c.TRANSMITTER)
  print("RTC ACK sla: "..tostring(ack))
  ack=i2c.write(0, 0x00)
  print("RTC ACK addr: "..tostring(ack))
  ack=i2c.write(0, 0x58)
  print("RTC ACK rst: "..tostring(ack))
  i2c.stop(id)
end

function init_i2c()
    -- SDA and SCL can be assigned freely to available GPIOs
    gpio.mode(sda, gpio.OUTPUT)
    gpio.mode(scl, gpio.OUTPUT)
    i2c.setup(id, sda, scl, i2c.SLOW)
end

function init_display()
    i2c.start(id)
    ack=i2c.address(id, oled, i2c.RECEIVER)
    print("LCD ACK: "..tostring(ack))
    i2c.stop(id)
    disp = u8g.ssd1306_128x64_i2c(oled)
    disp:begin()
    disp:firstPage()
    --font_6x10r,font_fub49n,font_freedoomr25n
    disp:setFont(u8g.font_freedoomr25n)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
    disp:setRot180()
end

function read_rtc()
    local a = {}
    i2c.start(id)
    ack=i2c.address(id, rtc, i2c.TRANSMITTER)
    print("RTC ACK: "..tostring(ack))
    i2c.write(id, 0x00)
    i2c.stop(id)
    i2c.start(id)
    ack=i2c.address(id, rtc, i2c.RECEIVER)
    for i=1,11 do
      a = string.byte(i2c.read(0, 1))
      print(tostring(i)..': '..string.format('0x%02X', a))
    end
    i2c.stop(id)
    return a
end

function draw_logo()
-- xbm converter: http://www.online-utility.org/image/convert/to/MONO
  file.open("irz-big.MONO", "r")
  xbm_data = file.read()
  file.close()
  disp:firstPage()
  repeat
    disp:drawXBM(0, 0, 128, 65, xbm_data)
  until disp:nextPage() == false
end

function draw_time()
  disp:firstPage()
  repeat
    disp:drawStr(15,  20, t)
  until disp:nextPage() == false
end

-- init
init_i2c()
init_display()
--init_rtc()
--read_rtc()

s=0   -- state: time or logo
h=12  -- hours
m=34  -- minutes
d=':' -- delimeter
c=0   -- seconds
t=''  -- time string

--[[
-- Config WiFi and sync time
wifi.setmode(wifi.STATION)
wifi.sta.config("myssid", "password")
tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()   
  ip = wifi.sta.getip()
  if ip ~= nil then
    print('Got ip: '..ip)
    sntp.sync()
  end
end)
--]]


-- MAIN LOOP
tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()   
  c=c+1
  if c > 59 then
    c=0
    m=m+1
    if m > 59 then
      m=0
      h=h+1
      if h > 23 then
        h=0
      end
    end
  end
  if c%2==0 then
    d=':'
  else
    d=' '
  end
  t=string.format('%02d',h)..d..string.format('%02d',m)
  print('Time: '..t)
  s=s+1
  if s > 15 then s=0 end
  if s > 10 then
    draw_logo()
  else
    draw_time()
  end
end)
