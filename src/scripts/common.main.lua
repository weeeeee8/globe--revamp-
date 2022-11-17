local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local generic = import('env/util/generic')

return function(Window)
    local tab = Window:CreateTab("Common", 4483364243)
    local function buildFlySection()
        tab:CreateSection("Fly Options")

        local flightEnabled = false
        local flightSpeed = 1
        local keycodeInputStates = generic.MakeSet(Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.W, Enum.KeyCode.D):get()

        local function getDirectionFromActiveStates()
            local dir = Vector3.zero
            if keycodeInputStates[Enum.KeyCode.A] then
                dir -= Vector3.xAxis
            end
            if keycodeInputStates[Enum.KeyCode.S] then
                dir += Vector3.zAxis
            end
            if keycodeInputStates[Enum.KeyCode.W] then
                dir -= Vector3.zAxis
            end
            if keycodeInputStates[Enum.KeyCode.D] then
                dir += Vector3.xAxis
            end
            return dir
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

        tab:CreateKeybind{
            Name = "Start/Stop flight",
            CurrentKeybind = "F",
            Callback = function()
               flightEnabled = not flightEnabled
            end
        }

        RunService:BindToRenderStep("fly.update", Enum.RenderPriority.Character.Value, function(dt)
            local head = generic.GetPlayerBodyPart("Head")
            if not head then return end
            head.Anchored = flightEnabled
            if flightEnabled then
                local direction: Vector3 = getDirectionFromActiveStates() * flightSpeed * dt
                local headCFrame = head.CFrame
                local cameraCFrame = workspace.CurrentCamera.CFrame
                local cameraOffset = head.CFrame:ToObjectSpace(cameraCFrame)
                cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
                local cameraPosition = cameraCFrame.Position
                local headPosition = headCFrame.Position
        
                local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(direction)
                head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
            end
        end)

        Globe.Maid:GiveTask(function()
            RunService:UnbindFromRenderStep("fly.update")
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

    local function buildJoiningSection()
        tab:CreateSection("Joining options")
        tab:CreateButton{
            Name = "Rejoin",
            Callback = function()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end
        }
    end

    buildJoiningSection()
    buildFlySection()
end