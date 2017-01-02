-- i2c config
SDA_PIN = 4
SCL_PIN = 3
-- BMP180 config
OSS = 1 -- oversampling
bmp180 = require("bmp085")
bmp180.init(SDA_PIN, SCL_PIN)
-- DHT11 config
DAT = 2
-- MQTT
MQTTID='env'
MQTTIP='mqtt'
-- ThingSpeak
TSKEY='RGTJA4C0PMEYVFAE'
TSIP='184.106.153.149' -- api.thingspeak.com
-- WiFi
WFSSID="Slow"
WFKEY="Ao3deiwah7"


function readDHT11()
  status, temp, humi, temp_dec, humi_dec = dht.read(DAT)
  if status == dht.OK then
    temp=temp.."."..temp_dec
    print("DHT temperature: "..temp)
    humi=humi.."."..humi_dec
    print("DHT humidity: "..humi)
    return temp, humi
  else
    print("DHT read error:"..status)
  end
end

function readBMP180()
  t = bmp180.temperature()
  -- add decimal point
  t = t / 10 ..".".. t % 10
  print("BMP180 temperature: "..t)
  p = bmp180.pressure(OSS)
  print("BMP180 pressure hPA: "..p)
  -- converp Pa to mmHg
  phg=(p * 75 / 10000).."."..((p * 75 % 10000) / 1000)
  print("BMP180 pressure mmHg: "..phg)
  return t, p, phg
end



function sendData()
print('---------------')
t1, hum = readDHT11()
t2, php, phg = readBMP180()
-- send data to mqtt
m = mqtt.Client(MQTTID, 10)
print("MQTT connect")
m:connect(MQTTIP, 1883, 0, function(client)
  print ("MQTT on connect")
  m:publish('/sensors/env/t',t2,0,0, function(client)
    print("MQTT:t sent")
    m:publish('/sensors/env/b',phg,0,0, function(client)
        print("MQTT:b sent")
        m:publish('/sensors/env/h',hum,0,0, function(client)
            print("MQTT:h sent")
            end)
        end)
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
  conn:send("GET /update?key="..TSKEY.."&field1="..t1.."&field2="..t2.."&field3="..hum.."&field4="..phg.."\r\n")
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
end

-- START
wifi.setmode(wifi.STATION)
wifi.sta.config(WFSSID, WFKEY)
tmr.alarm(0, 60000, 1, function() sendData() end )
