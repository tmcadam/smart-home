local M = {}

function M.load(filename)
    local config = {}
    local decoder = sjson.decoder()
    if file.open(filename) then
        decoder:write(file.read())
        config = decoder:result()
        file.close()
    end
    return config
end

function M.save(filename, config)
    local encoder = sjson.encoder(config)
    if file.open(filename, "w+") then
        file.write(encoder:read())
        file.close()
    end
end

local function tableMerge(t1, t2)
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            tableMerge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

local function convertJson(jsonString)
    local decoder = sjson.decoder()
    decoder:write(jsonString)
    jsonTbl = decoder:result()
    return jsonTbl
end

function M.updatePartial(filename, newConfigString)
    local currentConfig = M.load(filename)
    local newConfig = convertJson(newConfigString)
    newTbl = tableMerge(currentConfig, newConfig)
    M.save(filename, newTbl)
end

return M