local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

return function(Window)
    local generic = import('env/util/generic')
    local Hook = import('env/lib/hook')

    local domagic, docmagic, clientdata, combat = generic.FindInstancesInReplicatedStorage('DoMagic', 'DoClientMagic', 'ClientData', 'Combat')

    local function getPlayerFromInput(input)
        -- try this one first
        local players = Players:GetPlayers()
        for i = #players, 1, -1 do
            if players[i].Name:sub(1, #input) == input or players[i].DisplayName:sub(1, #input) == input then
                return players[i]
            end
        end
        -- if not try getting the userid by typing their fullname!
        local success, userid = pcall(Players.GetUserIdFromNameAsync, Players, input)
        if success then
            generic.NotifyUser('Found "' .. input .. "'s UserId!", 1)
            return userid
        end
        return nil
    end

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
                        local realArgs = {...}
                        local SpellName = tostring(realArgs[2])
                        local isSpoofed = spoofedSpells[SpellName]
                        if isSpoofed == true then
                            local fakeArgs = {unpack(realArgs)}
                            if SpellName == "Lightning Flash" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Origin = realArgs[3].Origin
                                fakeArgs[3].End = generic.GetMousePositionFromHook()
                            elseif SpellName == "Lightning Barrage" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Direction = if isMouseHitOverriden or playerMouse.Target then CFrame.lookAt(playerMouse.Hit.Position - Vector3.new(0, 17, 0), playerMouse.Hit.Position) else realArgs[3].Direction
                            elseif SpellName == "Refraction" then
                                fakeArgs[3] = if isMouseHitOverriden or playerMouse.Target then CFrame.lookAt(playerMouse.Hit.Position - Vector3.new(0, 20, 0), playerMouse.Hit.Position) else realArgs[3]
                            elseif SpellName == "Splitting Slime" or SpellName == "Illusive Atake" then
                                fakeArgs[3] =  if isMouseHitOverriden or playerMouse.Target then CFrame.new(playerMouse.Hit.Position) else realArgs[3]
                            elseif SpellName == "Blaze Column" then
                                fakeArgs[3] = if isMouseHitOverriden or playerMouse.Target then CFrame.new(playerMouse.Hit.Position) * CFrame.Angles(math.pi / 2, math.pi / 2, 0) else realArgs[3]
                            elseif SpellName == "Water Beam" then
                                fakeArgs[3] = {}
                                fakeArgs[3].Origin = if isMouseHitOverriden or playerMouse.Target then playerMouse.Hit.Position + Vector3.new(0, 7, 0) else realArgs[3].Origin
                            elseif SpellName == "Orbital Strike" then
                                fakeArgs[3] = if isMouseHitOverriden or playerMouse.Target then CFrame.lookAt(playerMouse.Hit.Position, playerMouse.Hit.Position - Vector3.new(0, 20, 0)) else realArgs[3]
                            elseif SpellName == "Orbs of Enlightenment" then
                                local c = {}
                                for i = 1, #realArgs[3].Coordinates do
                                    c[i] = if isMouseHitOverriden or playerMouse.Target then CFrame.new(playerMouse.Hit.Position + Vector3.new(0, 2, 0)) else CFrame.identity
                                end
                                local newArgs = {
                                    Origin = if isMouseHitOverriden or playerMouse.Target then CFrame.new(playerMouse.Hit.Position + Vector3.new(0, 2, 0)) else realArgs[3].Origin,
                                    Coordinates = c
                                }
                                fakeArgs[3] = newArgs
                            end
                            
                            return remoteHook:Call(self, unpack(fakeArgs))
                        else
                            local fakeArgs = {unpack(realArgs)}
                            if SpellName == "Lightning Flash" then
                                if isMouseHitOverriden then
                                    local hrp = Players.LocalPlayer.Character.FindFirstChild(Players.LocalPlayer.Character, "HumanoidRootPart")
                                    if hrp then
                                        fakeArgs[3] = {}
                                        fakeArgs[3].Origin = hrp.Position
                                        fakeArgs[3].End = hrp.Position + ((generic.GetMousePositionFromHook() - hrp.Position).Unit * 50)
                                    end
                                end
                            elseif SpellName == "Rainbow Dash" then
                                if isMouseHitOverriden then
                                    local hrp = Players.LocalPlayer.Character.FindFirstChild(Players.LocalPlayer.Character, "HumanoidRootPart")
                                    if hrp then
                                        fakeArgs[3] = {}
                                        fakeArgs[3].Dir = CFrame.lookAt(hrp, generic.GetMousePositionFromHook())
                                    end
                                end
                            end
                            
                            return remoteHook:Call(self, unpack(fakeArgs))
                        end
                    elseif (self == docmagic) then
                    elseif (self == clientdata) then
                        local realArgs = {...}
                        local tbl = HttpService.JSONDecode(HttpService, realArgs[1])
                        tbl.Cooldowns = {}
                        tbl = HttpService.JSONEncode(HttpService, tbl)
                        return remoteHook:Call(self, tbl)
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

        local function buildPunchAuraSection()
            local blacklistedPlayers = {}

            local MIN_DIST = 10--studs

            local playerNameFill = generic.NewAutofill("Punch Aura", getPlayerFromInput)
            local auraEnabled = false

            local function findNearestPlayer()
                local t = {}
                for _, player in ipairs(Players:GetPlayers()) do
                    if 
                        player == Players.LocalPlayer or
                        blacklistedPlayers[player.UserId]
                    then continue end
                    
                    local foundRootPart = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
                    if foundRootPart then
                        local rootPart = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            local dist = (foundRootPart.Position - rootPart.Position).Magnitude
                            if dist <= MIN_DIST then
                                table.insert(t, {
                                    dist = dist,
                                    player = player
                                })
                            end
                        end
                    end
                end
                table.sort(t, function(a, b) return a.dist < b.dist end)
                return if t[1] then t[1].player else nil
            end

            local function clearPlayerBlacklistData(data)
                if data.listenOnRemoving then
                    data.listenOnRemoving:Disconnect()
                    data.listenOnRemoving = nil
                end
            end

            utilityTab:CreateToggle{
                Name = "Enable Punch Aura",
                Callback = function(toggled)
                    auraEnabled = toggled
                end,
            }

            utilityTab:CreateInput{
                Name = "Blacklist Player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(text)
                    local success, foundPlayer = playerNameFill.TryAutoFillFromInput(text)
                    if success then
                        if (type(foundPlayer) == "number") then
                            generic.NotifyUser("Gave full name of a player but they're not in the server!", 4)
                            return
                        end
                        local listenOnRemoving; listenOnRemoving = foundPlayer.Destroying:Once(function()
                            listenOnRemoving:Disconnect()
                            listenOnRemoving = nil

                            generic.NotifyUser(string.format("%s has left the server. When they rejoin they'll still be blacklisted until then! (You can only unblacklist them when they returned from the server!)", foundPlayer.Name), 2)
                        end)
                        blacklistedPlayers[foundPlayer.UserId] = {
                            listenOnRemoving = listenOnRemoving
                        }
                    end
                end
            }

            utilityTab:CreateInput{
                Name = "Unblacklist Player",
                Placeholder = "Player DisplayName / Name",
                Callback = function(text)
                    local success, foundPlayerOrUserId = playerNameFill.TryAutoFillFromInput(text)
                    if success then
                        local id
                        if (type(foundPlayerOrUserId) == "number") then
                            id = foundPlayerOrUserId
                        else
                            id = foundPlayerOrUserId.UserId
                        end
                        local indexOf = blacklistedPlayers[id]
                        if indexOf then
                            clearPlayerBlacklistData(blacklistedPlayers[id])
                            blacklistedPlayers[id] = nil
                        end
                    end
                end
            }

            utilityTab:CreateButton{
                Name = "Clear All Blacklist",
                Callback = function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player == Players.LocalPlayer then continue end
                        local indexOf = blacklistedPlayers[player.UserId]
                        if indexOf then
                            clearPlayerBlacklistData(blacklistedPlayers[player.UserId])
                            blacklistedPlayers[player.UserId] = nil
                        end
                    end
                end
            }

            Globe.Maid:GiveTask(RunService.Stepped:Connect(function()
                if not auraEnabled then return end
                local foundPlayer = findNearestPlayer()
                if foundPlayer then
                    combat:FireServer(1)
                    combat:FireServer(foundPlayer.Character)
                end
            end))
        end

        buildPunchAuraSection()
        buildTechDiscSection()
    end
end