local Players = game:GetService("Players")

local generic = {}

function generic.GetPlayerBodyPart(bodyPartName)
    return if Players.LocalPlayer.Character then Players.LocalPlayer.Character:FindFirstChild(bodyPartName, true) else nil
end

function generic.NewStack()
    local stackObj = {}
    return {
        Push = function(input: any)
            stackObj[#stackObj+1] = input
        end,
        Pop = function()
            if #stackObj <= 0 then warn('[GLOBE] C STACK UNDERFLOW') return nil end
            local output = stackObj[#stackObj]
            stackObj[#stackObj] = nil
            return output
        end,
        Len = function()
            return #stackObj
        end,
        Clear = function()
            table.clear(stackObj)
        end
    }
end

function generic.MakeSet(...)
    local t = {} for _, k in ipairs({...}) do t[k] = true end
    return {
        override = function(self, callback)
            for k in pairs(t) do
                t[k] = callback[k]
            end
            return self
        end,
        get = function()
            return t
        end
    }
end

function generic.OnPlayerCharacterAdded(fn: (character: Model) -> nil)
   if Players.LocalPlayer.Character then fn(Players.LocalPlayer.Character) end
   return Players.LocalPlayer.CharacterAdded:Connect(fn)
end

return generic