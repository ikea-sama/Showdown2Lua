--[[
    File:        | Showdown2Lua.luau
    Author:      | Gilbert University Computer Science Club 
    Description: | Convert Pokémon Showdown data to Lua

    Notes:
        * "why are EVs and IVs being parsed separately?" no reason :buddha:
        * A way to convert Luau Pokémon data to Showdown data was planned, but it is pretty useless (so it was scrapped)
        * Pokémon nicknames are not supported (fork and do it yourself)
        * Hidden power was not fully implemented (fork and DIY)
]]--
--------------------------------------------------------------------------------------------------------------------------------


-- >> Functions
local string_find        = string.find
local string_format      = string.format
local string_gsub        = string.gsub
local string_lower       = string.lower
local string_split       = string.split
local string_sub         = string.sub
local string_upper       = string.upper

local table_clone        = table.clone
local table_concat       = table.concat
local table_find         = table.find
local table_insert       = table.insert
local table_remove       = table.remove
local tonumber           = tonumber
local type               = type


-- >> Important data
local stat_types         = {"HP", "Atk", "Def", "SpA", "SpD", "Spe"}
local Showdown           = {}
--------------------------------------------------------------------------------------------------------------------------------

-- >> Helper functions

-- // Sanitize string data by changing it to lowercase & removing unsupported characters
local function sanitize_data(text: string)
    return (string_gsub(string_lower(text), "[^a-z0-9]+", ""))
end
--------------------------------------------------------------------------------------------------------------------------------

-- >> Main code

-- // Convert Showdown data to Luau
local function ShowdownToLuau(data: string)
    local lines             = string_split(data, "\n")

    local species           = string_split(lines[1], " ")[1]
    local forme             = nil
    local gender            = (string_find(lines[1], "(M)") and "M") or (string_find(lines[1], "(F)") and "F") or nil
    local held_item         = string_split(lines[1], "@ ")[2]

    local ability           = string_split(lines[2], "Ability: ")[2]
    local level             = 100 -- If a level is not specified, Pokémon Showdown assumes it to be 100
    local is_shiny          = false

    local tera_type         -- this mechanic isn't implemented, but it was added anyways
    local effort_values     = table_clone(stat_types)
    local individual_values = table_clone(stat_types)

    local nature

    local moves             = {}

----------------------------------------------------------------

    -- determine the pokémon's forme
    if (string_find(species, "-")) then
        forme   = string_split(species, "-")[2]
        species = string_gsub(species, ("-" .. forme), "")
    end

    for _, line in pairs(lines) do
        -- determine the level
        if (string_split(line, " ")[1] == "Level:") then
            level = tonumber(string_split(line, "Level: ")[2])
        end

        -- determine the tera type (again, it's pointless (and was done for the sake of just doing it))
        if (string_split(line, " ")[1] == "Tera") then
            tera_type = string_split(line, " ")[3]
        end

        -- determine if the pokémon is shiny
        if (string_split(line, " ")[1] == "Shiny:") then
            is_shiny = (string_split(line, " ")[2] == "Yes")
        end

        -- determine the nature
        if (string_split(line, " ")[2] == "Nature") then
            nature = string_split(line, " ")[1]
        end

        -- yandere simulator type code below :(
        -- determine Effort Values
        if (string_split(line, " ")[1] == "EVs:") then
            line = string_gsub(line, "EVs: ", "")
            line = string_gsub(line, "/", "")

            local new_evs  = string_split(line, "  ")

            for _,stat_type in next, (stat_types) do
                for __, ev_type_raw in pairs(new_evs) do
                    local ev_value = string_split(ev_type_raw, " ")[1]
                    local ev_type  = string_split(ev_type_raw, " ")[2]

                    if ((stat_type == ev_type) and (table_find(effort_values, ev_type))) then
                        effort_values[table_find(effort_values, ev_type)] = tonumber(ev_value)
                    end
                end
            end

            for _, ev_value in pairs(effort_values) do
                if (type(ev_value) == "string") then
                    effort_values[_] = 0
                end
            end
        end

        -- determine Individual Values
        -- its ugly yeah
        if (string_split(line, " ")[1] == "IVs:") then
            local iv_data = string_split(line, " ")
            table_remove(iv_data, 1)

            iv_data       = table_concat(iv_data, " ")
            iv_data       = string_split(iv_data, "/")

            -- remove spaces from the beginning & end of each IV chunk
            for _,iv_chunk in next, (iv_data) do
                if (string_sub(iv_chunk, 1, 1) == " ") then
                    iv_data[_] = string_sub(iv_chunk, 2, #iv_chunk)
                end
            end

            for _, iv_chunk in next, (iv_data) do -- silly double-loop solution
                if (string_sub(iv_chunk, #iv_chunk) == " ") then
                    iv_data[_] = string_sub(iv_chunk, 1, (#iv_chunk - 1))
                end
            end

            -- actually insert the IVs
            for _, iv_chunk in next, (iv_data) do   -- just kidding (it was a triple-loop solution)
                local iv_value = tonumber(string_split(iv_chunk, " ")[1])
                local iv_type  = string_split(iv_chunk, " ")[2]
                individual_values[table_find(individual_values, iv_type)] = iv_value
            end

            for _, iv_value in next, (individual_values) do -- it was a lie (quadruple loop)
                if (type(iv_value) == "string") then
                    individual_values[_] = 31
                end
            end
        end

        -- determine moves
        if (string_split(line, " ")[1] == "-") then
            local move = string_gsub(line, "- ", "")
            table_insert(moves, {id = sanitize_data(move)})
        end
    end
    ----------------------------------------------------------------

    local converted_data_table = {
        species   = sanitize_data(species),
        forme     = (forme and sanitize_data(forme)),
        gender    = gender,
        item      = sanitize_data(held_item),
        ability   = sanitize_data(ability),
        level     = level,
        shiny     = is_shiny,
        nature    = (nature and string_lower(nature)),
        tera_type = (tera_type and sanitize_data(tera_type)),
        evs       = effort_values,
        ivs       = individual_values,
        moves     = moves
    }

    return converted_data_table
end

--------------------------------------------------------------------------------------------------------------------------------

-- Convert Pokémon Showdown data to Lua
function Showdown.toLua(data: string): table
    local data_converted_to_showdown = {}

    if (string_find(data, "\n\n")) then
        for _, data_chunk in next, (string_split(data, "\n\n")) do
            table_insert(data_converted_to_showdown, ShowdownToLuau(data_chunk))
        end
    else
        data_converted_to_showdown = ShowdownToLuau(data)
    end

    return data_converted_to_showdown
end
--------------------------------------------------------------------------------------------------------------------------------

return Showdown
