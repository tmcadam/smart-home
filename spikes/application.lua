led = require("led")
require("button")
--network = require("network")

local function toggleRelay()
    print("Toggle relay")
end

button = Button:new(
    3,
    function()
        print("Button pressed")
        led.off()
        toggle_relay()
    end
)
button.enable()

led.pin(4, gpio.HIGH)
led.blink(1000)

button.watch(1, buttonPressed)

-- local tObj1 = tmr.create()
-- tObj1:alarm(
--     10000,
--     tmr.ALARM_SINGLE,
--     function()
--         led.on()
--         tObj1:alarm(
--             10000,
--             tmr.ALARM_SINGLE,
--             led.off
--         )
--     end
-- )
