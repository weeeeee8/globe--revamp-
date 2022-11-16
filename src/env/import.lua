local PATH_SEPERATOR = "/"
local SOURCE = "https://raw.githubusercontent.com/weeeeee8/globe--revamp-/main/src/"

local ImportDirectories = {}

local Import = setmetatable({
    ['global'] = {},

    CreateDirectory = function(self, path: string)
        local directory = table.split(path, PATH_SEPERATOR)
        local indexInPath = 1
        local target = ImportDirectories
        repeat
            if not target[directory[indexInPath]] then
                target[directory[indexInPath]] = {}
            end
            target = target[directory[indexInPath]]
            indexInPath += 1
        until indexInPath - 1 == #directory
    end,
    Clean = function(self)
        table.clear(ImportDirectories)
        setmetatable(self, nil)
    end
}, {
    __index = function(self, key)
        return self[key]
    end,
    __newindex = function(_, key)
        error(string.format('Cannot assign property "%s" on static class', key))
    end,
    __call = function(self, path: string)
        local function parsePath(path: string)
            local directory = table.split(path, PATH_SEPERATOR)
            local indexInPath = 1

            local target = ImportDirectories
            repeat
                target = target[directory[indexInPath]]
                indexInPath += 1
            until indexInPath - 1 == #directory
            return directory, target
        end

        local function importToDirectory(path: string)
            local directory = table.split(path, PATH_SEPERATOR)
            local fileName = directory[#directory]
            directory[#directory] = nil

            local indexInPath = 1

            local target = ImportDirectories
            repeat
                target = target[directory[indexInPath]]
                indexInPath += 1
            until indexInPath - 1 == #directory
            
            local src = target[fileName]
            if not src then
                src = loadstring(game:HttpGet(SOURCE .. table.concat(directory, PATH_SEPERATOR) .. "/" .. fileName .. ".lua"), fileName .. ".lua")()
                target[fileName] = src
            end
            return src
        end

        local decompiledPah, src = parsePath(path)
        if not src then
            return importToDirectory(path)
        end

        return src
    end
})

return Import