
pin = 4

local function readout(temp)
  addr, temp in pairs(temp[0])
  print(temp)
end
        
tmr.create():alarm(2000, tmr.ALARM_AUTO, function()
    t:read_temp(readout, pin, t.C)
end)
