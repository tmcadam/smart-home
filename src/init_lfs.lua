function startup()
  if(LFS) == nil and file.exists('lfs.img') then
    node.flashindex("_init")()
    print("Starting from LFS" )
    LFS.application()
  else
    print("FATAL: LFS ERROR")
    tmr.create():alarm(10000, tmr.ALARM_SINGLE, node.restart)
  end
end

print("Startup will resume momentarily, you have 2 seconds to abort.")
tmr.create():alarm(2000, tmr.ALARM_SINGLE, startup)
