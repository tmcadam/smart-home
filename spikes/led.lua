local M =  {}

local tObj = tmr.create()
local pin
local onState
local state

function M.pin(_pin, _onState)
  pin = _pin
  onState = _onState
  state = _onState
  gpio.mode(pin, gpio.OUTPUT)
end

function M.blink(period)
  print("Starting blink")
  tObj:alarm(period,tmr.ALARM_AUTO, function()
    state = 1 - state
    gpio.write(pin, state)
  end) 
end

function M.on()
  tObj:unregister()
  gpio.write(pin, onState)
end

function M.off()
  tObj:unregister()
  gpio.write(pin, 1 - onState)
end

return M