--!ARM Embedded VSCode Settings Generator Task
--
-- Generates VSCode settings.json for embedded projects
-- Based on xmake's compile_commands task design
--

-- imports
import("core.base.option")
import("core.base.json")
import("core.project.project")

-- generate VSCode settings.json
function make(outputdir)
    local settings_dir = outputdir or ".vscode"
    local settings_file = path.join(settings_dir, "settings.json")
    
    -- ensure .vscode directory exists
    if not os.isdir(settings_dir) then
        os.mkdir(settings_dir)
    end
    
    -- collect all embedded targets and their configurations
    local embedded_targets = {}
    local query_drivers = {}
    
    for _, target in pairs(project.targets()) do
        -- check if target uses embedded rule
        if target:rule("embedded") then
            local mcu = target:values("embedded.mcu")
            local toolchain = target:values("embedded.toolchain")
            if mcu and toolchain then
                table.insert(embedded_targets, {
                    name = target:name(),
                    mcu = mcu,
                    toolchain = toolchain,
                    includedirs = target:get("includedirs") or {},
                    defines = target:get("defines") or {}
                })
                
                -- collect query drivers
                if toolchain == "gcc-arm" then
                    table.insert(query_drivers, "~/.xmake/packages/g/gcc-arm/*/bin/arm-none-eabi-gcc")
                elseif toolchain == "clang-arm" then
                    table.insert(query_drivers, "~/.xmake/packages/c/clang-arm/*/bin/clang")
                end
            end
        end
    end
    
    -- only generate VSCode config if we have embedded targets
    if #embedded_targets > 0 then
        -- remove duplicates from query drivers
        query_drivers = table.unique(query_drivers)
        
        -- prepare VSCode settings
        local settings = {
            ["clangd.arguments"] = {
                "--compile-commands-dir=${workspaceFolder}/.build",
                "--background-index",
                "--header-insertion=never",
                "--clang-tidy",
                "--log=error"
            }
        }
        
        -- add query-driver if we have toolchains
        if #query_drivers > 0 then
            table.insert(settings["clangd.arguments"], "--query-driver=" .. table.concat(query_drivers, ","))
        end
        
        -- write settings.json with proper formatting (following xmake's approach)
        local jsonfile = io.open(settings_file, "w")
        if jsonfile then
            jsonfile:write("{\n")
            jsonfile:write("  \"clangd.arguments\": [\n")
            for i, arg in ipairs(settings["clangd.arguments"]) do
                local comma = (i < #settings["clangd.arguments"]) and "" or ","
                jsonfile:printf("    \"%s\"%s\n", arg, comma)
            end
            jsonfile:write("  ]\n")
            jsonfile:write("}\n")
            jsonfile:close()
            print("Updated VSCode settings.json with clangd configuration")
        else
            print("Error: Could not write VSCode settings.json")
        end
    end
end