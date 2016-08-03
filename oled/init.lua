function init_i2c_display()
    -- SDA and SCL can be assigned freely to available GPIOs
    local sda = 2 -- GPIO14
    local scl = 1 -- GPIO12
    local sla = 0x3c
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
end

function prepare()
    disp:firstPage()
    disp:setFont(u8g.font_6x10)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
end

function box_frame(a)
    disp:drawStr(0, 0, "drawBox")
    disp:drawBox(5, 10, 20, 10)
    disp:drawBox(10+a, 15, 30, 7)
    disp:drawStr(0, 30, "drawFrame")
    disp:drawFrame(5, 10+30, 20, 10)
    disp:drawFrame(10+a, 15+30, 30, 7)
end


init_i2c_display()
prepare()
disp:begin()

function listap(t)
  a = {}
  i=1
  for k,v in pairs(t) do
    a[i]=tostring(i)..':'..k
    print('a['..i..']='..k)
    i=i+1
  end
  len=i-1
  offsetmax=len*10
  if offsetmax < 0 then offsetmax=0 end
  print('Total APs: '..len..'\nScroll:'..tostring(offsetmax))
  offset=0
  repeat
    disp:firstPage()
    repeat
      for i=1,len do
        y=i*10+54-offset
        disp:drawStr(0, y, a[i])
      end
    until disp:nextPage() == false
    offset=offset+1
    tmr.delay(10)
  until offset==offsetmax
  print('done')
end
wifi.sta.getap(listap)



--disp:firstPage()
--disp:nextPage()
--print(string.format("0x%02X", i))

