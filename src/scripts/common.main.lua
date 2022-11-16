local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local generic = import('env/util/generic')

return function(Window)
    local tab = Window:CreateTab("Common", 4483364243)
    local function buildFlySection()
        tab:CreateSection("Fly Options")

        local flightEnabled = false
        local flightSpeed = 250
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
                local direction: Vector3 = getDirectionFromActiveStates()
                local cframe = CFrame.new(head.Position + workspace.CurrentCamera.CFrame:PointToWorldSpace(direction * flightSpeed))
                head.CFrame = cframe
            end
        end)

        Globe.Maid:GiveTask(function()
            RunService:UnbindFromRenderStep("fly.update")
        end)
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