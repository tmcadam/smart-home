local led_pin = 7
gpio.mode(led_pin, gpio.OUTPUT)
gpio.write(led_pin, gpio.HIGH)

local status_tmr = tmr.create()
status_tmr:register(500, tmr.ALARM_AUTO, function ()
    if gpio.read(led_pin) == 1 then
        gpio.write(led_pin, gpio.LOW)
    else
        gpio.write(led_pin, gpio.HIGH)
    end
end)

local status_led = {}
function status_led.start()
    status_tmr:start()
end
function status_led.stop()
    status_tmr:stop()
    gpio.write(led_pin, gpio.HIGH)
end
return status_led
