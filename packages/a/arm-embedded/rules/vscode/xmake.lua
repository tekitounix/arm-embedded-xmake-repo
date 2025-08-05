--!ARM Embedded VSCode Integration Rule
--
-- Project-level VSCode configuration generator
-- Based on xmake's plugin.compile_commands.autoupdate design
--

-- update VSCode settings.json automatically for embedded projects
rule("embedded.vscode")
    set_kind("project")
    after_build(function (opt)

        -- imports
        import("core.project.config")
        import("core.project.depend")
        import("core.project.project")

        -- we should not update it if we are installing xmake package
        if os.getenv("XMAKE_IN_XREPO") then
            return
        end

        -- run only once for all xmake process
        local tmpfile = path.join(config.builddir(), ".gens", "rules", "embedded.vscode")
        local dependfile = tmpfile .. ".d"
        local lockfile = io.openlock(tmpfile .. ".lock")
        if lockfile:trylock() then
            local outputdir
            local embedded_targets = {}
            local has_embedded_targets = false
            
            for _, target in pairs(project.targets()) do
                -- check if target uses embedded rule
                if target:rule("embedded") then
                    has_embedded_targets = true
                    local mcu = target:values("embedded.mcu")
                    local toolchain = target:values("embedded.toolchain")
                    
                    -- if toolchain is not explicitly set, try to determine from compile commands
                    if not toolchain or #toolchain == 0 then
                        -- try to get compiler info to determine toolchain
                        local compiler = target:compiler("cxx") or target:compiler("cc")
                        if compiler then
                            local compiler_path = compiler:program()
                            print(string.format("DEBUG: target %s compiler path: %s", target:name(), compiler_path or "nil"))
                            if compiler_path then
                                if compiler_path:find("clang") then
                                    toolchain = {"clang-arm"}
                                    print(string.format("DEBUG: detected clang-arm for %s", target:name()))
                                elseif compiler_path:find("gcc") or compiler_path:find("g%+%+") then
                                    toolchain = {"gcc-arm"}
                                    print(string.format("DEBUG: detected gcc-arm for %s", target:name()))
                                else
                                    -- default fallback for embedded targets
                                    toolchain = {"clang-arm"}
                                    print(string.format("DEBUG: fallback to clang-arm for %s", target:name()))
                                end
                            else
                                toolchain = {"clang-arm"}
                                print(string.format("DEBUG: no compiler path, fallback to clang-arm for %s", target:name()))
                            end
                        else
                            toolchain = {"clang-arm"}
                            print(string.format("DEBUG: no compiler found, fallback to clang-arm for %s", target:name()))
                        end
                    else
                        print(string.format("DEBUG: explicit toolchain for %s: %s", target:name(), table.concat(toolchain, ",")))
                    end
                    
                    if mcu and toolchain then
                        table.insert(embedded_targets, {
                            name = target:name(),
                            mcu = mcu,
                            toolchain = toolchain,
                            includedirs = target:get("includedirs") or {},
                            defines = target:get("defines") or {}
                        })
                    end
                end
                
                -- get outputdir configuration if available
                local extraconf = target:extraconf("rules", "embedded.vscode")
                if extraconf then
                    outputdir = extraconf.outputdir
                end
            end
            
            -- generate VSCode config for all C/C++ projects (not just embedded)
            -- if has_embedded_targets then -- removed this check to support all projects
            if true then  -- always generate VSCode config
                depend.on_changed(function ()
                    
                    -- imports
                    import("core.base.json")
                    
                    -- generate VSCode settings.json using xmake's approach
                    local vscode_dir = outputdir or ".vscode"
                    local settings_file = path.join(vscode_dir, "settings.json")
                    
                    -- ensure .vscode directory exists
                    if not os.isdir(vscode_dir) then
                        os.mkdir(vscode_dir)
                    end
                    
                    -- collect unique compiler query drivers
                    local query_drivers_set = {}
                    local query_drivers = {}
                    for _, target_info in ipairs(embedded_targets) do
                        local driver = nil
                        if target_info.toolchain == "gcc-arm" then
                            driver = "~/.xmake/packages/g/gcc-arm/*/bin/arm-none-eabi-gcc"
                        elseif target_info.toolchain == "clang-arm" then
                            driver = "~/.xmake/packages/c/clang-arm/*/bin/clang"
                        end
                        
                        if driver and not query_drivers_set[driver] then
                            query_drivers_set[driver] = true
                            table.insert(query_drivers, driver)
                        end
                    end
                    
                    -- sort to ensure consistent order
                    table.sort(query_drivers)
                    
                    -- prepare clangd arguments (only those that cannot be set in .clangd)
                    local clangd_args = {
                        "--log=error"
                    }
                    
                    -- add query-driver if we have toolchains
                    if #query_drivers > 0 then
                        table.insert(clangd_args, "--query-driver=" .. table.concat(query_drivers, ","))
                    end
                    
                    -- read existing settings if present
                    local settings = {}
                    local needs_update = true
                    if os.isfile(settings_file) then
                        local existing_settings = try { function() return json.loadfile(settings_file) end }
                        if existing_settings then
                            settings = existing_settings
                            -- check if clangd.arguments already matches
                            if settings["clangd.arguments"] and type(settings["clangd.arguments"]) == "table" then
                                -- compare arguments more intelligently
                                local function normalize_args(args)
                                    local normalized = {}
                                    for _, arg in ipairs(args) do
                                        table.insert(normalized, arg)
                                    end
                                    table.sort(normalized)
                                    return table.concat(normalized, "|")
                                end
                                
                                local existing_normalized = normalize_args(settings["clangd.arguments"])
                                local new_normalized = normalize_args(clangd_args)
                                
                                if existing_normalized == new_normalized then
                                    needs_update = false
                                end
                            end
                        end
                    end
                    
                    -- Always add common clangd settings even for non-embedded projects
                    -- These settings are beneficial for all C/C++ projects
                    local enhanced_clangd_args = table.copy(clangd_args)
                    
                    -- Enable clang-tidy (matches Diagnostics.ClangTidy in .clangd)
                    table.insert(enhanced_clangd_args, "--clang-tidy")
                    
                    -- Set header insertion to never to avoid unwanted includes
                    table.insert(enhanced_clangd_args, "--header-insertion=never")
                    
                    -- Enable all scopes for completion (matches Completion.AllScopes in .clangd)
                    table.insert(enhanced_clangd_args, "--all-scopes-completion")
                    
                    -- update only if needed
                    if needs_update then
                        settings["clangd.arguments"] = enhanced_clangd_args
                        
                        -- write settings.json with proper formatting (xmake style)
                        local jsonfile = io.open(settings_file, "w")
                        if jsonfile then
                            -- collect and sort keys to maintain order
                            local keys = {}
                            for key, _ in pairs(settings) do
                                table.insert(keys, key)
                            end
                            table.sort(keys)
                            
                            jsonfile:write("{\n")
                            
                            for i, key in ipairs(keys) do
                                local value = settings[key]
                                if i > 1 then
                                    jsonfile:write(",\n")
                                end
                                
                                if key == "clangd.arguments" then
                                    jsonfile:write("  \"clangd.arguments\": [\n")
                                    for j, arg in ipairs(value) do
                                        local separator = (j < #value) and "," or ""
                                        jsonfile:write(string.format("    \"%s\"%s\n", arg, separator))
                                    end
                                    jsonfile:write("  ]")
                                elseif type(value) == "table" then
                                    -- handle other array/object settings with proper formatting
                                    local encoded = json.encode(value)
                                    jsonfile:write(string.format("  \"%s\": %s", key, encoded))
                                elseif type(value) == "string" then
                                    jsonfile:write(string.format("  \"%s\": \"%s\"", key, value))
                                elseif type(value) == "number" then
                                    jsonfile:write(string.format("  \"%s\": %s", key, value))
                                else
                                    jsonfile:write(string.format("  \"%s\": %s", key, tostring(value)))
                                end
                            end
                            
                            jsonfile:write("\n}\n")
                            jsonfile:close()
                            print("settings.json updated!")
                        else
                            print("error: failed to write settings.json")
                        end
                    end
                    
                    -- Generate tasks.json for embedded targets
                    local default_target = nil
                    local vscode_target = nil
                    
                    -- First, check for vscode.target in rule configuration
                    for _, target in pairs(project.targets()) do
                        local extraconf = target:extraconf("rules", "embedded.vscode")
                        if extraconf and extraconf.target then
                            vscode_target = extraconf.target
                            break
                        end
                    end
                    
                    -- Validate vscode_target if specified
                    if vscode_target then
                        local found = false
                        for _, target_info in ipairs(embedded_targets) do
                            if target_info.name == vscode_target then
                                default_target = vscode_target
                                found = true
                                break
                            end
                        end
                        if not found then
                            print(string.format("warning: vscode target '%s' not found in embedded targets, available targets:", vscode_target))
                            for _, target_info in ipairs(embedded_targets) do
                                print(string.format("  - %s", target_info.name))
                            end
                        end
                    end
                    
                    -- Fallback to default target if no vscode target specified or found
                    if not default_target then
                        for _, target_info in ipairs(embedded_targets) do
                            local target = project.target(target_info.name)
                            if target and target:get("default") then
                                default_target = target_info.name
                                break
                            end
                        end
                    end
                    
                    -- Final fallback to first embedded target
                    if not default_target and #embedded_targets > 0 then
                        default_target = embedded_targets[1].name
                        print(string.format("warning: no default target specified, using '%s' for vscode configuration", default_target))
                    end
                    
                    if default_target then
                        local tasks_file = path.join(vscode_dir, "tasks.json")
                        local tasks = {
                            version = "2.0.0",
                            tasks = {
                                {
                                    label = "Build (Release)",
                                    type = "shell",
                                    command = "xmake config -m release && xmake build " .. default_target,
                                    args = {},
                                    group = "build",
                                    problemMatcher = "$gcc"
                                },
                                {
                                    label = "Build (Debug)",
                                    type = "shell",
                                    command = "xmake config -m debug && xmake build " .. default_target,
                                    args = {},
                                    group = "build",
                                    problemMatcher = "$gcc"
                                },
                                {
                                    label = "Clean",
                                    type = "shell",
                                    command = "xmake",
                                    args = {"clean", default_target},
                                    problemMatcher = {}
                                },
                                {
                                    label = "Build & Flash",
                                    type = "shell",
                                    command = "xmake config -m release && xmake build " .. default_target .. " && xmake flash -t " .. default_target,
                                    args = {},
                                    group = {
                                        kind = "build",
                                        isDefault = true
                                    },
                                    problemMatcher = "$gcc"
                                }
                            }
                        }
                        
                        -- Write tasks.json
                        local tasksfile = io.open(tasks_file, "w")
                        if tasksfile then
                            tasksfile:write("{\n")
                            tasksfile:write(string.format("  \"version\": \"%s\",\n", tasks.version))
                            tasksfile:write("  \"tasks\": [\n")
                            
                            for i, task in ipairs(tasks.tasks) do
                                tasksfile:write("    {\n")
                                tasksfile:write(string.format("      \"label\": \"%s\",\n", task.label))
                                tasksfile:write(string.format("      \"type\": \"%s\",\n", task.type))
                                tasksfile:write(string.format("      \"command\": \"%s\",\n", task.command))
                                
                                -- Write args array
                                if task.args and #task.args > 0 then
                                    tasksfile:write("      \"args\": [")
                                    for j, arg in ipairs(task.args) do
                                        if j > 1 then tasksfile:write(", ") end
                                        tasksfile:write(string.format("\"%s\"", arg))
                                    end
                                    tasksfile:write("],\n")
                                else
                                    tasksfile:write("      \"args\": [],\n")
                                end
                                
                                -- Write group if present
                                if task.group then
                                    if type(task.group) == "table" then
                                        tasksfile:write("      \"group\": {\n")
                                        tasksfile:write(string.format("        \"kind\": \"%s\"", task.group.kind))
                                        if task.group.isDefault then
                                            tasksfile:write(",\n        \"isDefault\": true")
                                        end
                                        tasksfile:write("\n      },\n")
                                    else
                                        tasksfile:write(string.format("      \"group\": \"%s\",\n", task.group))
                                    end
                                end
                                
                                -- Write problemMatcher
                                tasksfile:write("      \"problemMatcher\": ")
                                if type(task.problemMatcher) == "table" and #task.problemMatcher == 0 then
                                    tasksfile:write("[]")
                                else
                                    tasksfile:write(string.format("\"%s\"", task.problemMatcher))
                                end
                                
                                if i < #tasks.tasks then
                                    tasksfile:write("\n    },\n")
                                else
                                    tasksfile:write("\n    }\n")
                                end
                            end
                            
                            tasksfile:write("  ]\n")
                            tasksfile:write("}\n")
                            tasksfile:close()
                            print("tasks.json updated!")
                        end
                        
                        -- Generate launch.json for debugging
                        local launch_file = path.join(vscode_dir, "launch.json")
                        local launch = {
                            version = "0.2.0",
                            configurations = {
                                {
                                    name = "Debug Embedded",
                                    type = "cortex-debug",
                                    request = "launch",
                                    servertype = "pyocd",
                                    cwd = "${workspaceFolder}",
                                    executable = "${workspaceFolder}/.build/cross/arm/debug/" .. default_target,
                                    runToEntryPoint = "main",
                                    showDevDebugOutput = "none",
                                    preLaunchTask = "Build (Debug)"
                                }
                            }
                        }
                        
                        -- Write launch.json
                        local launchfile = io.open(launch_file, "w")
                        if launchfile then
                            launchfile:write("{\n")
                            launchfile:write(string.format("  \"version\": \"%s\",\n", launch.version))
                            launchfile:write("  \"configurations\": [\n")
                            
                            for i, config in ipairs(launch.configurations) do
                                launchfile:write("    {\n")
                                launchfile:write(string.format("      \"name\": \"%s\",\n", config.name))
                                launchfile:write(string.format("      \"type\": \"%s\",\n", config.type))
                                launchfile:write(string.format("      \"request\": \"%s\",\n", config.request))
                                launchfile:write(string.format("      \"servertype\": \"%s\",\n", config.servertype))
                                launchfile:write(string.format("      \"cwd\": \"%s\",\n", config.cwd))
                                launchfile:write(string.format("      \"executable\": \"%s\",\n", config.executable))
                                launchfile:write(string.format("      \"runToEntryPoint\": \"%s\",\n", config.runToEntryPoint))
                                launchfile:write(string.format("      \"showDevDebugOutput\": \"%s\",\n", config.showDevDebugOutput))
                                launchfile:write(string.format("      \"preLaunchTask\": \"%s\"", config.preLaunchTask))
                                
                                if i < #launch.configurations then
                                    launchfile:write("\n    },\n")
                                else
                                    launchfile:write("\n    }\n")
                                end
                            end
                            
                            launchfile:write("  ]\n")
                            launchfile:write("}\n")
                            launchfile:close()
                            print("launch.json updated!")
                        end
                    end
                    
                end, {dependfile = dependfile,
                      files = table.join(project.allfiles(), config.filepath()),
                      values = embedded_targets})
            end
            
            lockfile:close()
        end
    end)