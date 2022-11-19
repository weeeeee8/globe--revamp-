local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rayfield = import('env/rayfield')

local ERROR_CONSTANTS = {}
local DEFAULT_NOTIFICATION_LIFETIME = 3--seconds

local generic = {}

function generic.NotifyUser(content: string, infoLevel: number)
    local title = string.format('[%s] Globe Debug', if infoLevel == 1 then "INFO" elseif infoLevel == 2 then "WARNING" elseif infoLevel == 3 then "ERROR" else "FATAL ERROR")
    rayfield:Notify{
        Title = title,
        Content = content,
        Duration = DEFAULT_NOTIFICATION_LIFETIME
    }
end

function generic.LenDictionary(dictionary)
    local l = 0
    table.foreach(dictionary, function()
        l += 1
    end)
    return l
end

function generic.SafeDestroy(instance: Instance?)
    if instance then
        instance:Destroy()
    end
end

function generic.FindInstancesInReplicatedStorage(...)
    local outputs = {}
    for _, k in ipairs({...}) do
        table.insert(outputs, ReplicatedStorage:FindFirstChild(k, true))
    end
    return unpack(outputs)
end

function generic.GetPlayerBodyPart(bodyPartName)
    return if Players.LocalPlayer.Character then Players.LocalPlayer.Character:FindFirstChild(bodyPartName, true) else nil
end

function generic.NewConnectionsHolder()
    local connections = {}
    return {
        Insert = function(self, connection)
            connections[#connections+1] = connection
        end,
        Remove = function(self, index)
            connections[index]:Disconnect()
            connections[index] = nil
        end,
        DisconnectAll = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            table.clear(connections)
        end,
        Destroy = function(self)
            self:DisconnectAll()
            connections = nil
        end
    }
end

function generic.NewAutofill(name: string, template: {string} | (input: string) -> any?)
    local template = template
    return {
        TryAutoFillFromInput = function(text: string)
            if #text <= 0 then return false, string.format('"%s" is an empty string!', name) end
            if (type(template) == "function") then
                local output = template(text)
                if output then
                    return true, output
                end
            else
                for i = #template, 1, -1 do
                    if template[i]:sub(1, #text) == text then
                        return true, template[i]
                    end
                end
            end
            return false, string.format('Cannot find an autofill correction for "%s"', text)
        end,
        ChangeTemplate = function(newTemplate: {string})
            template = newTemplate
        end
    }
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
                t[k] = callback(k)
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