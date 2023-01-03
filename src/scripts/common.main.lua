local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local generic = import('env/util/generic')

return function(Window)
    local playerMouse = Players.LocalPlayer:GetMouse()

    local function getPlayerFromInput(input)
        local players = Players:GetPlayers()
        for i = #players, 1, -1 do
            if players[i].Name:sub(1, #input) == input or players[i].DisplayName:sub(1, #input) == input then
                local player = players[i]
                if player == Players.LocalPlayer then return nil end
                return player
            end
        end
        return nil
    end
    
    local playerNameFill = generic.NewAutofill("Name Fill", getPlayerFromInput)

    local tab = Window:CreateTab("Common")
    local function buildAnimatorModifierSection()
        tab:CreateSection("Animator Modifier Options")
        local animator, hum
        local function onCharacterAdded(character)
            hum = character:WaitForChild("Humanoid")
            animator = hum:WaitForChild("Animator")
        end
        if Players.LocalPlayer.Character then onCharacterAdded(Players.LocalPlayer.Character) end
        Globe.Maid:GiveTask(Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded))

        tab:CreateButton{
            Name = "Remove Animator",
            Callback = function()
                if animator.Parent == nil then
                    generic.NotifyUser('Animator is already removed!', 3)
                    return
                end

                animator.Parent = nil
            end
        }

        tab:CreateButton{
            Name = "Add Animator",
            Callback = function()
                if animator.Parent == hum then
                    generic.NotifyUser('Animator is already added!', 3)
                    return
                end

                animator.Parent = hum
            end
        }
    end

    local function buildFlySection()
        tab:CreateSection("Fly Options")

        local flightNoClipEnabled = false
        local flightEnabled = false
        local flightSpeed = 250
        local keycodeInputStates = generic.MakeSet(Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.W, Enum.KeyCode.D):override(function()
            return false
        end):get()
        local bodyvelocity, bodygyro

        local function getDirectionFromActiveStates(velocity)
            local dir = Vector3.zero
            if keycodeInputStates[Enum.KeyCode.A] == true then
                dir -= workspace.CurrentCamera.CFrame.RightVector * velocity
            end
            if keycodeInputStates[Enum.KeyCode.D] == true then
                dir += workspace.CurrentCamera.CFrame.RightVector * velocity
            end
            if keycodeInputStates[Enum.KeyCode.W] == true then
                dir += workspace.CurrentCamera.CFrame.LookVector * velocity
            end
            if keycodeInputStates[Enum.KeyCode.S] == true then
                dir -= workspace.CurrentCamera.CFrame.LookVector * velocity
            end
            return dir
        end

        local function modifyBodyMovers(rootPart, shouldDestroy)
            if not shouldDestroy then
                if not bodyvelocity then
                    bodyvelocity = Instance.new("BodyVelocity")
                    bodyvelocity.MaxForce = Vector3.one * math.huge
                    bodyvelocity.P = 40000
                    bodyvelocity.Name = "flyvel"
                    bodyvelocity.Parent = rootPart
                end

                if not bodygyro then
                    bodygyro = Instance.new("BodyGyro")
                    bodygyro.MaxTorque = Vector3.one * math.huge
                    bodygyro.P = 40000
                    bodygyro.D = 200
                    bodygyro.CFrame = workspace.CurrentCamera.CFrame
                    bodygyro.Name = "flylook"
                    bodygyro.Parent = rootPart
                end
            else
                if bodygyro then
                    bodygyro:Destroy()
                    bodygyro = nil
                end

                if bodyvelocity then
                    bodyvelocity:Destroy()
                    bodyvelocity = nil
                end
            end
        end

        tab:CreateInput{
            Name = "Flight Speed",
            PlaceholderText = "number",
            Callback = function(text: string)
                local num = tonumber(text) or 0
                num = math.max(num, 0)
                flightSpeed = num
            end
        }

        tab:CreateToggle{
            Name = "Enable Noclip while flight",
            CurrentValue = true,
            Flag = "FlightNoclip",
            Callback = function(toggled)
                flightNoClipEnabled = toggled
            end
        }

        tab:CreateKeybind{
            Name = "Start/Stop flight",
            CurrentKeybind = "F",
            Callback = function()
                flightEnabled = not flightEnabled
            end
        }

        RunService:BindToRenderStep("fly.update", Enum.RenderPriority.Character.Value, function(dt)
            local rootPart = generic.GetPlayerBodyPart('HumanoidRootPart')
            local hum = generic.GetPlayerBodyPart('Humanoid')
            if not rootPart then return end
            if flightEnabled then
                modifyBodyMovers(rootPart, false)
                hum.AutoRotate = false
                local direction: Vector3 = getDirectionFromActiveStates(flightSpeed + dt)
                
                if bodyvelocity then
                    bodyvelocity.Velocity = direction
                end

                if bodygyro then
                    bodygyro.CFrame = workspace.CurrentCamera.CFrame
                end
            else
                modifyBodyMovers(rootPart, true)
                hum.AutoRotate = true
            end
        end)

        Globe.Maid:GiveTask(RunService.Stepped:Connect(function()
            if flightNoClipEnabled and flightEnabled then
                for _, bodypart in ipairs(Players.LocalPlayer.Character:GetChildren()) do
                    if bodypart:IsA("BasePart") then
                        bodypart.CanCollide = false
                    end
                end
            end
        end))

        Globe.Maid:GiveTask(function()
            RunService:UnbindFromRenderStep("fly.update")
            generic.SafeDestroy(bodyvelocity)
            generic.SafeDestroy(bodygyro)

            bodyvelocity = nil
            bodygyro = nil
        end)

        Globe.Maid:GiveTask(UserInputService.InputBegan:Connect(function(i, g)
            if g then return end
            local isDirectionalKey = keycodeInputStates[i.KeyCode]
            if isDirectionalKey ~= nil then
                keycodeInputStates[i.KeyCode] = true
            end
        end))
        
        Globe.Maid:GiveTask(UserInputService.InputEnded:Connect(function(i, g)
            local isDirectionalKey = keycodeInputStates[i.KeyCode]
            if isDirectionalKey ~= nil then
                keycodeInputStates[i.KeyCode] = false
            end
        end))
    end

    local function buildTeleportSection()
        tab:CreateSection("Teleporting Options")

        local targetPlayer = nil
        local stickToEnabled = false
        local requestPlayerTeleport = false

        local activePlayerRemovedConn

        tab:CreateInput{
            Name = "Player to Teleport to",
            PlaceholderText = "Player DisplayName / Name",
            Callback = function(text: string)
                local success, result: Player | string = playerNameFill.TryAutoFillFromInput(text)
                if success then
                    targetPlayer = result
                    generic.NotifyUser(string.format('Connecting teleport bindings for player "%s"', result.Name), 1)
                    
                    if activePlayerRemovedConn then
                        activePlayerRemovedConn:Disconnected()
                        activePlayerRemovedConn = nil
                    end

                    activePlayerRemovedConn = result.Destroying:Once(function()
                        targetPlayer = nil
                        generic.NotifyUser(string.format('Player "%s" has left the experience, disconnecting teleport bindings...', result.Name), 1)
                        activePlayerRemovedConn:Disconnect()
                        activePlayerRemovedConn = nil
                    end)
                else
                    generic.NotifyUser(result, 2)
                end
            end
        }

        tab:CreateKeybind{
            Name = "Teleport to Mouse",
            CurrentKeybind = "T",
            Callback = function()
                local rootPart = generic.GetPlayerBodyPart('HumanoidRootPart')
                if rootPart then
                    local hum = generic.GetPlayerBodyPart('Humanoid')
                    if playerMouse.Target then
                        local mousePosition = playerMouse.Hit.Position + (Vector3.yAxis * 2)
                        local moveDirection = rootPart.CFrame.LookVector.Unit * 50
                        if hum then
                            if hum.MoveDirection.Magnitude > 0 then
                                moveDirection = hum.MoveDirection.Unit * 50
                            end
                        end
                        rootPart.CFrame = CFrame.lookAt(mousePosition, mousePosition + moveDirection)
                    else
                        generic.NotifyUser('No part found to property teleport at, might cause the player to fling to void!', 4)
                    end
                end
            end
        }

        tab:CreateKeybind{
            Name = "Teleport to Player",
            CurrentKeybind = "G",
            Callback = function()
                if not requestPlayerTeleport then
                    requestPlayerTeleport = true
                end
            end
        }

        tab:CreateKeybind{
            Name = "Stick to Player",
            CurrentKeybind = "H",
            Callback = function()
                stickToEnabled = not stickToEnabled
            end
        }

        Globe.Maid:GiveTask(RunService.RenderStepped:Connect(function()
            if requestPlayerTeleport or stickToEnabled then
                if requestPlayerTeleport then
                    requestPlayerTeleport = false
                end
                if targetPlayer then
                    local foundRootPart = if targetPlayer.Character then targetPlayer.Character:FindFirstChild("HumanoidRootPart") else nil
                    if foundRootPart then
                        local rootPart = generic.GetPlayerBodyPart("HumanoidRootPart")
                        if rootPart then
                            rootPart.CFrame = foundRootPart.CFrame
                        end
                    end
                end
            end
        end))

        Globe.Maid:GiveTask(function()
            targetPlayer = nil

            if activePlayerRemovedConn then
                activePlayerRemovedConn:Disconnect()
                activePlayerRemovedConn = nil
            end
        end)
    end

    local function buildCameraSpySection()
        tab:CreateSection("Camera Spy Options")

        local watchedPlayer
        local connectionsHolder = generic.NewConnectionsHolder()

        local function setCameraSubjectTo(player: Player, shouldYield)
            local hum = if player.Character then player.Character[if shouldYield then "WaitForChild" else "FindFirstChild"](player.Character, "Humanoid") else nil
            if hum then
                workspace.CurrentCamera.CameraSubject = hum
            end
        end

        local input; input = tab:CreateInput{
            Name = "Player to Spy",
            PlaceholderText = "Player DisplayName / Name",
            Callback = function(text: string)
                local success, result: Player | string = playerNameFill.TryAutoFillFromInput(text)
                
                connectionsHolder:DisconnectAll()

                if success then
                    setCameraSubjectTo(result)
        
                    connectionsHolder:Insert(result.CharacterAdded:Connect(function()
                        setCameraSubjectTo(result, true)
                    end))
                else
                    setCameraSubjectTo(Players.LocalPlayer)
                end
            end
        }

        tab:CreateButton{
            Name = "Clear field (above)",
            Callback = function()
                input:Set('', true)
            end
        }

        Globe.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
            if player == watchedPlayer then
                connectionsHolder:DisconnectAll()
                watchedPlayer = nil
                input:Set('', true)
            end
        end))
        
        Globe.Maid:GiveTask(function()
            connectionsHolder:Destroy()
        end)

        setCameraSubjectTo(Players.LocalPlayer)
    end

    local function buildCustomEspSection()
        tab:CreateSection('ESP')
        
        local espEnabled = false
        local watchedPlayer
        local trackedPlayers = {}

        local textFont = Drawing.Fonts.UI
        local textSize = 14
        local textColor = Color3.fromRGB(239, 137, 42)

        local connectionsHolder = generic.NewConnectionsHolder()

        local function instantiateLabel(player)
            local label = Drawing.new('Text')
            label.Font = textFont
            label.Size = textSize
            label.Color = textColor
            label.Outline = true
            label.OutlineColor = Color3.new(0, 0, 0)
            label.Transparency = 0.7
            label.Center = true

            trackedPlayers[player] = label
        end

        local colorPicker = tab:CreateColorpicker{
            Flag = "SavedESPColor",
            CurrentColor = Color3.new(1, 0, 0)
        }
        Globe.Maid:GiveTask(colorPicker:OnChanged(function(newColor)
            textColor = newColor
        end))
        
        tab:CreateToggle{
            Flag = "SavedESPToggle",
            Name = "Enable ESP",
            CurrentValue = false,
            Callback = function(toggled)
                espEnabled = toggled
            end,
        }
        local input = tab:CreateInput{
            Name = "Spawn watch Player",
            PlaceholderText = "Player DisplayName / Name",
            Callback = function(text)
                local success, result = playerNameFill.TryAutoFillFromInput(text)
                if success then
                    connectionsHolder:DisconnectAll()
                    generic.NotifyUser(string.format('Watching %s! You will be notified once they have entered/exited a safezone', result.Name))

                    local function onCharacterAdded(char)
                        connectionsHolder:Insert(char.ChildAdded:Connect(function(c)
                            if c:IsA("ForceField") then
                                generic.NotifyUser(string.format('%s has entered spawn!', result.Name))
                            end
                        end))
                        connectionsHolder:Insert(char.ChildRemoved:Connect(function(c)
                            if c:IsA("ForceField") then
                                generic.NotifyUser(string.format('%s has exited spawn!', result.Name))
                            end
                        end))
                    end

                    connectionsHolder:Insert(result.CharacterAdded:Connect(onCharacterAdded))
                    watchedPlayer = result
                else
                    connectionsHolder:DisconnectAll()
                end
            end
        }

        Globe.Maid:GiveTask(Players.PlayerRemoving:Connect(function(player)
            if player == watchedPlayer then
                connectionsHolder:DisconnectAll()
                watchedPlayer = nil
            end
        end))

        tab:CreateButton{
            Name = "Clear field (above)",
            Callback = function()
                input:Set('', true)
            end
        }

        Globe.Maid:GiveTask(function()
            connectionsHolder:Destroy()
        end)

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
                        local vector, isInScreen = workspace.CurrentCamera:WorldToViewportPoint(foundHumanoidRootPart.Position)
                        if rootPart and isInScreen then
                            if not label.Visible then
                                label.Visible = true
                            end

                            local dist = (foundHumanoidRootPart.Position - rootPart.Position).Magnitude
                            label.Position = Vector2.new(vector.X, vector.Y - 25)

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

    local function buildJoiningSection()
        tab:CreateSection("Joining Options")

        local MAX_JOIN_ATTEMPTS = 5
        local SERVER_HOP_TIMEOUT = 30--seconds
        local SERVER_TIME_CACHE_FILENAME = 'globe_servercache.txt'
        local SERVERS_CACHE_FILENAME = 'globe_notsameservers.json'

        local desiredServerSize = 3
        local lastServerCursor
        local shouldAutoExecute = false

        tab:CreateToggle{
            Name = "Autoexecute script hub",
            CurrentValue = true,
            Callback = function(toggled)
                shouldAutoExecute = toggled
            end
        }

        tab:CreateLabel("Miscellaneous")

        tab:CreateButton{
            Name = "Copy Place JobId",
            Callback = function()
                local id = game.JobId
                setclipboard(id)
                generic.NotifyUser("Copied to clipboard! got: " .. id, 1)
            end
        }

        tab:CreateButton{
            Name = "Create Join Link (other exploiter must be in a game)",
            Callback = function()
                local placeid = game.PlaceId
                local id = game.JobId
                local src = string.format("game:GetService(\"TeleportService\"):TeleportToPlaceInstance(%i,%s,game.Players.LocalPlayer)", placeid, id)
                setclipboard(src)
                generic.NotifyUser("Created a join link!")
            end
        }
        
        tab:CreateLabel("Joining")
        
        tab:CreateButton{
            Name = "Rejoin",
            Callback = function()
                if shouldAutoExecute then
                    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/weeeeee8/globe--revamp-/main/source.lua"), "Globe")()')
                end
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end
        }
        

        tab:CreateButton{
            Name = "Serverhop",
            Callback = function()
                local startHour = os.date("!*t").hour
                local jobIds = {}
                local success1, foundLastCacheTime = pcall(readfile, SERVER_TIME_CACHE_FILENAME)
                if not success1 then
                    writefile(SERVER_TIME_CACHE_FILENAME, tostring(startHour))
                end
                local success2, foundFileCache = pcall(readfile, SERVERS_CACHE_FILENAME)
                if not success2 then
                    writefile(SERVERS_CACHE_FILENAME, HttpService:JSONEncode(jobIds))
                else
                    jobIds = HttpService:JSONDecode(foundFileCache)
                end

                local function isCurrentIdExisting(id)
                    for _, cache in ipairs(jobIds) do
                        if tostring(id) == tostring(cache) then 
                            return true
                        end
                    end
                    return false
                end

                generic.NotifyUser('Finding new servers..', 1)
                local scanned = 0
                local attempts = 0
                local start = tick()
                while true do
                    if foundLastCacheTime then
                        if tonumber(startHour) ~= tonumber(foundLastCacheTime) then
                            pcall(delfile, SERVER_TIME_CACHE_FILENAME)
                            table.clear(jobIds)
                        end
                    end

                    local now = tick()
                    if now - start > SERVER_HOP_TIMEOUT then
                        generic.NotifyUser('Serverhopping timeout! Please try again!', 2)
                        break
                    end

                    local serverlist
                    if lastServerCursor then
                        serverlist = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. lastServerCursor))
                    else
                        serverlist = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=Asc&limit=100'))
                    end

                    if serverlist.nextPageCursor and serverlist.nextPageCursor ~= "null" and serverlist.nextPageCursor ~= nil then
                        lastServerCursor = serverlist.nextPageCursor
                    end

                    local totalServers = generic.LenDictionary(serverlist.data)
                    generic.NotifyUser('Scanning a total of ' .. totalServers .. ' servers...', 1)
                    for _, serverdata in pairs(serverlist.data) do
                        local id = serverdata.id
                        if tonumber(serverdata.maxPlayers) > tonumber(serverdata.playing) and tonumber(serverdata.playing) > desiredServerSize then
                            if not isCurrentIdExisting(id) then
                                generic.NotifyUser('Found a server with an id of "' .. id .. '"!', 1)
                                setclipboard(id)

                                table.insert(jobIds, id)
                                local event = Instance.new("BindableEvent")
                                
                                writefile(SERVERS_CACHE_FILENAME, HttpService:JSONEncode(jobIds))

                                local function tryTeleport()
                                    if attempts > MAX_JOIN_ATTEMPTS then
                                        generic.NotifyUser('Unable to teleport!', 3)
                                        pcall(delfile, SERVERS_CACHE_FILENAME)
                                        event:Fire()
                                        writefile(SERVERS_CACHE_FILENAME, HttpService:JSONEncode({}))
                                        return
                                    end

                                    if shouldAutoExecute then
                                        queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/weeeeee8/globe--revamp-/main/source.lua"), "Globe")()')
                                    end
                                    TeleportService:TeleportToPlaceInstance(game.PlaceId, id, Players.LocalPlayer)
                                    local onTeleportFailed; onTeleportFailed = Players.LocalPlayer.OnTeleport:Connect(function(state)
                                        if state == Enum.TeleportState.Failed then
                                            onTeleportFailed:Disconnect()
                                            onTeleportFailed = nil
                                            generic.NotifyUser('Failed to teleport, retrying...', 2)
                                            attempts += 1
                                            tryTeleport()
                                        end
                                    end)
                                end
                                tryTeleport()

                                event.Event:Wait()
                            end
                        end
                        scanned+=1
                        generic.NotifyUser('Scanned ' .. scanned .. "/" .. totalServers, 1)
                        
                        task.wait(1)
                    end
                end

                getgenv().DisableAllInteractions = false
            end,
        }

        tab:CreateInput{
            Name = "Desired Server Size",
            PlaceholderText = "number",
            Callback = function(text)
                local num = tonumber(text) or 0
                num = math.max(num, 0)
                desiredServerSize = num
            end
        }
    end

    buildJoiningSection()
    buildTeleportSection()
    buildFlySection()
    buildCameraSpySection()
    buildCustomEspSection()
    buildAnimatorModifierSection()
end