-- some constants --
MQTTIP='mqtt'
MQTTTOPIC='/sensors/hwat-t'
MQTTID='hwat'
TSIP='184.106.153.149' -- api.thingspeak.com
TSKEY='03UIDXIKINPM4K4H'
SSID="Slow"
KEY="Ao3deiwah7"
-- onewire pin3=GPIO0
OWPIN = 3
-- DS18B20 Power Supply pin
PWRPIN=4

function getData()
count = 0
repeat
  count = count + 1
  addr = ow.reset_search(OWPIN)
  addr = ow.search(OWPIN)
  tmr.wdclr()
until((addr ~= nil) or (count > 100))
if (addr == nil) then
  print("No more addresses.")
else
  print(addr:byte(1,8))
  crc = ow.crc8(string.sub(addr,1,7))
  if (crc == addr:byte(8)) then
    if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
      print("Device is a DS18S20 family device.")
        repeat
          ow.reset(OWPIN)
          ow.select(OWPIN, addr)
          ow.write(OWPIN, 0x44, 1)
          tmr.delay(1000000)
          present = ow.reset(OWPIN)
          ow.select(OWPIN, addr)
          ow.write(OWPIN,0xBE,1)
          print("P="..present)  
          data = nil
          data = string.char(ow.read(OWPIN))
          for i = 1, 8 do
            data = data .. string.char(ow.read(OWPIN))
          end
          print(data:byte(1,9))
          crc = ow.crc8(string.sub(data,1,8))
          print("CRC="..crc)
          if (crc == data:byte(9)) then
             t = (data:byte(1) + data:byte(2) * 256)

             -- handle negative temperatures
             if (t > 0x7fff) then
                t = t - 0x10000
             end

             if (addr:byte(1) == 0x28) then
                t = t * 625  -- DS18B20, 4 fractional bits
             else
                t = t * 5000 -- DS18S20, 1 fractional bit
             end
             t1 = t / 10000
             t2 = t % 10000
             print("Temperature= "..t1.."."..t2.." Centigrade")
			 return t1.."."..t2
          end                   
          tmr.wdclr()
        until false
    else
      print("Device family is not recognized.")
    end
  else
    print("CRC is not valid!")
  end
end
end

-- MAIN --
function main()
ow.setup(OWPIN)
gpio.mode(PWRPIN, gpio.OUTPUT)
gpio.write(PWRPIN, gpio.HIGH)
-- get data
t=getData()
print("Temp:"..t.." C\n")
-- send data to mqtt
m = mqtt.Client(MQTTID, 10)
print("MQTT connect")
m:connect(MQTTIP, 1883, 0, function(client)
  print ("MQTT on connect")
  m:publish(MQTTTOPIC,t,0,0, function(client)
    print("MQTT sent")
    m:close();
    print("MQTT closed")
    end)
  end)
-- send data to thing speak
print("TS createConnection")
conn=net.createConnection(net.TCP, 0)
conn:on("receive", function(conn, payload)
  print("TS receive start")
  print(payload)
  print("TS receive end")
  end)
conn:on("connection", function(conn)
  print("TS connection start")
  conn:send("GET /update?key="..TSKEY.."&field1="..t.."\r\n")
  print("TS connection end")
  end)
conn:on("sent",function(conn)
  print("TS sent start")
  conn:close()
  print("TS sent end")
  end)
conn:on("disconnection", function(conn)
  print("TS disconnection start")
  print("TS disconnection end")
  end)
print("TS connecting...")
conn:connect(80,TSIP)
print("End of script")
end

-- START --
print("Going to deep sleep in 10 sec, stop timer 0 to prevent")
tmr.alarm(0, 10000, tmr.ALARM_SINGLE, function()    
  print("Deep sleep 5 min")
  node.dsleep(300000000)
  end)
-- connect wifi
print("configuring wifi: SSID:"..SSID..", KEY:"..KEY)
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, KEY)
wifi.sta.connect()
tmr.alarm(1, 1000, 1, function() 
  if wifi.sta.getip()== nil then 
    print("IP unavaiable, Waiting...") 
  else 
    tmr.stop(1)
    print("Config done, IP is")
    print(wifi.sta.getip())
    print(wifi.sta.getconfig())
    main()
  end
end)
