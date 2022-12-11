local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

return function(Window)
    local generic = import('env/util/generic')

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
    local domagic, docmagic, clientdata, combat, reservekey, sendloadout = generic.FindInstancesInReplicatedStorage('DoMagic', 'DoClientMagic', 'ClientData', 'KeyReserve', 'Combat')

    local playerMouse = Players.LocalPlayer:GetMouse()

    local isMouseHitOverriden = false
    local overridenMouseCFrame = playerMouse.Hit

    local mainTab = Window:CreateTab("Elemental Battlegrounds") do
        local spoofedSpells = generic.MakeSet(
            'Lightning Flash',
            'Lightning Barrage',
            'Asteroid Belt',
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
            'Sewer Burst',
            'Arcane Guardian',
            'Ethereal Acumen'
        ):override(function() return false end):get()

        local remoteHookOld; remoteHookOld = hookmetamethod(game, '__namecall', function(self, ...)
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
                                Spawn = CFrame.new(mousePosition),
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

            local specialSpellNameAutofil = generic.NewAutofill("Spell Autofill", function(text)
                for k in pairs(spoofedSpells) do
                    if k:sub(1, #text) == text then
                        return k
                    end
                end
                return nil
            end)

            local parentsOfSpells = generic.MakeSet(
                'Light',
                'Technology',
                'Water',
                'Acid',
                'Nightmare',
                'Darkness',
                'Storm',
                'Illusion',
                'Slime',
                'Gravity',
                'Angel',
                'Fire'
            ):override(function(parent)
                parent = parent:lower()
                if parent == 'light' then
                    return generic.MakeSet('Orbs of Enlightenment', 'Amaurotic Lambent'):get()
                elseif parent == 'technology' then
                    return generic.MakeSet('Orbital Strike'):get()
                elseif parent == 'water' then
                    return generic.MakeSet('Water Beam'):get()
                elseif parent == 'acid' then
                    return generic.MakeSet('Sewer Burst'):get()
                elseif parent == 'nightmare' then
                    return generic.MakeSet('Skeleton Grab'):get()
                elseif parent == 'darkness' then
                    return generic.MakeSet('Murky Missiles'):get()
                elseif parent == 'storm' then
                    return generic.MakeSet('Lightning Flash', 'Lightning Barrage'):get()
                elseif parent == 'illusion' then
                    return generic.MakeSet('Refraction', 'Ethereal Acumen'):get()
                elseif parent == 'slime' then
                    return generic.MakeSet('Splitting Slime'):get()
                elseif parent == 'gravity' then
                    return generic.MakeSet('Gravital Globe'):get()
                elseif parent == 'angel' then
                    return generic.MakeSet('Arcane Guardian'):get()
                elseif parent == 'fire' then
                    return generic.MakeSet('Blaze Column'):get()
                end
                return true
            end):get()

            local function findSpellParentByName(text)
                for k, spells in pairs(parentsOfSpells) do
                    if spells[text] then
                        return k
                    end
                end
            end

            local patternLocked = false
            local patternIndex = 1
            local patternContainer = {}

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
            
            local label = mainTab:CreateLabel("Current Pattern Index: " .. patternIndex)
            mainTab:CreateInput{
                Name = "Add Spell to Pattern",
                Placeholder = "Spell Name",
                Callback = function(text)
                    local success, name = specialSpellNameAutofil.TryAutofillFromInput(text)
                    if success then
                        local index = #patternContainer+1
                        patternContainer[index] = {
                            [1] = findSpellParentByName(name),
                            [2] = name,
                        }
                        generic.NotifyUser('Spell "'.. name .. '" is set to index ' .. index .. '!', 1)
                    else
                        generic.NotifyUser('Spell "' .. text .. '" may: not have any available autofill placeholder; or not exist', 3)
                    end
                end
            }
            mainTab:CreateInput{
                Name = "Remove Spell from Pattern",
                Placeholder = "string | number",
                Callback = function(text)
                    if tonumber(text) then
                        local data = table.remove(patternContainer, tonumber(text))
                        generic.NotifyUser('Successfully removed Spell "'.. data[2] .. '" from pattern!', 1)
                    else
                        local success, name = specialSpellNameAutofil.TryAutofillFromInput(text)
                        if success then
                            for i, data in ipairs(patternContainer) do
                                if data[2] == name then
                                    table.remove(patternContainer, i)
                                    generic.NotifyUser('Successfully removed Spell "'.. name .. '" from pattern!', 1)
                                    break
                                end
                            end
                        else
                            generic.NotifyUser('Spell "' .. text .. '" may: not have any available autofill placeholder; or not exist', 3)
                        end
                    end
                end
            }
            mainTab:CreateButton{
                Name = "Clear Pattern",
                Callback = function()
                    table.clear(patternContainer)
                end
            }
            mainTab:CreateToggle{
                Name = "Lock Pattern",
                CurrentValue = true,
                Callback = function(toggled)
                    patternLocked = toggled
                end,
            }
            mainTab:CreateInput{
                Name = "Set Pattern Index",
                PlaceholderText = "number",
                Callback = function(text)
                    local num = tonumber(text)
                    if num then
                        num = math.clamp(num, 1, #patternContainer)
                        patternIndex = num
                        label:Set("Current Pattern Index: " .. patternIndex)
                    else
                        generic.NotifyUser("Expected a number!", 2)
                    end
                end
            }
            mainTab:CreateKeybind{
                Name = "Cast Spell by Index",
                CurrentKeybind = "V",
                Callback = function()
                    local foundSpellData = patternContainer[patternIndex]
                    if not spoofedSpells[foundSpellData[2]] then
                        generic.NotifyUser('Spell "' .. foundSpellData[2] .. '" should be spoofed! Skipping...', 2)
                    else
                        docmagic:FireServer(foundSpellData[1], foundSpellData[2])
                        domagic:InvokeServer(foundSpellData[1], foundSpellData[2])
                    end

                    if not patternLocked then
                        patternIndex += 1
                        if patternIndex > #patternContainer then
                            patternIndex = 1
                        end
                        label:Set("Current Pattern Index: " .. patternIndex)
                    end
                end
            }
        end

        local function buildDisorderIgnitionSection()
            mainTab:CreateSection("Disorder Ignition Options")

            local tpDelay = 3
            local voidPosition = Vector3.new(0, workspace.FallenPartsDestroyHeight + 2, 0)
            local lockedSpawnsPositionsOfMaps = {
                [2569625809]  = Vector3.new(-1100.52, 65.125, 282.28),
                [570158081] = Vector3.new(-1907.776, 126.015, -414.179),
                [537600204] = Vector3.new(1282.834, -83.49, -758.368),
            }

            local targetPlayer
            local teleportOption = "void"
        
            mainTab:CreateInput{
                Name = "Set Teleport Delay (3s-7s)",
                PlaceholderText = "number",
                Callback = function(text)
                    local num = tonumber(text)
                    if num then
                        num = math.clamp(num, 3, 7)
                        tpDelay = num
                        generic.NotifyUser("Set Teleport Delay to " .. num .. "!", 1)
                    else
                        generic.NotifyUser("Expected a number!", 2)
                    end
                end
            }

            local input = mainTab:CreateInput{
                Name = "Set Target Player",
                PlaceholderText = "Player DisplayName / Name",
                Callback = function(text)
                    local success, foundPlayer = playerNameFill.TryAutoFillFromInput(text)
                    if success then
                        if (type(foundPlayer) == "number") then
                            generic.NotifyUser("Gave full name of a player but they're not in the server!", 4)
                            return
                        end 

                        generic.NotifyUser(string.format("[Disorder Ignition] %s is currently being targeted!", foundPlayer.Name), 1)
                        targetPlayer = foundPlayer
                    else
                        targetPlayer = nil
                    end
                end
            }
            

            mainTab:CreateButton{
                Name = "Clear field (above)",
                Callback = function()
                    input:Set('', true)
                end
            }

            mainTab:CreateKeybind{
                CurrentKeybind = "X",
                Name = "Cast Disorder Ignition",
                Callback = function()
                    if targetPlayer and typeof(targetPlayer) == "Instance" then
                        local character = targetPlayer.Character
                        if not character then
                            generic.NotifyUser("[Disorder Ignition] Current targeted player does not exist yet!", 3)
                            return
                        end
                        
                        if character:FindFirstChildOfClass("ForceField") then
                            generic.NotifyUser("[Disorder Ignition] Current targeted player is in spawn!", 2)
                            return
                        end
                        
                        local otherHum, otherRoot, rootPart = character:FindFirstChild("Humanoid"), character:FindFirstChild("HumanoidRootPart"), generic.GetPlayerBodyPart("HumanoidRootPart")
                        if not (otherHum and otherRoot) then
                            generic.NotifyUser("[Disorder Ignition] Current targeted player has not yet loaded their character!", 2)
                            return
                        end

                        if rootPart then
                            local finalPosition = Vector3.zero
                            if teleportOption == "void" then
                                finalPosition = voidPosition
                            elseif teleportOption == "spawn" then
                                finalPosition = lockedSpawnsPositionsOfMaps[game.PlaceId] or voidPosition
                            elseif teleportOption == "null" then
                                local i = 0
                                local pos = Vector3.zero
                                while i < 5 do
                                    pos += Vector3.new(10e5,10e5,10e5)
                                    i+=1
                                end
                                finalPosition = pos
                            end

                            local targetPosition = otherRoot.Position
                            local _velocity = otherRoot.AssemblyLinearVelocity
                            if _velocity.Magnitude > 0 then
                                targetPlayer = otherRoot.Position + (_velocity.Unit * _velocity.Magnitude)
                            end
                            rootPart.CFrame = CFrame.new(targetPosition)

                            task.wait(0.15)
                            local args = {[1] = "Chaos", [2] = "Disorder Ignition"}
                            docmagic:FireServer(unpack(args))
                            args[3] = {
                                ['nearestHRP'] = character.Head,
                                ['nearestPlayer'] = targetPlayer,
                                ['rpos'] = otherRoot.Position,
                                ['norm'] = Vector3.yAxis,
                                ['rhit'] = workspace.Map.Part
                            }
                            domagic:InvokeServer(unpack(args))
                            reservekey:FireServer(Enum.KeyCode.Y)
                            local _s = tick()
                            while tick()-_s < tpDelay do task.wait() end
                            if rootPart:FindFirstChild("ChaosLink") == nil then
                                generic.NotifyUser("[Disorder Ignition] Failed to catch target!", 3)
                                return
                            end
                            if otherHum.Health <= 0 then
                                generic.NotifyUser("[Disorder Ignition] Current targeted player died before teleportation!", 2)
                                return
                            end
                            rootPart.CFrame = CFrame.new(finalPosition)
                            task.wait(0.1)
                            reservekey:FireServer(Enum.KeyCode.Y)
                        end
                    end
                end,
            }
            
            mainTab:CreateDropdown{
                Name = "Targeting Type",
                Options = {'Void', 'Null', 'Spawn'},
                CurrentOption = 'void',
                Flag = 'SavedTargetingType',
                Callback = function(option)
                    teleportOption = option:lower()
                end

            }
            Globe.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
                if targetPlayer == player then
                    generic.NotifyUser(string.format("[Disorder Ignition] %s has left the server, no active target!", player.Name), 2)
                    targetPlayer = nil
                    input:Set('', true)
                end
            end))
        end

        buildSpellSection()
        buildDisorderIgnitionSection()
    end

    local utilityTab = Window:CreateTab("Utility - Elemental Battlegrounds") do
        local function buildTechDiscSection()
            local connectionsHolder = generic.NewConnectionsHolder()

            utilityTab:CreateSection('Disable Techlag (Technology Light Disk Bug) State')
            utilityTab:CreateToggle{
                Name = "Enabled",
                CurrentValue = true,
                Callback = function(toggled)
                    if toggled then
                        local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
                        local ClientEffectsFolder = workspace:WaitForChild('.Ignore'):WaitForChild('.LocalEffects')
                        connectionsHolder:Insert(PlayerScripts.ChildAdded:Connect(function(c)
                            if c.Name == "DiscScript" then
                                task.delay(1, c.Destroy, c)
                            end
                        end))
                        connectionsHolder:Insert(ClientEffectsFolder.ChildAdded:Connect(function(c)
                            if c.Name == "LightDisc" or c.Name == "DeadlyDisc" then
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
            local points = {}
            points.activelySimulatingObstructionCheck = false
            points.pointsSmoothingSpeed = 0.75
            points.target = nil
            points.activated = false
            points._pointsShownDirty = false
            points.unrenderCF = CFrame.new(0, 10e5, 0)
            points.lastTimeVelocities = {}
            points.connectionsHolder = generic.NewConnectionsHolder()
            --players
            local function onOtherPlayerAdded(player)
                points.lastTimeVelocities[player.UserId] = {
                    lastVelocity = Vector3.zero,
                    velocity = Vector3.zero,
                    position = Vector3.zero,
                }
                local profile = points.lastTimeVelocities[player.UserId]
                local function onCharAdd(char)
                    local hum, rootpart = char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
                    profile.hum = hum
                    profile.root = rootpart
                end
                if player.Character then onCharAdd(player.Character) end
                player.CharacterAdded:Connect(onCharAdd)
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
            function points:clear()
                while #self > 1 do
                    self:remove(#self)
                end
            end
            function points:new2(locked)
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
                    _shownDirty = true,
                    part = sphere,
                    locked = locked,
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
            function points:setActivePoint(index)
                local foundPoint = self[index]
                if foundPoint then
                    for _, point in ipairs(self) do
                        point.active = false
                    end
                    foundPoint.active = true
                end
            end
            function points:setSmoothingSpeed(speed)
                self.pointsSmoothingSpeed = speed
            end
            function points:getPositionFromInterval(a, b, c, f)
                return a + b * c + 0.5 * f * (c * c)
            end
            function points:update(deltaTime)
                if not self.target or not self.activated then
                    if self._pointsShownDirty then
                        self._pointsShownDirty = false
                        for i = #self, 1, -1 do
                            local point = self[i]
                            if point._shownDirty then
                                point._shownDirty = false
                                point.part.CFrame = points.unrenderCF
                            end
                        end
                    end
                    return
                end
                local foundProfile = self.lastTimeVelocities[self.target.UserId]
                if not foundProfile then
                    if self._pointsShownDirty then
                        self._pointsShownDirty = false
                        for i = #self, 1, -1 do
                            local point = self[i]
                            if point._shownDirty then
                                point._shownDirty = false
                                point.part.CFrame = points.unrenderCF
                            end
                        end
                    end
                    return
                end

                if #self < 1 or not (foundProfile.hum and foundProfile.root) then
                    return
                end

                foundProfile.position = foundProfile.root.Position
                foundProfile.velocity = foundProfile.root.AssemblyLinearVelocity

                local normalizedVelocity = foundProfile.velocity - foundProfile.lastVelocity
                for i = 1, #self, 1 do
                    local point = self[i]
                    point.position = point.position:Lerp(self:getPositionFromInterval(foundProfile.position, foundProfile.velocity, if point.locked then 0 else (foundProfile.hum.WalkSpeed / 16) * (i / #self), normalizedVelocity / deltaTime), self.pointsSmoothingSpeed)
                    point.part.CFrame = CFrame.new(point.position)
                    local newColor = if point.active then BrickColor.Green() else BrickColor.Red()
                    if point.part.BrickColor ~= newColor then
                        point.part.BrickColor = newColor
                    end
                    point._shownDirty = true
                end
                foundProfile.lastVelocity = foundProfile.velocity
                self._pointsShownDirty = true
            end

            local function findNearestPlayerFromPosition(position)
                local t = {}
                for _, player in ipairs(Players:GetPlayers()) do
                    if 
                        player == Players.LocalPlayer or
                        blacklistedPlayers[player.UserId]
                    then continue end
                    
                    if player.Character then
                        local dist = player:DistanceFromCharacter(position)
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

            for i = 0, numsOfPoints do
                points:new(i == 0)
            end
            points:setActivePoint(4)

            local toggle = utilityTab:CreateToggle{
                Name = "Enable Advanced Targeting",
                Callback = function(toggled)
                    points.activated = toggled
                    targetingEnabled = toggled
                end
            }

            utilityTab:CreateKeybind{
                Name = "Toggle bind",
                CurrentKeybind = "C",
                Callback = function()
                    generic.NotifyUser((if targetingEnabled then "Dis" else "En").."abled Advanced Targeting!", 1)
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

                        generic.NotifyUser(string.format("[Targeting] %s is currently being targeted! (Locked targeting option)", foundPlayer.Name), 1)
                        targetPlayer = foundPlayer
                    else
                        targetPlayer = nil
                    end
                end
            }

            utilityTab:CreateButton{
                Name = "Clear field (above)",
                Callback = function()
                    input:Set('', true)
                end
            }

            utilityTab:CreateInput{
                Name = "# of Waypoints (5 - 20)",
                PlaceholderText = "number",
                Callback = function(text)
                    local num = tonumber(text)
                    if num then
                        num = math.clamp(num, 5, 20)
                        points:clear()
                        for i = 0, num do
                            points:new(i == 0)
                        end
                        generic.NotifyUser("Numbers of Waypoints is set to " .. num .. "!", 1)
                    else
                        generic.NotifyUser("Expected a number!", 2)
                    end
                end
            }

            utilityTab:CreateInput{
                Name = "Prediction Index (1 - 10)",
                PlaceholderText = "number",
                Callback = function(text)
                    local num = tonumber(text)
                    if num then
                        num = math.max(num, 0)
                        points:setActivePoint(num)
                        generic.NotifyUser("Prediction Waypoint Index is set to " .. num .. "!", 1)
                    else
                        generic.NotifyUser("Expected a number!", 2)
                    end
                end
            }

            utilityTab:CreateInput{
                Name = "Points Smoothing Speed (0.25 - 1)",
                PlaceholderText = "number",
                Callback = function(text)
                    local num = tonumber(text)
                    if num then
                        num = math.clamp(num, 0.25, 1)
                        points:setSmoothingSpeed(num)
                        generic.NotifyUser("Prediction waypoints are smoothen to " .. num .. " seconds!", 1)
                    else
                        generic.NotifyUser("Expected a number!", 2)
                    end
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
                Name = "Clear All Blacklisted",
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
                    targetType = option:lower()
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
                    local rootPart = generic.GetPlayerBodyPart("HumanoidRootPart")
                    if rootPart then
                        local foundTargetPlayer
                        if targetType == 'locked' then
                            if targetPlayer then
                                foundTargetPlayer = targetPlayer
                            end
                        elseif targetType == 'mouse' then
                            local foundPlayer = findNearestPlayerFromPosition(generic.GetMousePositionFromHook())
                            if foundPlayer then
                                foundTargetPlayer = foundPlayer
                            end
                        elseif targetType == 'character' then
                            local foundPlayer = findNearestPlayerFromPosition(rootPart.Position)
                            if foundPlayer then
                                foundTargetPlayer = foundPlayer
                            end
                        end

                        local mousePosition = Vector3.zero
                        points.target = foundTargetPlayer
                        mousePosition = points:getActivePoint().position

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
                    generic.NotifyUser((if auraEnabled then "Dis" else "En").."abled Punch Aura!", 1)
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