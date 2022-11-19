-- Hook
-- 0866
-- October 4, 2020

--[[

    Constructor:

        hook = Hook.new(closure [, callback])

    Fields:

        hook.Closure        [The original closure] (Read-only)
        hook.Callback       [The callback to hook to the closure; Defaults to the original closure]

    Methods:

        hook:Call(...)      -> Results...
        >   Calls the original closure with the given
            arguments and returns the results

        hook:Reset()        -> Void
        >   Sets Hook.Callback to the original closure

    Events:

        hook.Invoked:Connect(callback)
        >   Fires when the *hooked closure was called


    Examples:

        local Hook = loadfile("Hook.lua")()

        hook = Hook.new(spawn, function(...)
            print("Spawn was intercepted with arguments:", ...)
            return hook:Call(...)
        end)

        spawn(function() end)

        -- outputs: Spawn was intercepted with arguments: func 0x123

        local invokeConnection = hook.Invoked:Connect(function(...)
            warn("Spawn was called with arguments:", ...)
        end)

        spawn(function()
            wait(1)
            invokeConnection:Disconnect()
        end)

        -- outputs: Spawn was called with arguments: func 0x456
        --          Spawn was intercepted with arguments: func 0x456


    Why:

        Hook offers a more extensive use of hookfunction, adding more
        features. This uses the 'shared' global, thus upvalue count is
        not limited.

    Why not just use hookfunction:

        Hookfunction is powerful but can be difficult to use on its
        own due to the upvalue count of the callback being limited to
        that of the original closure.

--]]



local Hook = {}
Hook.__index = function(self, key)
    return if Hook[key] then Hook[key] else rawget(self, key)
end

local hookfunction = assert(getfenv(0).hookfunction, "Hook is not supported on this exploit")

local hooks = getgenv().__hooks or {}
getgenv().__hooks = hooks


function Hook.new(closure, callback)

    do
        -- Verify arguments:
        assert(type(closure) == "function", "First argument 'closure' must be a function")
        assert(type(callback) == "function" or callback == nil, "Second argument 'callback' must be a function or nil")
    
        -- Check for pre-existing hook:
        if (hooks[closure]) then
            if (callback) then
                hooks[closure]._callback = callback
            end
            return hooks[closure]
        end

    end

    local function call(...)
        local hook = hooks[debug.getinfo(getfenv(1)).func]
        hook._invoked:Fire(...)
        return hook._callback(...)
    end

    local invoked = Instance.new("BindableEvent")

    local self = setmetatable({
        Invoked = invoked.Event;
        _invoked = invoked;
        _callback = callback;
        _closure = hookfunction(closure, call);
    }, Hook)
    self.Callback = callback
    self.Closure = self._closure

    hooks[closure] = self
    --hooks[call] = self

    return self

end


function Hook:Call(...)
    return self._closure(...)
end


function Hook:Reset()
    self._callback = self._closure
end

return Hook