local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

return function(Window)
    local generic = import('env/util/generic')
    local Hook = import('env/lib/hook')

    local domagic, docmagic, clientdata, combat = generic.FindInstancesInReplicatedStorage('DoMagic', 'DoClientMagic', 'ClientData', 'Combat')

    local mainTab = Window:CreateTab("Elemental Battlegrounds") do
        local playerMouse = Players.LocalPlayer:GetMouse()

        local validNameCalls = {'FireServer', 'InvokeServer'}
        local isMouseHitOverriden = false
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
            mainTab:CreateSection('Spell Exploit Options')
            mainTab:CreateParagraph{Title = 'Information: ', Content = [[Enabling any of these options will spoof the data that are to be sent to the server.
            When using Instant Casting, it'll be incrementing from the index 1 but can be locked by enabling "Lock Pattern Index"!]]}

            for k in pairs(spoofedSpells) do
                mainTab:CreateToggle{
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
            
            local espEnabled = false
            local trackedPlayers = {}
            local showTrackBeam = false

            local textFont = Drawing.Fonts.Monospace
            local textSize = 14
            local textColor = Color3.fromRGB(239, 137, 42)

            local function instantiateLabel(player)
                local label = Drawing.new('Text')
                label.TextFont = textFont
                label.Size = textSize
                label.Color = textColor
                label.Outline = true
                label.OutlineColor = Color3.new(0, 0, 0)
                label.TextBounds = Vector2.new(workspace.CurrentCamera.ViewportSize.X, 100)
                label.TextTransparency = 0.7
                label.Center = true

                trackedPlayers[player] = label
            end

            local colorPicker = utilityTab:CreateColorpicker{
                CurrentColor = Color3.new(1, 0, 0)
            }
            Globe.Maid:GiveTask(colorPicker:OnChanged(function(newColor)
                textColor = newColor
            end))
            
            utilityTab:CreateToggle{
                Name = "Enable ESP",
                CurrentValue = false,
                Callback = function(toggled)
                    espEnabled = toggled
                end,
            }

            for _, player in ipairs(Players:GetPlayers()) do
                if player == Players.LocalPlayer then continue end
                instantiateLabel(player)
            end
            Globe.Maid:GiveTask(Players.PlayerAdded:Connect(instantiateLabel))
            Globe.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
                local indexOf = trackedPlayers[player]
                if indexOf then
                    trackedPlayers[player]:Destroy()
                    trackedPlayers[player] = nil
                end
            end))

            Globe.Maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
                for player, label in pairs(trackedPlayers) do
                    if not espEnabled then
                        if label.Visible then
                            label.Visible = false
                        end
                    else
                        if label.Color ~= textColor then
                            label.Color = textColor
                        end

                        local foundHumanoidRootPart = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
                        if foundHumanoidRootPart then
                            local rootPart = generic.GetPlayerBodyPart('HumanoidRootPart')
                            local vector, isInScreen = workspace.CurrentCamera:WorldToViewportPoint()
                            if rootPart and isInScreen then
                                if not label.Visible then
                                    label.Visible = true
                                end

                                local dist = (foundHumanoidRootPart.Position - rootPart.Position).Magnitude
                                label.Position = Vector2.new(vector.X, vector.Y - 50)

                                local newText = string.format('[%i] %s (%i studs)', foundHumanoidRootPart.Parent.Humanoid.Health, player.Name, math.floor(dist))
                                if label.Text ~= newText then
                                    label.Text = newText
                                end
                            else
                                if label.Visible then
                                    label.Visible = false
                                end
                            end
                        else
                            if label.Visible then
                                label.Visible = false
                            end
                        end
                    end
                end
            end))
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