local Players = game:GetService("Players")

return function(Window)
    local generic = import('env/util/generic')
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

        local remoteHook; remoteHook = Hook.new('ebg.remotenamecall', getrawmetatable(game).__namecall, newcclosure(function(self, ...)
            if not checkcaller() then
                if validNameCalls[getnamecallmethod()] then
                    if (self == domagic) then
                    elseif (self == docmagic) then
                    end
                end
            end

            return remoteHook:Call(self, ...)
        end))

        local mouseHook; mouseHook = Hook.new('ebg.mousehook', getrawmetatable(playerMouse).__index, newcclosure(function(self, key: string)
            if not checkcaller() then
                if isMouseHitOverriden then
                    if key:lower() == "hit" then
                        return overridenMouseCFrame
                    end
                end
            end
            return mouseHook:Call(self, key)
        end))

        local function buildSpellSection()
            tab:CreateSection('Spell Exploit Options')
            tab:CreateParagraph{Title = 'Information: ', Content = [[Enabling any of these options will spoof the data that are to be sent to the server.
            When using Instant Casting, it'll be incrementing from the index 1 but can be locked by enabling "Lock Pattern Index"!]]}

            for k in pairs(spoofedSpells) do
                tab:CreateToggle{
                    Name = "Spoof " .. k,
                    CurrentValue = false,
                    Callback = function(toggled)
                        spoofedSpells[k] = toggled
                    end,
                }
            end
        end

        buildSpellSection()
    end

    local utilityTab = Window:CreateTab("Utility - Elemental Battlegrounds") do
        local function buildCustomEspSection()
            utilityTab:CreateSection('ESP')
            
            local trackedPlayers = {}
            local showTrackBeam = false

            local textFont = Drawing.Fonts.Monospace
            local textSize = 14
            local textColor = Color3.fromRGB(239, 137, 42)

            local function instantiateLabel()
                local label = Drawing.new('Text')
            end

            local colorPicker = utilityTab:CreateColorpicker{CurrentColor = Color3.fromRBG(220, 10, 0), Flag = "ESPLabelColor"}
        end

        local function buildTechDiscSection()
            local connectionsHolder = generic.NewConnectionsHolder()
            local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
            local ClientEffectsFolder = workspace:WaitForChild('.Ignore'):WaitForChild('.LocalEffects')

            utilityTab:CreateSection('Disable Techlag (Technology Light Disk Bug) State')
            utilityTab:CreateToggle{
                Name = "Enabled",
                CurrentValue = true,
                Callback = function(toggled)
                    if toggled then
                        connectionsHolder:Insert(PlayerScripts.ChildAdded:Connect(function(c)
                            if c.Name:lower() == "DiscScript" then
                                task.delay(0.07, c.Destroy, c)
                            end
                        end))
                        connectionsHolder:Insert(ClientEffectsFolder.ChildAdded:Connect(function(c)
                            if c.Name:lower() == "LightDisc" or c.Name:lower() == "DeadlyDisc" then
                                task.delay(0.07, c.Destroy, c)
                            end
                        end))
                    else
                        connectionsHolder:DisconnectAll()
                    end
                end
            }
            Globe.Maid:GiveTask(function()
                connectionsHolder:Destroy()
            end)
        end

        buildTechDiscSection()
        buildCustomEspSection()
    end
end