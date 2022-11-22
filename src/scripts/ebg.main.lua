local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

return function(Window)
    local generic = import('env/util/generic')
    local calculateTrajectory = import('env/util/calculateTrajectory')
    local Hook = import('env/lib/hook')

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
    
    local playerNameFill = generic.NewAutofill("Name Fill", getPlayerFromInput)
    local domagic, docmagic, clientdata, combat, sendloadout = generic.FindInstancesInReplicatedStorage('DoMagic', 'DoClientMagic', 'ClientData', 'Combat')

    local playerMouse = Players.LocalPlayer:GetMouse()

    local isMouseHitOverriden = false
    local overridenMouseCFrame = playerMouse.Hit

    local mainTab = Window:CreateTab("Elemental Battlegrounds") do
        local spoofedSpells = generic.MakeSet(
            'Lightning Flash',
            'Lightning Barrage',
            'Orbs of Enlightenment',
            'Orbital Strike',
            'Refraction',
            'Water Beam',
            'Splitting Slime',
            'Illusive Atake',
            'Blaze Column',
            'Amaurotic Lambent',
            'Gravital Globe',
            'Murky Missiles',
            'Skeleton Grab',
            'Sewer Burst'
        ):override(function() return false end):get()

        local remoteHookOld; remoteHookOld = hookmetamethod(game, '__namecall', function(self, ...)
            if not checkcaller() then
                if getnamecallmethod() == "InvokeServer" then
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
                            elseif SpellName == "Blaze Column" or SpellName == "Skeleton Grab" then
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
                            elseif SpellName == "Amaurotic Lambent" or SpellName == "Gravital Globe" then
                                fakeArgs[3] = {
                                    lastPos = if isMouseHitOverriden or playerMouse.Target then playerMouse.Hit.Position + Vector3.new(0, 2, 0) else realArgs[3].lastPos
                                }
                            elseif SpellName == "Murky Missiles" then
                                fakeArgs[3] = {
                                    lastMousePosition = if isMouseHitOverriden or playerMouse.Target then CFrame.new(playerMouse.Hit.Position + Vector3.new(0, 2, 0)) else realArgs[3].lastMousePosition
                                }
                            elseif SpellName == "Sewer Burst" then
                                local mousePosition = if isMouseHitOverriden or playerMouse.Target then CFrame.new(playerMouse.Hit.Position + Vector3.new(0, 2, 0)) else realArgs[3].Mouse
                                fakeArgs[3] = {
                                    Mouse = mousePosition,
                                    Camera = mousePosition - Vector3.new(0, 4, 0),
                                    Spawn = mousePosition,
                                    Origin = CFrame.new(mousePosition)
                                }
                            end
                            
                            return remoteHookOld(self, unpack(fakeArgs))
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
                            
                            return remoteHookOld(self, unpack(fakeArgs))
                        end
                    end
                if getnamecallmethod() == "FireServer" then
                    elseif (self == docmagic) then
                    elseif (self == clientdata) then
                        local realArgs = {...}
                        local tbl = HttpService.JSONDecode(HttpService, realArgs[1])
                        tbl.Cooldowns = {}
                        tbl = HttpService.JSONEncode(HttpService, tbl)
                        return remoteHookOld(self, tbl)
                    end
                end
            end

            return remoteHookOld(self, ...)
        end)

        local mouseHook; mouseHook = hookmetamethod(game, '__index', function(self, key)
            if not checkcaller() then
                if self == playerMouse then
                    if isMouseHitOverriden then
                        if key == "Hit" then
                            return overridenMouseCFrame
                        end
                    end
                end
            end
            return mouseHook(self, key)
        end)

        Globe.Maid:GiveTask(function()
            hookmetamethod(game, '__namecall', remoteHookOld)
            hookmetamethod(playerMouse, '__index', mouseHook)
        end)

        local function buildSpellSection()
            mainTab:CreateSection('Spell Exploit Options')
            mainTab:CreateParagraph{Title = 'Information: ', Content = [[Enabling any of these options will spoof the data that are to be sent to the server.
            When using Instant Casting, it'll be incrementing from the index 1 but can be locked by enabling "Lock Pattern Index"!]]}

            for k in pairs(spoofedSpells) do
                mainTab:CreateToggle{
                    Name = "Spoof " .. k,
                    Flag = k .. "SavedValue",
                    CurrentValue = false,
                    Callback = function(toggled)
                        spoofedSpells[k] = toggled
                    end,
                }
            end
        end

        local function buildDisorderIgnitionSection()
            mainTab:CreateSection("Disorder Ignition Options")
        end

        buildSpellSection()
        buildDisorderIgnitionSection()
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
                                task.delay(1, c.Destroy, c)
                            end
                        end))
                        connectionsHolder:Insert(ClientEffectsFolder.ChildAdded:Connect(function(c)
                            if c.Name:lower() == "LightDisc" or c.Name:lower() == "DeadlyDisc" then
                                task.delay(1, c.Destroy, c)
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

        local function buildAdvancedTargetingSection()
            utilityTab:CreateSection('Advanced Targeting Options')

            local MIN_DIST = 200

            local targetingEnabled = false
            local targetType = 'locked'
            local targetPlayer = nil
            local blacklistedPlayers = {}

            local pointsFolder = workspace:FindFirstChild(".points") or Instance.new("Folder", workspace)
            pointsFolder.Name = ".points"

            local numsOfPoints = 10
            local velocityTime = 1
            local activelySimulatingObstructionCheck = false
            local pointIndex = 4
            local points = {}
            points.target = nil
            points.unrenderCF = CFrame.new(0, 10e5, 0)
            points.lastTimeVelocities = {}
            points.connectionsHolder = generic.NewConnectionsHolder()
            --players
            local function onOtherPlayerAdded(player)
                points.lastTimeVelocities[player.UserId] = {
                    lastVelocity = Vector3.zero,
                    velocity = Vector3.zero,
                    position = Vector3.zero,
                    movementspeed = 16,
                }
                local profile = points.lastTimeVelocities[player.UserId]
                player.CharacterAdded:Connect(function(char)
                    local hum, rootpart = char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
                    local function onSpeedChanged()
                        profile.movementspeed = hum.WalkSpeed
                    end

                    local function onVelocityChanged()
                        profile.velocity = rootpart.AssemblyLinearVelocity
                    end
                    
                    local function onPositionChanged()
                        profile.position = rootpart.Position
                    end

                    onSpeedChanged()
                    onVelocityChanged()
                    onPositionChanged()
                    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(onSpeedChanged)
                    rootpart:GetPropertyChangedSignal("Position"):Connect(onPositionChanged)
                    rootpart:GetPropertyChangedSignal("AssemblyLinearVelocity"):Connect(onVelocityChanged)
                end)
            end
            points.connectionsHolder:Insert(Players.PlayerAdded:Connect(onOtherPlayerAdded))
            points.connectionsHolder:Insert(Players.PlayerRemoving:Connect(function(player)
                local indexOf = points.lastTimeVelocities[player.UserId]
                if indexOf then
                    points.lastTimeVelocities[player.UserId] = nil
                end
            end))
            for _, player in ipairs(Players:GetPlayers()) do
                if player == Players.LocalPlayer then continue end
                onOtherPlayerAdded(player)
            end
            --end players
            function points:new()
                local sphere = Instance.new("Part")
                sphere.Anchored = true
                sphere.Shape = Enum.PartType.Ball
                sphere.Material = Enum.Material.Neon
                sphere.CastShadow = true
                sphere.CanCollide = false
                sphere.CanQuery = false
                sphere.Size = Vector3.one * 1.85
                sphere.Parent = pointsFolder
                table.insert(self, {
                    active = false,
                    shown = false,
                    _shownDirty = false,
                    part = sphere,
                    position = Vector3.yAxis * 10e4
                })

                return #self
            end
            function points:remove(index)
                local output = table.remove(index)
                output.part:Destroy()
                return output
            end
            function points:destroy()
                while #self > 1 do
                    local point = self:remove(#self)
                    table.clear(point)
                end
                self.connectionsHolder:Destroy()
                table.clear(self.lastTimeVelocities)
                table.clear(self)
            end
            function points:getActivePoint()
                for _, point in ipairs(self) do
                    if point.active then
                        return point
                    end
                end
                return nil
            end
            function points:getPositionFromInterval(a, b, c)
                return a + (b * c)
            end
            function points:update(deltaTime)
                local foundProfile = self.lastTimeVelocities[self.target.UserId]
                if not foundProfile then
                    for i = #self, 1, -1 do
                        local point = self[i]
                        if point._shownDirty then
                            point._shownDirty = false
                            point.part.CFrame = points.unrenderCF
                        end
                    end
                    return
                end
                local normalizedVelocity = foundProfile.lastVelocity - foundProfile[self.target.UserId].velocity
                for i = #self, 1, -1 do
                    local point = self[i]
                    point.index = i == pointIndex
                    if point.shown then
                        point.position = self:getPositionFromInterval(foundProfile.position, normalizedVelocity, deltaTime * foundProfile.movementspeed * (i / #self))
                        point.part.CFrame = CFrame.new(point.position)
                        local newColor = if point.active then BrickColor.Green() else BrickColor.Red()
                        if point.part.BrickColor ~= newColor then
                            point.part.BrickColor = newColor
                        end
                        point._shownDirty = true
                    else
                        if point._shownDirty then
                            point._shownDirty = false
                            point.part.CFrame = points.unrenderCF
                        end
                    end
                end
            end

            local function findNearestPlayerFromPosition(position)
                local t = {}
                for _, player in ipairs(Players:GetPlayers()) do
                    if 
                        player == Players.LocalPlayer or
                        blacklistedPlayers[player.UserId]
                    then continue end
                    
                    local foundRootPart = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
                    if foundRootPart then
                        local dist = (foundRootPart.Position - position).Magnitude
                        if dist <= MIN_DIST then
                            table.insert(t, {
                                dist = dist,
                                player = player
                            })
                        end
                    end
                end
                table.sort(t, function(a, b) return a.dist < b.dist end)
                return if t[1] then t[1].player else nil
            end

            local function clearPlayerBlacklistData(data)
            end

            for i = 1, numsOfPoints do
                points:new()
            end

            local toggle = utilityTab:CreateToggle{
                Name = "Enable Advanced Targeting",
                Callback = function(toggled)
                    targetingEnabled = toggled
                end
            }

            utilityTab:CreateKeybind{
                Name = "Toggle bind",
                CurrentKeybind = "C",
                Callback = function()
                    toggle:Set(not targetingEnabled)
                end
            }

            local input = utilityTab:CreateInput{
                Name = "Set Target Player",
                PlaceholderText = "Player DisplayName / Name",
                Callback = function(text)
                    local success, foundPlayer = playerNameFill.TryAutoFillFromInput(text)
                    if success then
                        if (type(foundPlayer) == "number") then
                            generic.NotifyUser("Gave full name of a player but they're not in the server!", 4)
                            return
                        end 

                        generic.NotifyUser(string.format("[Targeting] %s is currently being targeted! (Locked targeting option)", foundPlayer.Name), 2)
                        targetPlayer = foundPlayer
                    else
                        targetPlayer = nil
                    end
                end
            }

            utilityTab:CreateButton{
                Name = "Clear field",
                Callback = function()
                    input:Set('', true)
                end
            }

            utilityTab:CreateInput{
                Name = "Blacklist Player",
                PlaceholderText = "Player DisplayName / Name",
                Callback = function(text)
                    local success, foundPlayer = playerNameFill.TryAutoFillFromInput(text)
                    if success then
                        if (type(foundPlayer) == "number") then
                            generic.NotifyUser("Gave full name of a player but they're not in the server!", 4)
                            return
                        end
                        blacklistedPlayers[foundPlayer.UserId] = {}
                    end
                end
            }

            utilityTab:CreateInput{
                Name = "Unblacklist Player",
                PlaceholderText = "Player DisplayName / Name",
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

            utilityTab:CreateDropdown{
                Name = "Targeting Type",
                Options = {'Locked', 'Mouse', 'Character'},
                CurrentOption = 'Locked',
                Flag = 'SavedTargetingType',
                Callback = function(option)
                    targetType = option
                end
            }

            Globe.Maid:GiveTask(function()
                points:destroy()
            end)

            Globe.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
                if blacklistedPlayers[player.UserId] then
                    generic.NotifyUser(string.format("[Targeting] %s has left the server. When they rejoin they'll still be blacklisted until then! (You can only unblacklist them when they returned from the server!)", player.Name), 2)
                end

                if targetPlayer == player then
                    generic.NotifyUser(string.format("[Targeting] %s has left the server, no active target!", player.Name), 2)
                    targetPlayer = nil
                    input:Set('', true)
                end
            end))

            Globe.Maid:GiveTask(RunService.Stepped:Connect(function(_, dt)
                points:update(dt)

                if targetingEnabled then
                    local foundRootPart
                    local rootPart = generic.GetPlayerBodyPart("HumanoidRootPart")
                    if rootPart then
                        if targetType == 'locked' then
                            if targetPlayer then
                                foundRootPart = if targetPlayer.Character then targetPlayer.Character:FindFirstChild("HumanoidRootPart") else nil
                            end
                        elseif targetType == 'mouse' then
                            local foundPlayer = findNearestPlayerFromPosition(generic.GetMousePositionFromHook())
                            if foundPlayer then
                                foundRootPart = if foundPlayer.Character then foundPlayer.Character:FindFirstChild("HumanoidRootPart") else nil
                            end
                        elseif targetType == 'character' then
                            local foundPlayer = findNearestPlayerFromPosition(rootPart.Position)
                            if foundPlayer then
                                foundRootPart = if foundPlayer.Character then foundPlayer.Character:FindFirstChild("HumanoidRootPart") else nil
                            end
                        end

                        local mousePosition = Vector3.zero
                        if foundRootPart then
                            points.target = targetPlayer
                            mousePosition = points:getActivePoint().position
                        end

                        isMouseHitOverriden = true
                        overridenMouseCFrame = CFrame.new(mousePosition)
                    else
                        isMouseHitOverriden = false
                    end
                else
                    isMouseHitOverriden = false
                end
            end))
        end

        local function buildPunchAuraSection()
            utilityTab:CreateSection("Punch Aura Options")

            local MIN_DIST = 10--studs

            local auraEnabled = false
            local blacklistedPlayers = {}

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
            end

            local toggle = utilityTab:CreateToggle{
                Name = "Enable Punch Aura",
                Callback = function(toggled)
                    auraEnabled = toggled
                end,
            }

            utilityTab:CreateKeybind{
                Name = "Toggle bind",
                CurrentKeybind = "Z",
                Callback = function()
                    toggle:Set(not auraEnabled)
                end
            }

            utilityTab:CreateInput{
                Name = "Blacklist Player",
                PlaceholderText = "Player DisplayName / Name",
                Callback = function(text)
                    local success, foundPlayer = playerNameFill.TryAutoFillFromInput(text)
                    if success then
                        if (type(foundPlayer) == "number") then
                            generic.NotifyUser("Gave full name of a player but they're not in the server!", 4)
                            return
                        end
                        blacklistedPlayers[foundPlayer.UserId] = {}
                    end
                end
            }

            utilityTab:CreateInput{
                Name = "Unblacklist Player",
                PlaceholderText = "Player DisplayName / Name",
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

            
            Globe.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
                if blacklistedPlayers[player.UserId] then
                    generic.NotifyUser(string.format("[Punch Aura] %s has left the server. When they rejoin they'll still be blacklisted until then! (You can only unblacklist them when they returned from the server!)", player.Name), 2)
                end
            end))

            Globe.Maid:GiveTask(RunService.Stepped:Connect(function()
                if not auraEnabled then return end
                local foundPlayer = findNearestPlayer()
                if foundPlayer then
                    combat:FireServer(1)
                    combat:FireServer(foundPlayer.Character)
                end
            end))
        end

        buildTechDiscSection()
        buildPunchAuraSection()
        buildAdvancedTargetingSection()
    end
end