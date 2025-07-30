--[[============================================================================
process_slicer.lua
============================================================================]]--

class "ProcessSlicer"

function ProcessSlicer:__init(process_func, ...)
 assert(type(process_func) == "function", "expected a function as first argument")

 self.__process_func = process_func
 self.__process_func_args = arg
 self.__process_thread = nil
end

-- returns true when the current process currently is running  

function ProcessSlicer:running()
 return (self.__process_thread ~= nil)
end

-- start a process  

function ProcessSlicer:start()
 assert(not self:running(), "process already running")

 self.__process_thread = coroutine.create(self.__process_func)

 renoise.tool().app_idle_observable:add_notifier(
 ProcessSlicer.__on_idle, self)
end

-- stop a running process  

function ProcessSlicer:stop()
 assert(self:running(), "process not running")

 renoise.tool().app_idle_observable:remove_notifier(ProcessSlicer.__on_idle, self)

 self.__process_thread = nil
end

-- function that gets called from Renoise to do idle stuff. switches back into the processing function or detaches the thread  

function ProcessSlicer:__on_idle()
 assert(self.__process_thread ~= nil, "ProcessSlicer internal error: ".. "expected no idle call with no thread running")

 -- continue or start the process while its still active
 if (coroutine.status(self.__process_thread) == 'suspended') then
 local succeeded, error_message = coroutine.resume(
 self.__process_thread, unpack(self.__process_func_args))

 if (not succeeded) then
 -- stop the process on errors
 self:stop()
 -- and forward the error to the main thread
 renoise.app():show_error("ERROR: You're probably trying to export to a protected folder.")
 error(error_message)
 end

 -- stop when the process function completed
 elseif (coroutine.status(self.__process_thread) == 'dead') then
 self:stop()
 end
end
