-- some constants
CONFFILE='config.txt'
MAINFILE='main.lua'

print("started")
if file.open(CONFFILE, "r") == nil then
  print("No config found!")
end

function trim1(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

SSID=trim1(file.readline())
KEY=trim1(file.readline())
file.close()
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
  end
end)
print("Call main in 5 sec, stop timer 1 to prevent")
tmr.alarm(1, 5000, tmr.ALARM_SINGLE, function()    
  print("Call main file")
  dofile(MAINFILE)
end)
