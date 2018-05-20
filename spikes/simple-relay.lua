pin = 1
gpio.mode(pin,gpio.OUTPUT)

lighton=0
tmr.alarm(0,5000,1,function()
    if lighton==0 then
        lighton=1
        gpio.write(pin,gpio.HIGH)
    else
        lighton=0
        gpio.write(pin,gpio.LOW)
    end
end)
