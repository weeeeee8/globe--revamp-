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
                return players[i]
            end
        end
        return nil
    end

    local tab = Window:CreateTab("Common", 4483364243)
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
            if not rootPart then return end
            if flightEnabled then
                modifyBodyMovers(rootPart, false)
                local direction: Vector3 = getDirectionFromActiveStates(flightSpeed + dt)
                
                if bodyvelocity then
                    bodyvelocity.Velocity = direction
                end

                if bodygyro then
                    bodygyro.CFrame = workspace.CurrentCamera.CFrame
                end
            else
                modifyBodyMovers(rootPart, true)
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

        local targetPlayerAutofill = generic.NewAutofill("Player to Teleport to", getPlayerFromInput)

        tab:CreateInput{
            Name = "Player to Teleport to",
            PlaceholderText = "Player DisplayName / Name",
            Callback = function(text: string)
                local success, result: Player | string = targetPlayerAutofill.TryAutoFillFromInput(text)
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
                    local mousePosition = playerMouse.Hit.Position + (Vector3.yAxis * 2)
                    local moveDirection = rootPart.CFrame.LookVector.Unit * 50
                    if hum then
                        if hum.MoveDirection.Magnitude > 0 then
                            moveDirection = hum.MoveDirection.Unit * 50
                        end
                    end
                    rootPart.CFrame = CFrame.new(mousePosition, mousePosition + moveDirection)
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

        local playerSpyAutofill = generic.NewAutofill("Camera Spy", getPlayerFromInput)
        local activePlayerRemovedConn

        local function setCameraSubjectTo(player: Player)
            local hum = if player.Character then player.Character:FindFirstChild("Humanoid") else nil
            if hum then
                workspace.CurrentCamera.CameraSubject = hum
            end
        end

        tab:CreateInput{
            Name = "Player to Spy",
            PlaceholderText = "Player DisplayName / Name",
            Callback = function(text: string)
                local success, result: Player | string = playerSpyAutofill.TryAutoFillFromInput(text)
                
                if activePlayerRemovedConn then
                    activePlayerRemovedConn:Disconnected()
                    activePlayerRemovedConn = nil
                end

                if success then
                    setCameraSubjectTo(result)
        
                    activePlayerRemovedConn = result.Destroying:Once(function()
                        setCameraSubjectTo(Players.LocalPlayer)
                        generic.NotifyUser(string.format('Player "%s" has left the experience, disconnecting camera spy bindings...', result.Name), 1)
                        activePlayerRemovedConn:Disconnect()
                        activePlayerRemovedConn = nil
                    end)
                else
                    setCameraSubjectTo(Players.LocalPlayer)
                end
            end
        }

        Globe.Maid:GiveTask(function()
            if activePlayerRemovedConn then
                activePlayerRemovedConn:Disconnect()
                activePlayerRemovedConn = nil
            end
        end)

        setCameraSubjectTo(Players.LocalPlayer)
    end

    local function buildJoiningSection()
        tab:CreateSection("Joining Options")

        local MAX_JOIN_ATTEMPTS = 5
        local STALKING_TIMEOUT = 30--seconds
        local targetPlayerName
        local shouldAutoExecute = false

        tab:CreateToggle{
            Name = "Autoexecute script hub",
            CurrentValue = false,
            Callback = function(toggled)
                shouldAutoExecute = toggled
            end
        }
        
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
            Name = "Stalk",
            Callback = function()
                getgenv().DisableAllInteractions = true
                generic.NotifyUser('Attempting to find player...', 1)
                local success, id = pcall(Players.GetUserIdFromNameAsync, Players, targetPlayerName)
                if not success then
                    generic.NotifyUser('Cannot find player!', 3)
                    getgenv().DisableAllInteractions = false
                    return
                end

                generic.NotifyUser('Attempting to find player thumbnail...', 1)
                local playerThumbnailUrl = game:HttpGet("https://www.roblox.com/headshot-thumbnail/json?userId=" .. tostring(id) .. "&width=48&height=48").Url

                local terminatedProcess = false
                local startIndex = 0
                local start = tick()

                generic.NotifyUser('Scanning servers...', 1)
                while true do
                    local now = tick()
                    if now - start > STALKING_TIMEOUT then terminatedProcess = true break end

                    local gameInstances = game:HttpGet("https://www.roblox.com/games/getgameinstancesjson?placeId=" .. game.PlaceId .. "&startindex=" .. tostring(startIndex))
                    for _, place in pairs(gameInstances.Collection) do
                        for _, playerFromWebsite in pairs(place.CurrentPlayers) do
                            if playerFromWebsite.UserId == id and playerFromWebsite.Thumbnail.Url == playerThumbnailUrl then
                                generic.NotifyUser('Found server!', 1)
                                generic.NotifyUser('Attempting to teleport to server...', 1)

                                if shouldAutoExecute then
                                    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/weeeeee8/globe--revamp-/main/source.lua"), "Globe")()')
                                end

                                local failCounter = 0
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, place.Guid)

                                local teleportAttemptConn
                                teleportAttemptConn = Players.LocalPlayer.OnTeleport:Connect(function(state)
                                    if state == Enum.TeleportState.Failed then
                                        if failCounter > MAX_JOIN_ATTEMPTS then
                                            teleportAttemptConn:Disconnect()
                                            teleportAttemptConn  = nil
                                            getgenv().DisableAllInteractions = false
                                            generic.NotifyUser('Max joining attempts reached, please try again later!', 3)
                                            return
                                        end
                                        failCounter += 1
                                        generic.NotifyUser('Failed to teleport! (retries: ' .. tostring(failCounter) .. ')', 2)
                                        TeleportService:TeleportToPlaceInstance(game.PlaceId, place.Guid)
                                    end
                                end)

                                break
                            end
                        end
                    end

                    if startIndex > gameInstances.TotalCollectionSize then
                        terminatedProcess = true
                        break
                    end

                    generic.NotifyUser(tostring(startIndex) .. ' / ' .. tostring(gameInstances.TotalCollectionSize) .. ' servers scanned!', 1)
                    startIndex += 10
                end

                if terminatedProcess then
                    getgenv().DisableAllInteractions = false
                    generic.NotifyUser('Teleportation cancelled! (Timeout or Player is on a Private Server)', 4)
                end
            end
        }

        tab:CreateInput{
            Name = "Player Name to Stalk",
            PlaceholderText = "Player Name (CASE SENSITIVE)",
            Callback = function(name: string)
                if #name <= 0 then return end
                targetPlayerName = name
            end,
        }
    end

    buildJoiningSection()
    buildTeleportSection()
    buildFlySection()
    buildCameraSpySection()
end