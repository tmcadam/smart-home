SimpleButton = {}
SimpleButton.__index = SimpleButton

function SimpleButton.new(pin, pressed_action)
    local self = setmetatable({}, SimpleButton)
    self.pin = pin
    self.pressed_action = pressed_action
    self.released_action = nil
    self.debounce = 20
    self.last_button_state = 1
    self.timer = tmr.create()
    gpio.mode(self.pin, gpio.INPUT)
    self.timer:register(self.debounce, tmr.ALARM_AUTO, function ()
        local button_state = gpio.read(self.pin)
        if button_state ~= self.last_button_state then
            if button_state == 0 then
                --Released
            elseif button_state == 1 then
                --Pressed
                self.pressed_action()
            end
            self.last_button_state = button_state
        end
    end)
    self.timer:start()
    return self
end
