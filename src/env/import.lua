local PATH_SEPERATOR = "/"



local function importFromGithub()
    return loadstring()()
end

local Import = setmetatable({
    ['global'] = {},

    CreateDirectory = function(self, path: string)
        local directory = table.split(path, PATH_SEPERATOR)
        local indexInPath = 1
        repeat
            if not self[directory[indexInPath]] then
                self[directory[indexInPath]] = {}
            end
            indexInPath += 1
        until indexInPath - 1 == #directory
    end
}, {
    __index = function(self, key)
        return self[key]
    end,
    __newindex = function(_, key)
        error(string.format('Cannot assign property "%s" on static class'))
    end,
    __call = function(self, path: string)
        local function parsePath(path: string)
            local directory = table.split(path, PATH_SEPERATOR)
            local indexInPath = 1

            local target = self
            repeat
                target = target[directory[indexInPath]]
                indexInPath += 1
            until indexInPath - 1 == #directory
            return directory, target
        end

        local function importToDirectory(path: string)

        end

        local decompiledPah, src = parsePath(path)
        if not src then
            importFromGithub(decompiledPah[#decompiledPah])

        end
    end
})

return Import