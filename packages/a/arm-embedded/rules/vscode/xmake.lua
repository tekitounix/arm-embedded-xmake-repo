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
                            if compiler_path then
                                if compiler_path:find("clang") then
                                    toolchain = {"clang-arm"}
                                elseif compiler_path:find("gcc") or compiler_path:find("g%+%+") then
                                    toolchain = {"gcc-arm"}
                                else
                                    -- default fallback for embedded targets
                                    toolchain = {"clang-arm"}
                                end
                            else
                                toolchain = {"clang-arm"}
                            end
                        else
                            toolchain = {"clang-arm"}
                        end
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
                        local toolchain = target_info.toolchain
                        
                        -- handle both string and array toolchain values
                        if type(toolchain) == "table" then
                            toolchain = toolchain[1] -- take first element if array
                        end
                        
                        if toolchain == "gcc-arm" then
                            driver = "~/.xmake/packages/g/gcc-arm/*/bin/arm-none-eabi-g++"
                        elseif toolchain == "clang-arm" then
                            driver = "~/.xmake/packages/c/clang-arm/*/bin/clang++"
                        end
                        
                        if driver and not query_drivers_set[driver] then
                            query_drivers_set[driver] = true
                            table.insert(query_drivers, driver)
                        end
                    end
                    
                    -- sort to ensure consistent order
                    table.sort(query_drivers)

                    -- Build clangd arguments with all necessary settings
                    local clangd_args = {
                        "--log=error",
                        "--compile-commands-dir=.build/",
                        "--clang-tidy",
                        "--header-insertion=never",
                        "--all-scopes-completion"
                    }

                    -- Add query-driver for cross-compilers (required for clangd to find stdlib)
                    if #query_drivers > 0 then
                        table.insert(clangd_args, "--query-driver=" .. table.concat(query_drivers, ","))
                    end

                    -- Read existing settings and check if update is needed
                    local settings = {}
                    local needs_update = true
                    if os.isfile(settings_file) then
                        local existing_settings = try { function() return json.loadfile(settings_file) end }
                        if existing_settings then
                            settings = existing_settings
                            -- Compare existing clangd.arguments with new ones
                            if settings["clangd.arguments"] and type(settings["clangd.arguments"]) == "table" then
                                local function normalize_args(args)
                                    local sorted = {}
                                    for _, arg in ipairs(args) do
                                        table.insert(sorted, arg)
                                    end
                                    table.sort(sorted)
                                    return table.concat(sorted, "|")
                                end
                                if normalize_args(settings["clangd.arguments"]) == normalize_args(clangd_args) then
                                    needs_update = false
                                end
                            end
                        end
                    end

                    -- Update settings if needed
                    if needs_update then
                        settings["clangd.arguments"] = clangd_args
                        
                        -- Use installed clang-format config file with absolute path
                        local home_dir = os.getenv("HOME") or os.getenv("USERPROFILE")
                        if home_dir then
                            local clang_format_path = path.join(home_dir, ".xmake", "rules", "coding", "configs", ".clang-format")
                            settings["clang-format.style"] = "file:" .. clang_format_path
                        end
                        
                        -- Write settings.json with proper formatting (preserving user settings)
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
                                elseif type(value) == "boolean" then
                                    jsonfile:write(string.format("  \"%s\": %s", key, tostring(value)))
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
                        
                        -- Define our managed task labels
                        local managed_labels = {
                            "Build (Release)",
                            "Build (Debug)", 
                            "Clean",
                            "Build & Flash"
                        }
                        
                        -- Load existing tasks.json and preserve non-managed tasks
                        local tasks = {
                            version = "2.0.0",
                            tasks = {}
                        }
                        
                        if os.isfile(tasks_file) then
                            local existing_tasks = try { function() return json.loadfile(tasks_file) end }
                            if existing_tasks then
                                tasks.version = existing_tasks.version or "2.0.0"
                                if existing_tasks.tasks then
                                    -- Filter out managed tasks, keep user tasks
                                    for _, task in ipairs(existing_tasks.tasks) do
                                        local is_managed = false
                                        for _, managed_label in ipairs(managed_labels) do
                                            if task.label == managed_label then
                                                is_managed = true
                                                break
                                            end
                                        end
                                        if not is_managed then
                                            table.insert(tasks.tasks, task)
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Add our managed tasks
                        local managed_tasks = {
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
                        
                        -- Append managed tasks to existing tasks
                        for _, managed_task in ipairs(managed_tasks) do
                            table.insert(tasks.tasks, managed_task)
                        end
                        
                        -- Write tasks.json with proper formatting (preserving user tasks)
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
                                elseif type(task.problemMatcher) == "string" then
                                    tasksfile:write(string.format("\"%s\"", task.problemMatcher))
                                else
                                    -- Default to empty array for nil or other values
                                    tasksfile:write("[]")
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
                        
                        -- Define our managed configuration names
                        local managed_names = {
                            "Debug Embedded",
                            "RTT Debug (OpenOCD)"
                        }
                        
                        -- Load existing launch.json and preserve non-managed configurations
                        local launch = {
                            version = "0.2.0",
                            configurations = {}
                        }
                        
                        if os.isfile(launch_file) then
                            local existing_launch = try { function() return json.loadfile(launch_file) end }
                            if existing_launch then
                                launch.version = existing_launch.version or "0.2.0"
                                if existing_launch.configurations then
                                    -- Filter out managed configurations, keep user configurations
                                    for _, config in ipairs(existing_launch.configurations) do
                                        local is_managed = false
                                        for _, managed_name in ipairs(managed_names) do
                                            if config.name == managed_name then
                                                is_managed = true
                                                break
                                            end
                                        end
                                        if not is_managed then
                                            table.insert(launch.configurations, config)
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- MCU to device mapping for pyOCD
                        local mcu_to_device = {
                            ["stm32f407vgt6"] = "STM32F407VG",
                            ["stm32f407vg"] = "STM32F407VG",
                            ["stm32f405rg"] = "STM32F405RG",
                            ["stm32f103c8t6"] = "STM32F103C8",
                            ["stm32f103c8"] = "STM32F103C8",
                            ["stm32f746zg"] = "STM32F746ZG",
                            ["stm32h743zi"] = "STM32H743ZI"
                        }
                        
                        -- Get device name from MCU
                        local device_name = nil
                        for _, target_info in ipairs(embedded_targets) do
                            if target_info.name == default_target and target_info.mcu then
                                local mcu_lower = string.lower(target_info.mcu[1] or target_info.mcu)
                                device_name = mcu_to_device[mcu_lower] or string.upper(target_info.mcu[1] or target_info.mcu)
                                break
                            end
                        end
                        
                        -- Add our managed configurations
                        local managed_config = {
                            name = "Debug Embedded",
                            type = "cortex-debug",
                            request = "launch",
                            servertype = "openocd",
                            cwd = "${workspaceFolder}",
                            executable = "${workspaceFolder}/.build/" .. default_target .. "/debug/" .. default_target,
                            runToEntryPoint = "main",
                            showDevDebugOutput = "none",
                            preLaunchTask = "Build (Debug)",
                            configFiles = {
                                "interface/stlink.cfg",
                                "target/stm32f4x.cfg"
                            }
                        }
                        
                        -- Add device if available
                        if device_name then
                            managed_config.device = device_name
                        end
                        
                        table.insert(launch.configurations, managed_config)
                        
                        -- Add RTT configuration
                        local rtt_config = {
                            name = "RTT Debug (OpenOCD)",
                            type = "cortex-debug",
                            request = "launch",
                            servertype = "openocd",
                            executable = "${workspaceFolder}/.build/" .. default_target .. "/debug/" .. default_target,
                            runToEntryPoint = "main",
                            rttConfig = {
                                enabled = true,
                                address = "0x20000000",
                                searchSize = 131072,
                                searchId = "RT MONITOR",
                                decoders = {
                                    {
                                        port = 0,
                                        type = "console",
                                        timestamp = true
                                    }
                                }
                            },
                            preLaunchTask = "Build (Debug)",
                            configFiles = {
                                "interface/stlink.cfg",
                                "target/stm32f4x.cfg"
                            }
                        }
                        
                        -- Add device if available
                        if device_name then
                            rtt_config.device = device_name
                        end
                        
                        table.insert(launch.configurations, rtt_config)
                        
                        -- Write launch.json with proper formatting (preserving user configurations)
                        local launchfile = io.open(launch_file, "w")
                        if launchfile then
                            launchfile:write("{\n")
                            launchfile:write(string.format("  \"version\": \"%s\",\n", launch.version))
                            launchfile:write("  \"configurations\": [\n")
                            
                            for i, config in ipairs(launch.configurations) do
                                launchfile:write("    {\n")
                                launchfile:write(string.format("      \"name\": \"%s\",\n", config.name or ""))
                                launchfile:write(string.format("      \"type\": \"%s\",\n", config.type or ""))
                                launchfile:write(string.format("      \"request\": \"%s\"", config.request or ""))
                                
                                -- Write optional fields only if they exist
                                if config.program then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"program\": \"%s\"", config.program))
                                end
                                if config.servertype then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"servertype\": \"%s\"", config.servertype))
                                end
                                if config.cwd then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"cwd\": \"%s\"", config.cwd))
                                end
                                if config.executable then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"executable\": \"%s\"", config.executable))
                                end
                                if config.runToEntryPoint then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"runToEntryPoint\": \"%s\"", config.runToEntryPoint))
                                end
                                if config.showDevDebugOutput then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"showDevDebugOutput\": \"%s\"", config.showDevDebugOutput))
                                end
                                if config.preLaunchTask then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"preLaunchTask\": \"%s\"", config.preLaunchTask))
                                end
                                if config.device then
                                    launchfile:write(",\n")
                                    launchfile:write(string.format("      \"device\": \"%s\"", config.device))
                                end
                                if config.rttConfig then
                                    launchfile:write(",\n")
                                    launchfile:write("      \"rttConfig\": {\n")
                                    launchfile:write(string.format("        \"enabled\": %s,\n", tostring(config.rttConfig.enabled)))
                                    launchfile:write(string.format("        \"address\": \"%s\",\n", config.rttConfig.address))
                                    launchfile:write(string.format("        \"searchSize\": %d,\n", config.rttConfig.searchSize))
                                    launchfile:write(string.format("        \"searchId\": \"%s\",\n", config.rttConfig.searchId))
                                    launchfile:write("        \"decoders\": [\n")
                                    for j, decoder in ipairs(config.rttConfig.decoders) do
                                        launchfile:write("          {\n")
                                        launchfile:write(string.format("            \"port\": %d,\n", decoder.port))
                                        launchfile:write(string.format("            \"type\": \"%s\",\n", decoder.type))
                                        launchfile:write(string.format("            \"timestamp\": %s\n", tostring(decoder.timestamp)))
                                        if j < #config.rttConfig.decoders then
                                            launchfile:write("          },\n")
                                        else
                                            launchfile:write("          }\n")
                                        end
                                    end
                                    launchfile:write("        ]\n")
                                    launchfile:write("      }")
                                end
                                if config.configFiles then
                                    launchfile:write(",\n")
                                    launchfile:write("      \"configFiles\": [\n")
                                    for j, configFile in ipairs(config.configFiles) do
                                        local separator = (j < #config.configFiles) and "," or ""
                                        launchfile:write(string.format("        \"%s\"%s\n", configFile, separator))
                                    end
                                    launchfile:write("      ]")
                                end
                                
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