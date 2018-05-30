StatusLed = {}
StatusLed.__index = StatusLed

function StatusLed.new(pin, rate)
    local self = setmetatable({}, StatusLed)
    self.pin = pin
    self.rate = rate
    self.timer = tmr.create()
    gpio.mode(self.pin, gpio.OUTPUT)
    gpio.write(self.pin, gpio.HIGH)
    self.timer:register(self.rate, tmr.ALARM_AUTO, function ()
        if gpio.read(self.pin) == 1 then
            gpio.write(self.pin, gpio.LOW)
        else
            gpio.write(self.pin, gpio.HIGH)
        end
    end)
    return self
end

function StatusLed:start()
    self.timer:start()
end

function StatusLed:stop()
    self.timer:stop()
    gpio.write(self.pin, gpio.HIGH)
end
