Button =  { debounceDelay=50,
            multiplePressWindow=1000 }
Button.__index = Button
setmetatable(Button, {
    __call = function (cls, ...)
        return cls.create(...)
    end,
    })

function Button.create(_pin, _pressedAction)
    local self = setmetatable({}, Button)
    self.btnPin = _pin -- 3
    self.pressedAction = _pressedAction
    self.tmr1 = tmr.create()
    self.counter = 0
    gpio.mode(self.btnPin, gpio.INT, gpio.PULLUP)
    gpio.trig(self.btnPin, "down", function() self:buttonPressed() end)
    return self
end

function Button:handleSinglePress()
    self.counter = self.counter + 1
    self.tmr1:alarm(self.multiplePressWindow, tmr.ALARM_SINGLE, function() self:handleFinalPress() end)
end

function Button:handleFinalPress()
    self.pressedAction(self.counter)
    self.counter = 0
end

function Button:buttonPressed()
    gpio.trig(self.btnPin, "none")
    tmr.create():alarm( self.debounceDelay,
                tmr.ALARM_SINGLE,
                function()
                    gpio.trig(self.btnPin, "down", function() self:buttonPressed() end)
                    self:handleSinglePress()
                end
    )
end
