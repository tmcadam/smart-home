LED = {}
LED.__index = LED
setmetatable(LED, {
    __call = function (cls, ...)
      return cls.create(...)
    end,
  })

function LED.create(_pin, _rate, _onLevel)
    local self = setmetatable({}, LED)
    self.pin = _pin
    self.rate = _rate
    self.onLevel = _onLevel
    self.timer = tmr.create()
    gpio.mode(self.pin, gpio.OUTPUT)
    gpio.write(self.pin, 1 - self.onLevel)
    self.timer:register(self.rate, tmr.ALARM_AUTO, 
        function ()
            gpio.write(self.pin, 1 - gpio.read(self.pin))
        end)
    return self
end

function LED:blink()
    self.timer:start()
end

function LED:on()
    self.timer:stop()
    gpio.write(self.pin, self.onLevel)
end

function LED:off()
    self.timer:stop()
    gpio.write(self.pin, 1 - self.onLevel)
end
