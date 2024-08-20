local thread_cache = {}

--- @class Thread
--- @field co thread
--- @field sleeping timer?
--- @field awaiting Thread?
--- @field values table?
--- @field dead boolean?
--- @field on_dead function?
--- @field is_valid fun(self: Thread): boolean
--- @field get_running_thread fun(): Thread?
--- @field new fun(func: function, ...: any): Thread | false
--- @field destroy fun(self: Thread): nil
--- @field status fun(self: Thread): "dead" | "normal" | "running" | "suspended"
--- @field pause fun(self: Thread): nil
--- @field sleep fun(self: Thread, duration: number): nil
--- @field await fun(self: Thread, other: Thread): any?
--- @field resume fun(self: Thread, ...: any): any?
local Thread = {}
Thread.__index = Thread

function Thread.is_valid(self)
	return getmetatable(self) == Thread
end

function Thread.get_running_thread()
	return thread_cache[coroutine.running()]
end

function Thread.new(func, ...)
	if type(func) ~= "function" then
		return false
	end
	local thread = setmetatable({ co = coroutine.create(func) }, Thread)
	thread_cache[thread.co] = thread
	thread:resume(...)
	return thread
end

function Thread:destroy()
	thread_cache[self.co] = nil
	setmetatable(self, nil)
end

function Thread:status()
	return coroutine.status(self.co)
end

function Thread:pause()
	return coroutine.yield()
end

function Thread:sleep(duration)
	if type(duration) ~= "number" then
		return false
	end
	self.sleeping = setTimer(function()
		self.sleeping = nil
		self:resume()
	end, duration, 1)
	return self:pause()
end

function Thread:await(other)
	if not Thread.is_valid(other) then
		return false
	end
	if other == self then
		return false
	end
	if other.dead and other.values then
		return unpack(other.values)
	end
	self.awaiting = other
	function other.on_dead()
		self.awaiting = nil
		self:resume(unpack(other.values))
	end
	return self:pause()
end

function Thread:resume(...)
	if self.sleeping then
		return
	end
	if self.awaiting then
		return
	end
	if self:status() == "dead" then
		return unpack(self.values)
	end
	if self:status() == "suspended" then
		local values = { coroutine.resume(self.co, ...) }
		table.remove(values, 1)
		self.values = values
	end
	if self:status() == "dead" then
		self.dead = true
		if self.on_dead then
			self.on_dead()
		end
		thread_cache[self.co] = nil
	end
	return unpack(self.values)
end

--- @param func function
--- @return function | false
function Async(func)
	if type(func) ~= "function" then
		return false
	end
	return function(...)
		return Thread.new(func, ...)
	end
end

--- @param thread Thread
--- @return any
function Await(thread)
	if not Thread.is_valid(thread) then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	return running_thread:await(thread)
end

--- @param duration number
--- @return any
function Sleep(duration)
	if type(duration) ~= "number" then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	return running_thread:sleep(duration)
end

local _dbQuery = dbQuery

dbQuery = Async(function(...)
	if not _dbQuery then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	local result = _dbQuery(function(query)
		running_thread:resume(dbPoll(query, 0))
	end, ...)
	if not result then
		return false
	end
	return running_thread:pause()
end)

local _passwordHash = passwordHash

passwordHash = Async(function(password, algorithm, options)
	if not _passwordHash then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	local result = _passwordHash(password, algorithm, options or {}, function(...)
		running_thread:resume(...)
	end)
	if not result then
		return false
	end
	return running_thread:pause()
end)

local _passwordVerify = passwordVerify

passwordVerify = Async(function(password, hash, options)
	if not _passwordVerify then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	local result = _passwordVerify(password, hash, options or {}, function(...)
		running_thread:resume(...)
	end)
	if not result then
		return false
	end
	return running_thread:pause()
end)

local _fetchRemote = fetchRemote

fetchRemote = Async(function(url, options)
	if not _fetchRemote then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	local result = _fetchRemote(url, options or {}, function(...)
		running_thread:resume(...)
	end)
	if not result then
		return false
	end
	return running_thread:pause()
end)

local _encodeString = encodeString

encodeString = Async(function(algorithm, input, options)
	if not _encodeString then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	local result = _encodeString(algorithm, input, options or {}, function(...)
		running_thread:resume(...)
	end)
	if not result then
		return false
	end
	return running_thread:pause()
end)

local _decodeString = decodeString

decodeString = Async(function(algorithm, input, options)
	if not _decodeString then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	local result = _decodeString(algorithm, input, options or {}, function(...)
		running_thread:resume(...)
	end)
	if not result then
		return false
	end
	return running_thread:pause()
end)

local _generateKeyPair = generateKeyPair

---@diagnostic disable-next-line: lowercase-global
generateKeyPair = Async(function(algorithm, options)
	if not _generateKeyPair then
		return false
	end
	local running_thread = Thread.get_running_thread()
	if not running_thread then
		return false
	end
	local result = _generateKeyPair(algorithm, options or {}, function(...)
		running_thread:resume(...)
	end)
	if not result then
		return false
	end
	return running_thread:pause()
end)
