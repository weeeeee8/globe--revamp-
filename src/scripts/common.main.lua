local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local generic = import('env/util/generic')

return function(Window)
    local playerMouse = Players.LocalPlayer:GetMouse()

    local tab = Window:CreateTab("Common", 4483364243)
    local function buildFlySection()
        tab:CreateSection("Fly Options")

        local flightNoClipEnabled = false
        local flightEnabled = false
        local flightSpeed = 250
        local keycodeInputStates = generic.MakeSet(Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.W, Enum.KeyCode.D):get()
        local bodyvelocity, bodygyro

        local function getDirectionFromActiveStates()
            local dir = Vector3.zero
            if keycodeInputStates[Enum.KeyCode.A] == true then
                dir -= Vector3.xAxis
            end
            if keycodeInputStates[Enum.KeyCode.S] == true then
                dir += Vector3.zAxis
            end
            if keycodeInputStates[Enum.KeyCode.W] == true then
                dir -= Vector3.zAxis
            end
            if keycodeInputStates[Enum.KeyCode.D] == true then
                dir += Vector3.xAxis
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
                local direction: Vector3 = getDirectionFromActiveStates() * (flightSpeed + dt)
                
                if bodyvelocity then
                    bodyvelocity.Velocity = workspace.CurrentCamera.CFrame:PointToWorldSpace(direction)
                end

                if bodygyro then
                    bodygyro.CFrame = workspace.CurrentCamera.CFrame
                end
            else
                modifyBodyMovers(rootPart, true)
            end
        end)

        Globe.Maid:GiveTask(RunService.Stepped:Connect(function()
            if flightNoClipEnabled then
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
        tab:CreateKeybind{
            Name = "Teleport to Mouse",
            CurrentKeybind = "T",
            Callback = function()
                local rootPart = generic.GetPlayerBodyPart('HumanoidRootPart')
                if rootPart then
                    local hum = generic.GetPlayerBodyPart('Humanoid')
                    local mousePosition = playerMouse.Hit.Position + (Vector3.yAxis * 2)
                    local moveDirection = rootPart.CFrame.LookVector
                    if hum then
                        moveDirection = hum.MoveDirection
                    end
                    rootPart.CFrame = CFrame.new(mousePosition, mousePosition + moveDirection)
                end
            end
        }
    end

    local function buildJoiningSection()
        tab:CreateSection("Joining options")
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
    end

    buildJoiningSection()
    buildTeleportSection()
    buildFlySection()
end