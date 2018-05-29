function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        dofile("application.lua")
    end
end

print("Startup will resume momentarily, you have 3 seconds to abort.")
tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)
