--[[
-----------------------------------------------------------------------------

▄▄▄█████▓ ██░ ██ ▓█████   ▄▄▄█████▓ ▄▄▄        ██████  ██ ▄█▀▓█████  ██▀███
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀   ▓  ██▒ ▓▒▒████▄    ▒██    ▒  ██▄█▒ ▓█   ▀ ▓██ ▒ ██▒
▒ ▓██░ ▒░▒██▀▀██░▒███     ▒ ▓██░ ▒░▒██  ▀█▄  ░ ▓██▄   ▓███▄░ ▒███   ▓██ ░▄█ ▒
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄   ░ ▓██▓ ░ ░██▄▄▄▄██   ▒   ██▒▓██ █▄ ▒▓█  ▄ ▒██▀▀█▄
  ▒██▒ ░ ░▓█▒░██▓░▒████▒    ▒██▒ ░  ▓█   ▓██▒▒██████▒▒▒██▒ █▄░▒████▒░██▓ ▒██▒
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░    ▒▒   ▓▒█░▒ ▒▓▒ ▒ ░▒ ▒▒ ▓▒░░ ▒░ ░░ ▒▓ ░▒▓░
    ░     ▒ ░▒░ ░ ░ ░  ░      ░      ▒   ▒▒ ░░ ░▒  ░ ░░ ░▒ ▒░ ░ ░  ░  ░▒ ░ ▒░
  ░       ░  ░░ ░   ░       ░        ░   ▒   ░  ░  ░  ░ ░░ ░    ░     ░░   ░
          ░  ░  ░   ░  ░                 ░  ░      ░  ░  ░      ░  ░   ░

-----------------------------------------------------------------------------
____ ____ ____ ____ _  _ ___ _ _  _ ____    ____ _  _ _  _ _  _ ____ ____
|    |  | |__/ |  | |  |  |  | |\ | |___    |__/ |  | |\ | |\ | |___ |__/
|___ |__| |  \ |__| |__|  |  | | \| |___    |  \ |__| | \| | \| |___ |  \

	DLT <dave.tichy@gmail.com>
-----------------------------------------------------------------------------

Usage:
	local TASKER = Dlt_CoroutineRunner()
	TASKER:add_task( callback, feedback_func, finished_func )
	TASKER:add_task( callback2, feedback_func2, finished_func2 )

---------------------------------------------------------------------------
Copyright © 2020 David Lopez Tichy, http://dlt.fm <dave.tichy@gmail.com>
---------------------------------------------------------------------------
The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
---------------------------------------------------------------------------


---------------------------------------------------------------------------]]

class 'Dlt_CoroutineRunner'

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:__init ()
	self.queue = {}

	self.lock_to_new_tasks = false

	self.require_explicit_continue = false
	-- queue contains tasks :
	-- { callback_function, feedback_function, finished_function }
	self.active_coroutine = nil
	self.active_feedback = nil
	self.active_finished = nil

	self.app_idle_callback = function()
		self:app_idle()
	end


	self.DEBUG = false
end

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:add_task (callback, feedback, finished)

	feedback = feedback or nil
	finished = finished or nil

	if self.DEBUG then
		-- DEBUG
		if callback then callback() end
		if feedback then feedback() end
		if finished then finished() end
		return
	end
	if not self.lock_to_new_tasks then
		table.insert(self.queue, {callback, feedback, finished})
		self:run_queue()
	end
end

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:lock ()
	self.lock_to_new_tasks = true
end

function Dlt_CoroutineRunner:unlock ()
	self.lock_to_new_tasks = false
end


-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:run_queue ()
	if not self.active_coroutine then
		-- pop the first task off the queue
		if #self.queue >= 1 then
			local t = table.remove(self.queue, 1)
			self.active_coroutine = coroutine.create( t[1] )
			self.active_feedback = t[2]
			self.active_finished = t[3]
			if not renoise.tool().app_idle_observable:has_notifier(self.app_idle_callback) then
				renoise.tool().app_idle_observable:add_notifier(self.app_idle_callback)
			end
		end
	end
	-- otherwise, either already running or no more tasks; nothing to do
end

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:yield ()
	if self.active_coroutine then
		coroutine.yield()
	end
end

-----------------------------------------------------------------------------
-- Fires a coroutine.yield() if the given condition is true

function Dlt_CoroutineRunner:yield_if (test)
	if test == true then
		self:yield()
	end
end

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:continue ()
	self:run_queue(true)
end

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:cancel_all ()
	self.queue = {}
	self:clear_active()
	if renoise.tool().app_idle_observable:has_notifier(self.app_idle_callback) then
		renoise.tool().app_idle_observable:remove_notifier(self.app_idle_callback)
	end
end

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:clear_active ()
	self.active_coroutine = nil
	self.active_feedback = nil
	self.active_finished = nil
end

-----------------------------------------------------------------------------

function Dlt_CoroutineRunner:app_idle ()
	if self.active_coroutine then
		if coroutine.status(self.active_coroutine) == 'suspended' then
			-- print('suspended')
			if self.active_feedback then
				-- print('-feedback')
				self.active_feedback()
			end
			coroutine.resume(self.active_coroutine)
			-- print('resumed')
		elseif coroutine.status(self.active_coroutine) == 'dead' then
			-- print('dead')
			self.active_coroutine = nil
			self.active_feedback = nil
			self.active_finished = nil
			if renoise.tool().app_idle_observable:has_notifier(self.app_idle_callback) then
				renoise.tool().app_idle_observable:remove_notifier(self.app_idle_callback)
			end
			if self.active_finished then
				-- print('-finished')
				self.active_finished()
			end
			if self.require_explicit_continue ~= true then
				self:run_queue()
			end
		end
	end
end



-- vim: foldenable:foldmethod=syntax:foldnestmax=1:foldlevel=0:foldcolumn=3
-- :foldopen=all:foldclose=all
