function init_i2c_display()
    -- SDA and SCL can be assigned freely to available GPIOs
    local id = 0
    local sda = 3
    local scl = 4
    local sla = 0x3c
    gpio.mode(sda, gpio.OUTPUT)
    gpio.mode(scl, gpio.OUTPUT)
    i2c.setup(id, sda, scl, i2c.SLOW)
    i2c.start(id)
    ack=i2c.address(id, sla, i2c.RECEIVER)
    print("LCD ACK: "..tostring(ack))
    i2c.stop(id)
    
    disp = u8g.ssd1306_128x64_i2c(sla)
    disp:begin()
end

function prepare_display()
    --font_6x10r
    --font_gdr25n
    --font_gdb25n
    --font_freedoomr25n
    disp:firstPage()
    disp:setFont(u8g.font_gdb25n)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
    disp:setRot180()
end

-- init
init_i2c_display()
prepare_display()

-- MAIN LOOP
--tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()   
  -- draw screen
  disp:firstPage()
  repeat
    disp:drawStr(0,  0, '0123456789')
  until disp:nextPage() == false
--end)