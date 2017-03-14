-- Manufacturer: e0
-- Device: 4014
-- MAC: 18:fe:34:f2:71:54

id   = 0
sda  = 4 -- GPIO2=D4
scl  = 3 -- GPIO0=D3
env  = 2 -- GPIO4=D2
rtc  = 0x51
oled = 0x3c
eeprom = 0x53 -- or 0x57 if B0 is high
tzoffsethrs = 3
tzoffsetmin = 0
ntpserv = 'pool.ntp.org'
wifi_ssid = "*"
wifi_key = "*"
issynced = 0
insync = 0
ip = nil
rssi = ''
envstr=''
TSKEY='*'
TSIP='api.thingspeak.com'
MQTTIP='*'
MQTTPORT='*'
MQTTID='*'
MQTTUSER='*'
MQTTPASS='*'

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
    --font_6x10,font_chikita,font_freedoomr25n
    disp:setFont(u8g.font_freedoomr25n)
    disp:drawStr(15,  30, t)
    disp:setFont(u8g.font_6x10)
    disp:drawStr(0,  40, envstr)
    if ip ~= nil then
      disp:drawStr(0,  50, "IP "..ip)
    else
      disp:drawStr(0,  50, "MAC "..wifi.sta.getmac())
    end
    disp:drawStr(0,  60, wifi_ssid..' '..rssi..'dBm')
  until disp:nextPage() == false
end

function get_env()
  status, temp, humi, temp_dec, humi_dec = dht.read(env)
  if status == dht.OK then
    if ip ~= nil then
      senddata(temp.."."..temp_dec, humi.."."..humi_dec)
      end
    return(string.format("Temp: %d C, Hum: %d %%",temp,humi))
  elseif status == dht.ERROR_CHECKSUM then
    return( "DHT Checksum error." )
  elseif status == dht.ERROR_TIMEOUT then
    return( "DHT timed out." )
  end
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
  issynced=1
  tmr.stop(0)
end

function sync_err(errcode)
  print('Sync ERR: '..tostring(errcode))
  if errcode == 1 then print('1: DNS lookup failed') end
  if errcode == 2 then print('2: Memory allocation failure') end
  if errcode == 3 then print('3: UDP send failed') end
  if errcode == 4 then print('4: Timeout, no NTP response received') end
  insync=0
end

-- Config WiFi and sync time
wifi.setmode(wifi.STATION)
wifi.sta.config(wifi_ssid, wifi_key)
tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()
  ip = wifi.sta.getip()
  if ip ~= nil then
    print('Got ip: '..ip)
    if insync == 0 then
      sntp.sync('pool.ntp.org',sync_ok, sync_err)
      insync=1
    end
  end
end)

function senddata(temp, humi)
print("TS createConnection")
conn=net.createConnection(net.TCP, 0)
conn:on("receive", function(conn, payload)
  --print("TS receive start")
  print(payload)
  --print("TS receive end")
  end)
conn:on("connection", function(conn)
  --print("TS connection start")
  conn:send("GET /update?key="..TSKEY.."&field1="..temp.."&field2="..humi.."\r\n")
  --print("TS connection end")
  end)
conn:on("sent",function(conn)
  --print("TS sent start")
  conn:close()
  --print("TS sent end")
  end)
conn:on("disconnection", function(conn)
  --print("TS disconnection start")
  print("TS disconnection end")
  end)
--print("TS connecting...")
conn:connect(80,TSIP)

mq = mqtt.Client(MQTTID, 10, MQTTUSER, MQTTPASS)
print("MQTT connect")
mq:connect(MQTTIP, MQTTPORT, 0, function(client)
  print ("MQTT on connect")
  mq:publish('/sensors/office/t',temp,0,0, function(client)
    print("MQTT:t sent")
    mq:publish('/sensors/office/h',humi,0,0, function(client)
        print("MQTT:b sent")
        mq:close()
        print("MQTT: closed")
        end)
    end)
  end)
end

-- MAIN LOOP
envstr=get_env()
tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()
  c=c+1
  if c > 59 then
    c=0
    m=m+1
    if m%5 == 0 then envstr=get_env() end
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
  if issynced == 0 then
    t=t..' -'
  end
--  print('Time: '..t)
  s=s+1
  if s > 15 then
    s=0
  end
  if s > 10 then
    draw_logo()
  else
    rssi = wifi.sta.getrssi()
    if rssi == nil then
      rssi = ''
    end
    draw_time()
  end
end)
