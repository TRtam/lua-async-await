local locale = {
    assert = assert,
    isFunction = isFunction,
    coroutine = coroutine,
    table = table,
    isTimer = isTimer,
    killTimer = killTimer,
    setTimer = setTimer,
    math = math,
    tonumber = tonumber,
    dbQuery = dbQuery,
    dbPoll = dbPoll,
    passwordHash = passwordHash,
    passwordVerify = passwordVerify,
    fetchRemote = fetchRemote,
}

async = {
    threads = {},

    new = function(fn)
        if(not locale.isFunction(fn))then
            return false
        end
    
        return function(...)
            local thread = {co = locale.coroutine.create(fn)}
    
            locale.assert(thread.co, "async.new() - failed to create locale.coroutine")
        
            async.threads[thread.co] = thread
        
            function thread:status()
                return locale.coroutine.status(self.co)
            end

            function thread:pause()
                local runningThread = async.threads[locale.coroutine.running()]
    
                locale.assert(runningThread, "async.thread:pause() - this function can only be called from an async thread")
    
                return locale.coroutine.yield()
            end
    
            function thread:resume(...)
                if(locale.isTimer(self.sleeping) or self.awaiting)then
                    return false
                end

                local values

                if(thread:status() == "suspended")then
                    values = {locale.coroutine.resume(self.co, ...)}

                    if(thread:status() == "dead")then
                        local success = locale.table.remove(values, 1)
                        
                        if(not success)then
                            thread.values = {false, unpack(values)}
                        else
                            thread.values = values
                        end
                    end
                end

                return locale.table.unpack(values)
            end

            thread:resume(...)

            return thread
        end
    end
}

function sleep(ms)
    local runningThread = async.threads[locale.coroutine.running()]

    locale.assert(runningThread, "async.sleep() - this function can only be called from an async thread")

    ms = locale.tonumber(ms) or 1

    runningThread.sleeping = setTimer(
        function()
            runningThread.sleeping = nil
            runningThread:resume()
        end,
        ms,
        1
    )

    return runningThread:pause()
end

await = {
    dbQuery = function(connection, queryString, ...)
        local runningThread = async.threads[locale.coroutine.running()]

        locale.assert(runningThread, "async.await.dbQuery() - this function can only be called from an async thread")
    
        local waiting = locale.dbQuery(function(query) return runningThread:resume(locale.dbPoll(query, 0)) end, connection, queryString, ...)
    
        if(waiting)then return runningThread:pause() else return false end
    end,

    passwordHash = function(password, algorithm, options)
        local runningThread = async.threads[locale.coroutine.running()]

        locale.assert(runningThread, "async.await.passwordHash() - this function can only be called from an async thread")
            
        local waiting = locale.passwordHash(password, algorithm, options or {}, function(...) return runningThread:resume(...) end)
    
        if(waiting)then return runningThread:pause() else return false end
    end,

    passwordVerify = function(password, hash, options)
        local runningThread = async.threads[locale.coroutine.running()]

        locale.assert(runningThread, "async.await.passwordVerify() - this function can only be called from an async thread")
    
        local waiting = locale.passwordVerify(password, hash, options or {}, function(...) return runningThread:resume(...) end)
    
        if(waiting)then return runningThread:pause() else return false end
    end,

    fetchRemote = function(url, options)
        local runningThread = async.threads[locale.coroutine.running()]

        locale.assert(runningThread, "async.await.fetchRemote() - this function can only be called from an async thread")
            
        locale.fetchRemote(url, options, function(...) return runningThread:resume(...) end)
    
        return runningThread:pause()
    end,

    new = function(thread)
        local runningThread = async.threads[locale.coroutine.running()]

        locale.assert(runningThread, "async.await.new() - this function can only be called from an async thread")

        if((not locale.table.valid(thread)) or (not async.threads[thread.co]) or (runningThread.co == thread.co))then
            return false
        end

        if(thread.values)then
            return locale.table.unpack(thread.values)
        end

        runningThread.awaiting = locale.setTimer(
            function()
                if(thread.values)then
                    locale.killTimer(runningThread.awaiting)

                    runningThread.awaiting = nil
                    runningThread:resume(locale.table.unpack(thread.values))
                end
            end,
            50,
            0
        )

        return runningThread:pause()
    end,
}

setmetatable(
    async, 
    {
        __call = function(self, ...)
            return self.new(...)
        end
    }
)

setmetatable(
    await,
    {
        __call = function(self, ...)
            return self.new(...)
        end
    }
)
