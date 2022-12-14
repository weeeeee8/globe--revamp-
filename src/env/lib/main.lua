return function(import)
    local Maid = import('env/lib/maid')

    local environment = assert(getgenv, "Cannot find global 'getgenv'. Your executor might not be supported!")()
    if environment.import then
        environment.import = nil
    end
    environment.import = import
    environment.SecureMode = true
    
    if environment.Globe then
        pcall(function()
            environment.Globe:Exit()
        end)
        environment.Globe = nil
    end

    environment.Globe = {
        Maid = Maid.new(),
        Hooks = {},
        Exit = function(self)
            self.Window:Destroy()
            self.Maid:DoCleaning()
            for _, hook in ipairs(self.Hooks) do
                hook:Reset()
            end
            table.clear(self.Hooks)
        end
    }

    local rayfield = import('env/rayfield')
    local Window = rayfield:CreateWindow{
        Name = "Globe [ Revamped ]",
        LoadingTitle = "Globe",
        LoadingSubtitle = 'by RVCDev',
        ConfigurationSaving = {
            Enabled = true,
            FileName = "SavedGlobeSettings"
        },
        KeySystem = true,
        KeySettings = {
            Title = 'Globe Guard',
            Subtitle = 'Key identification system',
            Note = "Whitelisted key system",
            FileName = "key",
            GrabKeyFromSite = true,
            SaveKey = true,
            Key = 'https://raw.githubusercontent.com/weeeeee8/globe--revamp-/main/src/key.txt',
        }
    }
    environment.Globe.Window = Window

    xpcall(function()
        do import('scripts/common.main')(Window)
        local function tryGetScriptNameFromGameId(gameId: number)
        local scripts = {
            [224422602] = 'ebg'
        }
        return scripts[gameId]
        end
        import('scripts/' .. tryGetScriptNameFromGameId(game.GameId) .. '.main')(Window) end
    end, warn)

    rayfield:LoadConfiguration()
end