local Button =  {}
Button.__index = Button

function Button:new(_pin, _pressedAction)
    local self = setmetatable({}, SimpleButton)
    self.btnPin = _pin -- 3
    self.pressedAction = pressedAction
    self.debounceDelay = 20
    self.tObj = tmr.create()
    self.tObj2 = tmr.create()
    gpio.mode(self.btnPin, gpio.INT)
end

function Button:buttonPressed()
    gpio.trig(btn_pin, "none")
    tObj:alarm( debounceDelay, 
                tmr.ALARM_SINGLE, 
                function()
                    gpio.trig(btn_pin, "down", self.buttonPressed)
                    self.pressedAction()
                end
    )
end

function Button:enable()
    gpio.trig(self.btnPin, "down", self.buttonPressed)
end

function Button:disable()
    gpio.trig(self.btnPin, "none")
end
