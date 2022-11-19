local Players = game:GetService("Players")

return function(Window)
    local generic = import('env/lib/generic')
    local Hook = import('env/lib/hook')

    local domagic, docmagic, clientdata, combat = generic.FindInstancesInReplicatedStorage('DoMagic', 'DoClientMagic', 'ClientData', 'Combat')

    local tab = Window:CreateTab("Elemental Battlegrounds") do
        local playerMouse = Players.LocalPlayer:GetMouse()

        local validNameCalls = {'FireServer', 'InvokeServer'}
        local isMouseHitOverriden = false0
        local overridenMouseCFrame = playerMouse.Hit
        local spoofedSpells = generic.MakeSet(
            'Lightning Barrage',
            'Orbital Strike'
        ):get()

        local remoteHook; remoteHook = Hook.new(getrawmetatable(game).__namecall, function(self, ...)
            if not checkcaller() then
                if validNameCalls[getnamecallmethod()] then
                    if (self == domagic) then
                    elseif (self == docmagic) then
                    end
                end
            end

            return remoteHook:Call(self, ...)
        end)

        local mouseHook; mouseHook = Hook.new(getrawmetatable(playerMouse).__index, function(self, key: string)
            if not checkcaller() then
                if isMouseHitOverriden then
                    if key:lower() == "hit" then
                        return overridenMouseCFrame
                    end
                end
            end
            return mouseHook:Call(self, key)
        end)

        local function buildSpellSection()
            tab:CreateSection('Spell Exploit Options')
            tab:Paragraph('Information: ', [[Enabling any of these options will spoof the data that are to be sent to the server.
            When using Instant Casting, it'll be incrementing from the index 1 but can be locked by enabling "Lock Pattern Index"!]])
        end

        buildSpellSpoofSection()
    end

    local utility = Window:CreateTab("Utility - Elemental Battlegrounds") do
        
    end
end