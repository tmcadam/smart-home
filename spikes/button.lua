local btn_pin = 3
gpio.mode(btn_pin, gpio.INPUT)

local last_button_state = 1
local debounce = 20
local function button_watcher()
    button_state = gpio.read(btn_pin)
    if button_state ~= last_button_state then
        if button_state == 0 then
            print ("Button pressed")
        elseif button_state == 1 then
            print ("Button released")
        end
        last_button_state = button_state
    end
end

tmr.alarm(0, debounce, tmr.ALARM_AUTO, button_watcher)
