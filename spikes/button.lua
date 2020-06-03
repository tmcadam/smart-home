local Button =  {}
Button.__index = Button

function SimpleButton.new(pin, pressed_action)
    local self = setmetatable({}, SimpleButton)


local btn_pin = 3
gpio.mode(btn_pin, gpio.INPUT)

local tObj = tmr.create() 
local action

local last_button_state = 1
local debounce = 20
local function button_watcher()
    button_state = gpio.read(btn_pin)
    if button_state ~= last_button_state then
        if button_state == 0 then
            print ("Button pressed")
            action()
        elseif button_state == 1 then
            print ("Button released")
        end
        last_button_state = button_state
    end
end

function M.watch(_action)
    action = _action
    tObj:alarm(debounce, tmr.ALARM_AUTO, button_watcher)
end

return M