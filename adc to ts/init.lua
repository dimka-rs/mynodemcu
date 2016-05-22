-- some constants --
TSIP='184.106.153.149' -- api.thingspeak.com
TSKEY='TS KEY'
SSID="WIFI SSID"
KEY="WIFI KEY"

-- MAIN --
function main()
a=adc.read(0)
print("ADC: "..a)
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
  conn:send("GET /update?key="..TSKEY.."&field1="..a.."\r\n")
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
