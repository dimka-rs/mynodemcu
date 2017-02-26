id   = 0
sda  = 4 -- GPIO2=D4
scl  = 3 -- GPIO0=D3
rtc  = 0x51
oled = 0x3c
eeprom = 0x53 -- or 0x57 if B0 is high
tzoffsethrs = 3
tzoffsetmin = 0
ntpserv = 'pool.ntp.org'
wifi_ssid = ""
wifi_key = ""
insync = 0
ip = nil
h=12  -- hours
m=34  -- minutes
c=0   -- seconds
t=''  -- time string
hwat_t='' -- hot water temperature
cwat_p='' -- cold water pressure
env_t=''
env_h=''
env_b=''


function i2c_print_slaves()
  for i=0x00,0x7F do
    i2c.start(id)
    ack=i2c.address(id, i, i2c.RECEIVER)
    if ack==true then print("ACK: "..string.format('0x%02X',i)) end
    i2c.stop(id)
  end
end

function init_i2c()
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
    disp:setFont(u8g.font_6x10)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
    disp:setRot180()
end

function draw_time()
  print("draw time")
  t=string.format('%02d',h)..":"..string.format('%02d',m)
  disp:firstPage()
  repeat
    --font_6x10,font_chikita,font_freedoomr25n
    disp:setFont(u8g.font_6x10)
    disp:drawStr(0,  0, "Time       "..t)
    disp:drawStr(0, 10, "Hot  water "..hwat_t.." °C")
    disp:drawStr(0, 20, "Cold water "..cwat_p.." kPa")
    disp:drawStr(0, 30, "Room temp  "..env_t.." °C")
    disp:drawStr(0, 40, "Room humid "..env_h.." %")
    disp:drawStr(0, 50, "Room press "..env_b.." mmHg")
  until disp:nextPage() == false
end

function sync_ok(offsec, offusec,serv)
  print('Sync OK: '..tostring(offsec)..','..tostring(offusec)..','..tostring(serv))
  hrs=offsec%86400/3600
  hrs=hrs+tzoffsethrs
  if hrs>23 then hrs=hrs-24 end

  min=offsec%3600/60
  min=min+tzoffsetmin
  if min > 59 then min=min-60 end

  sec=offsec%60

  h=hrs
  m=min
  s=sec
  print('Time set to: '..tostring(hrs)..':'..tostring(min)..':'..tostring(sec))
  insync=0
  tmr.stop(0)
  draw_time()
end

function sync_err(errcode)
  print('Sync ERR: '..tostring(errcode))
  if errcode == 1 then print('1: DNS lookup failed') end
  if errcode == 2 then print('2: Memory allocation failure') end
  if errcode == 3 then print('3: UDP send failed') end
  if errcode == 4 then print('4: Timeout, no NTP response received') end
  insync=0
end

--- MQTT ---

function mqtt_init(clientid, broker, port, secure, keepalive, user, password)
  mq = mqtt.Client(clientid, keepalive, user, password)
  mq:on("offline", function(client) print ("on offline") end)
  mq:on("message", function(client, topic, data) 
    --print(topic .. ":" ) 
    if data ~= nil then
      --print(data)
      if topic == "/sensors/hwat-t" then hwat_t=data print("hwat_t:"..data) end
      if topic == "/sensors/cwat-p" then cwat_p=data print("cwat_p:"..data) end
      if topic == "/sensors/env/t"  then env_t=data  print("env_t:"..data)  end
      if topic == "/sensors/env/h"  then env_h=data  print("env_h:"..data)  end
      if topic == "/sensors/env/b"  then env_b=data  print("env_b:"..data)  end
    end
  end)
  mq:connect(broker, port, secure,
    function(client)
      print("connected")
      mq:subscribe("/sensors/#",0, function(client)
        print("subscribed")
      end)
    end, 
    function(client, reason)
      print("failed reason: "..reason)
    end)
end

-- Config WiFi and sync time
wifi.setmode(wifi.STATION)
wifi.sta.config(wifi_ssid, wifi_key)
tmr.alarm(0, 2000, tmr.ALARM_AUTO, function()
  ip = wifi.sta.getip()
  if ip ~= nil then
    print('Got ip: '..ip)
    if insync == 0 then
      sntp.sync('pool.ntp.org',sync_ok, sync_err)
      insync=1
    end
  end
end)


-- init
init_i2c()
init_display()
mqtt_init("ESP-"..wifi.sta.getmac(), "mqtt", 1883, 0, 120)


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
    draw_time()
  end
end)






