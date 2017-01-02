-- some constants --
MQTTIP='mqtt'
MQTTTOPIC='/sensors/cwat-p'
MQTTID='cwat'
TSIP='184.106.153.149' -- api.thingspeak.com
TSKEY='TS KEY'
SSID="WIFI SSID"
KEY="WIFI KEY"

-- Sensor Power Supply pin
PWRPIN=1

function getData()
    a=adc.read(0)
    --shift: +0.5V, divider: 1/5, shift: 100 adc cnts
    -- each 100 cnts = 0.15 MPa 
    p=(a-100)*3/2
    if p < 0 then
		p=0
		print 'Probably, there is no sensor connected\n'
		end
	return a, p
end

-- MAIN --
function main()
-- get data
a, p=getData()
print("ADC:      "..a.."\nPressure :"..p.." kPa\n")
-- send data to mqtt
m = mqtt.Client(MQTTID, 10)
print("MQTT connect")
m:connect(MQTTIP, 1883, 0, function(client)
  print ("MQTT on connect")
  m:publish(MQTTTOPIC,p,0,0, function(client)
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
  conn:send("GET /update?key="..TSKEY.."&field1="..a.."&field2="..p.."\r\n")
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
print('Sensor power ON')
gpio.mode(PWRPIN, gpio.OUTPUT)
gpio.write(PWRPIN, gpio.HIGH)
print("Going to deep sleep in 10 sec, stop timer 0 to prevent")
tmr.alarm(0, 10000, tmr.ALARM_SINGLE, function()    
  print('Sensor power OFF')
  gpio.write(PWRPIN, gpio.LOW)
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
