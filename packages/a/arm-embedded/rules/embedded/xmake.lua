-- ARM Embedded Build Rule with External Database Loading

rule("embedded")
    on_load(function(target)
        -- Load required modules
        import("core.base.global")
        
        -- Load all database modules using JSON
        import("core.base.json")
        local rule_dir = os.scriptdir()
        local database_dir = path.join(rule_dir, "database")
        
        -- Load Cortex-M database from JSON
        local cortex_data = json.loadfile(path.join(database_dir, "cortex-m.json"))
        if not cortex_data then
            raise("Failed to load database/cortex-m.json")
        end
        
        -- Load MCU database from JSON
        local mcu_data = json.loadfile(path.join(database_dir, "mcu-database.json"))
        if not mcu_data then
            raise("Failed to load database/mcu-database.json")
        end
        
        -- Load build options database from JSON
        local build_data = json.loadfile(path.join(database_dir, "build-options.json"))
        if not build_data then
            raise("Failed to load database/build-options.json")
        end
        
        -- Load toolchain configs from JSON
        local toolchain_data = json.loadfile(path.join(database_dir, "toolchain-configs.json"))
        if not toolchain_data then
            raise("Failed to load database/toolchain-configs.json")
        end
        
        -- Helper to get core configuration
        local function get_core_config(core_name)
            return cortex_data.cores[core_name]
        end
        
        -- Helper to convert size strings (like "1M", "128K") to bytes
        local function size_to_bytes(size_str)
            local num, unit = size_str:match("(%d+)([KMG]?)")
            num = tonumber(num)
            if unit == "K" then
                return num * 1024
            elseif unit == "M" then
                return num * 1024 * 1024
            elseif unit == "G" then
                return num * 1024 * 1024 * 1024
            else
                return num
            end
        end
        
        local mcu_db = {
            get_config = function(mcu_name)
                return mcu_data.CONFIGS[mcu_name:lower()]
            end
        }
        
        -- Set target properties
        target:set("kind", "binary")
        target:set("plat", "cross")
        target:set("arch", "arm")
        target:set("strip", "none")  -- Don't strip embedded binaries
        target:set("optimize", "none")  -- Disable xmake's default optimization
        target:set("symbols", "none")   -- Disable xmake's default symbol settings
        
        -- Set target-specific build directory
        local build_mode = is_mode and (is_mode("debug") and "debug" or "release") or "release"
        target:set("targetdir", path.join("$(builddir)", target:name(), build_mode))
        target:set("objectdir", path.join("$(builddir)", target:name(), build_mode, ".objs"))
        
        -- Get MCU and toolchain configuration
        local mcu = target:values("embedded.mcu")
        local toolchain = target:values("embedded.toolchain") or build_data.DEFAULTS.toolchain
        -- Get build type - check multiple sources
        local build_type = nil
        
        -- First, check if there's a build_type option
        if target:get("options") then
            local options = target:get("options")
            if type(options) == "table" then
                for _, opt in ipairs(options) do
                    if opt and opt.name and opt:name() == "build_type" then
                        local value = opt:get()
                        if value and value ~= "auto" then
                            build_type = value
                            -- Set xmake's mode immediately for early display consistency
                            import("core.project.config")
                            local current_mode = config.get("mode")
                            if current_mode ~= build_type then
                                config.set("mode", build_type)
                                print("ARM Embedded: Build type set to '" .. build_type .. "' (from option)")
                            end
                        end
                        break
                    end
                end
            end
        end
        
        -- If not found or set to auto, use xmake's mode
        if not build_type or build_type == "auto" then
            -- Debug: check if is_mode function exists
            if is_mode then
                if is_mode("debug") then
                    build_type = "debug"
                elseif is_mode("release") then
                    build_type = "release"
                else
                    -- Fallback to release if no mode is set
                    build_type = "release"
                end
            else
                build_type = "release"
            end
        end
        
        -- Fallback to environment variable if still not set
        if not build_type then
            build_type = os.getenv("XMAKE_BUILD_TYPE") or "release"
        end
        
        -- Set xmake's mode to match our build_type for display consistency (once per project)
        import("core.project.config")
        local current_mode = config.get("mode")
        if current_mode ~= build_type then
            config.set("mode", build_type)
            print("ARM Embedded: Build type set to '" .. build_type .. "'")
        end
        
        local optimize, debug_level, lto
        if build_type == "debug" then
            -- Force debug settings
            optimize = "debug"
            debug_level = "maximum"
            lto = "none"
        else
            -- Normal build configuration
            optimize = target:values("embedded.optimize") or build_data.DEFAULTS.optimization
            debug_level = target:values("embedded.debug_level") or build_data.DEFAULTS.debug_level
            lto = target:values("embedded.lto") or build_data.DEFAULTS.lto
        end
        
        -- Print debug info if verbose
        if target:get("verbose") then
            print("embedded: optimize=%s, debug_level=%s, lto=%s", optimize, debug_level, lto)
        end
        
        if not mcu then
            raise("embedded rule requires 'mcu' configuration. Please specify: set_values(\"embedded.mcu\", \"your_mcu_name\")")
        end
        
        -- Get MCU configuration from database
        local mcu_config = mcu_db.get_config(mcu)
        if not mcu_config then
            raise("Unknown MCU: " .. mcu .. ". Please add it to mcu-database.lua")
        end
        
        -- Get core configuration
        local core_config = get_core_config(mcu_config.core)
        if not core_config then
            raise("Unknown core type: " .. mcu_config.core)
        end
        
        -- Set toolchain directly
        target:set("toolchains", toolchain)
        
        -- Apply common flags for all cores
        for _, flag in ipairs(cortex_data.common.all_cores.flags) do
            target:add("cxflags", flag, {force = true})
        end
        for _, flag in ipairs(cortex_data.common.all_cores.ldflags) do
            target:add("ldflags", flag, {force = true})
        end
        
        -- Apply optimization based on embedded.optimize value
        local opt_flags = build_data.OPTIMIZATION_LEVELS[optimize] or build_data.OPTIMIZATION_LEVELS[build_data.DEFAULTS.optimization]
        for _, flag in ipairs(opt_flags) do
            target:add("cxflags", flag, {force = true})
        end
        
        -- Apply debug info if optimize is "debug"
        if optimize == "debug" then
            local debug_flags = build_data.DEBUG_INFO_LEVELS[debug_level] or build_data.DEBUG_INFO_LEVELS[build_data.DEFAULTS.debug_level]
            for _, flag in ipairs(debug_flags) do
                target:add("cxflags", flag, {force = true})
            end
        end
        
        -- Apply C++ embedded flags
        local cxx_flags = build_data.CXX_EMBEDDED_FLAGS
        for _, flag in ipairs(cxx_flags) do
            target:add("cxxflags", flag, {force = true})
        end
        
        -- Apply C/C++ standard versions
        local c_standard = target:values("embedded.c_standard") or build_data.DEFAULTS.c_standard
        local cxx_standard = target:values("embedded.cxx_standard") or build_data.DEFAULTS.cxx_standard
        
        -- Add C standard flag
        if build_data.C_STANDARDS[c_standard] then
            target:add("cflags", build_data.C_STANDARDS[c_standard], {force = true})
        end
        
        -- Add C++ standard flag
        if build_data.CXX_STANDARDS[cxx_standard] then
            target:add("cxxflags", build_data.CXX_STANDARDS[cxx_standard], {force = true})
        end
        
        -- Apply LTO flags if enabled
        if lto ~= "none" and build_data.LTO_OPTIONS[lto] then
            for _, flag in ipairs(build_data.LTO_OPTIONS[lto]) do
                target:add("cxflags", flag, {force = true})
            end
        end
        
        -- Apply toolchain-specific linker flags
        if toolchain == "clang-arm" then
            -- LLVM: Use -nostdlib but link required libraries
            local common_flags = cortex_data.linker_options["clang-arm"].common
            local runtime_libs = cortex_data.linker_options["clang-arm"].runtime_libs
            for _, flag in ipairs(common_flags) do
                target:add("ldflags", flag, {force = true})
            end
            for _, lib in ipairs(runtime_libs) do
                target:add("ldflags", lib, {force = true})
            end
            -- Apply LTO linker flags for Clang
            if lto ~= "none" and cortex_data.linker_options["clang-arm"].lto and cortex_data.linker_options["clang-arm"].lto[lto] then
                for _, flag in ipairs(cortex_data.linker_options["clang-arm"].lto[lto]) do
                    target:add("ldflags", flag, {force = true})
                end
            end
        else
            -- GCC: Use -nostartfiles but link libc for memcpy/memset
            local common_flags = cortex_data.linker_options["gcc-arm"].common
            local newlib_flags = cortex_data.linker_options["gcc-arm"].newlib_nano
            for _, flag in ipairs(common_flags) do
                target:add("ldflags", flag, {force = true})
            end
            for _, flag in ipairs(newlib_flags) do
                target:add("ldflags", flag, {force = true})
            end
            -- Apply LTO linker flags for GCC
            if lto ~= "none" and cortex_data.linker_options["gcc-arm"].lto and cortex_data.linker_options["gcc-arm"].lto[lto] then
                for _, flag in ipairs(cortex_data.linker_options["gcc-arm"].lto[lto]) do
                    target:add("ldflags", flag, {force = true})
                end
            end
        end
        
        -- Toolchain-specific configuration
        local tc_config = cortex_data.toolchain_specific[toolchain]
        
        if toolchain == "clang-arm" then
            -- LLVM requires target triple
            target:add("cxflags", tc_config.target_flag_prefix .. core_config.target, {force = true})
            target:add("ldflags", tc_config.target_flag_prefix .. core_config.target, {force = true})
        end
        
        -- Both GCC and LLVM use -mcpu for optimization
        local mcpu = core_config.cpu or mcu_config.core:gsub("f$", "")  -- Remove FPU suffix
        target:add("cxflags", tc_config.cpu_flag_prefix .. mcpu, {force = true})
        target:add("ldflags", tc_config.cpu_flag_prefix .. mcpu, {force = true})
        
        -- FPU configuration
        if core_config.fpu then
            -- Apply FPU-enabled flags
            for _, flag in ipairs(cortex_data.common.fpu_enabled.flags) do
                target:add("cxflags", flag, {force = true})
            end
            for _, flag in ipairs(cortex_data.common.fpu_enabled.ldflags) do
                target:add("ldflags", flag, {force = true})
            end
            
            -- Add FPU type
            local fpu_flag = tc_config.fpu_flag_prefix .. core_config.fpu
            target:add("cxflags", fpu_flag, {force = true})
            target:add("ldflags", fpu_flag, {force = true})
        else
            -- Apply FPU-disabled flags
            for _, flag in ipairs(cortex_data.common.fpu_disabled.flags) do
                target:add("cxflags", flag, {force = true})
            end
            for _, flag in ipairs(cortex_data.common.fpu_disabled.ldflags) do
                target:add("ldflags", flag, {force = true})
            end
        end
        
        -- Add toolchain include paths
        if toolchain == "clang-arm" then
            -- Add LLVM include paths
            local llvm_package = toolchain_data.PACKAGE_PATHS["clang-arm"]
            local llvm_path = path.join(global.directory(), llvm_package.base_path)
            if os.isdir(llvm_path) then
                local versions = os.dirs(path.join(llvm_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest = versions[#versions]
                    local installs = os.dirs(path.join(latest, "*"))
                    if #installs > 0 then
                        local install_dir = installs[1]
                        -- Get library directory from mapping
                        local lib_mapping = tc_config.lib_mapping[core_config.target]
                        if lib_mapping then
                            local float_type = core_config.fpu and "hard" or "soft"
                            local arch_dir = lib_mapping[float_type]
                            if arch_dir then
                                -- Add C++ include paths from runtime directory
                                local runtime_inc = path.join(install_dir, tc_config.lib_prefix, arch_dir, "include")
                                if os.isdir(runtime_inc) then
                                    -- Add C++ include directory FIRST (before C headers)
                                    local cxx_inc = path.join(runtime_inc, "c++", "v1")
                                    if os.isdir(cxx_inc) then
                                        target:add("includedirs", cxx_inc, {public = true})
                                    end
                                    
                                    -- Add clang's built-in include directory
                                    local clang_inc = path.join(install_dir, "lib", "clang", "19", "include")
                                    if os.isdir(clang_inc) then
                                        target:add("includedirs", clang_inc, {public = true})
                                    end
                                    
                                    -- Add base C include directory LAST
                                    target:add("includedirs", runtime_inc, {public = true})
                                end
                            end
                        end
                    end
                end
            end
        elseif toolchain == "gcc-arm" then
            -- Add GCC include paths
            local gcc_package = toolchain_data.PACKAGE_PATHS["gcc-arm"]
            local gcc_path = path.join(global.directory(), gcc_package.base_path)
            if os.isdir(gcc_path) then
                local versions = os.dirs(path.join(gcc_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest = versions[#versions]
                    local installs = os.dirs(path.join(latest, "*"))
                    if #installs > 0 then
                        local install_dir = installs[1]
                        -- Find GCC version directory
                        local gcc_version_dir = nil
                        local gcc_inc_base = path.join(install_dir, "arm-none-eabi", "include", "c++")
                        if os.isdir(gcc_inc_base) then
                            local gcc_versions = os.dirs(path.join(gcc_inc_base, "*"))
                            if #gcc_versions > 0 then
                                gcc_version_dir = path.basename(gcc_versions[1])
                            end
                        end
                        
                        if gcc_version_dir then
                            -- Add C++ include paths
                            local cxx_inc = path.join(install_dir, "arm-none-eabi", "include", "c++", gcc_version_dir)
                            if os.isdir(cxx_inc) then
                                target:add("includedirs", cxx_inc, {public = true})
                            end
                            -- Add target-specific C++ include path
                            local target_cxx_inc = path.join(cxx_inc, "arm-none-eabi")
                            if os.isdir(target_cxx_inc) then
                                target:add("includedirs", target_cxx_inc, {public = true})
                            end
                        end
                        
                        -- Add standard C include paths
                        local c_inc = path.join(install_dir, "arm-none-eabi", "include")
                        if os.isdir(c_inc) then
                            target:add("includedirs", c_inc, {public = true})
                        end
                    end
                end
            end
        end
        
        -- Add LLVM-specific library path
        if toolchain == "clang-arm" then
            
            -- Add LLVM library path based on target
            local llvm_package = toolchain_data.PACKAGE_PATHS["clang-arm"]
            local llvm_path = path.join(global.directory(), llvm_package.base_path)
            if os.isdir(llvm_path) then
                local versions = os.dirs(path.join(llvm_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest = versions[#versions]
                    local installs = os.dirs(path.join(latest, "*"))
                    if #installs > 0 then
                        local install_dir = installs[1]
                        -- Get library directory from mapping
                        local lib_mapping = tc_config.lib_mapping[core_config.target]
                        if lib_mapping then
                            local float_type = core_config.fpu and "hard" or "soft"
                            local arch_dir = lib_mapping[float_type]
                            if arch_dir then
                                local lib_path = path.join(install_dir, tc_config.lib_prefix, arch_dir, "lib")
                                if os.isdir(lib_path) then
                                    target:add("ldflags", "-L" .. lib_path, {force = true})
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Define MCU macro
        target:add("defines", "MCU_" .. mcu:upper())
        
        -- Apply linker script
        local linker_script = target:values("embedded.linker_script")
        if not linker_script then
            -- Use common linker script from rule directory
            local rule_dir = os.scriptdir()
            local common_script = toolchain_data.LINKER_SCRIPTS.common_script
            linker_script = path.join(rule_dir, "linker", common_script)
            if os.isfile(linker_script) then
                target:add("ldflags", "-T" .. linker_script, {force = true})
                -- Store for display
                target:data_set("embedded.linker_script_path", linker_script)
                target:data_set("embedded.memory_info", {
                    flash = mcu_config.flash,
                    flash_origin = mcu_config.flash_origin,
                    ram = mcu_config.ram,
                    ram_origin = mcu_config.ram_origin
                })
                
                -- Set memory symbols
                local symbols = toolchain_data.MEMORY_SYMBOLS
                local flash_bytes = size_to_bytes(mcu_config.flash)
                local ram_bytes = size_to_bytes(mcu_config.ram)
                target:add("ldflags", "-Wl,--defsym," .. symbols.flash_size .. "=" .. flash_bytes, {force = true})
                target:add("ldflags", "-Wl,--defsym," .. symbols.ram_size .. "=" .. ram_bytes, {force = true})
                target:add("ldflags", "-Wl,--defsym," .. symbols.flash_origin .. "=" .. mcu_config.flash_origin, {force = true})
                target:add("ldflags", "-Wl,--defsym," .. symbols.ram_origin .. "=" .. mcu_config.ram_origin, {force = true})
                
                -- Generate map file for common script
                local mode = build_type or "release"
                local map_path = path.join(".build", target:name(), mode, target:name() .. ".map")
                target:add("ldflags", "-Wl,-Map=" .. map_path, {force = true})
            end
        else
            target:add("ldflags", "-T" .. linker_script, {force = true})
            -- Store for display
            target:data_set("embedded.linker_script_path", linker_script)
            
            -- Generate map file for custom script
            local mode = build_type or "release"
            local map_path = path.join(".build", target:name(), mode, target:name() .. ".map")
            target:add("ldflags", "-Wl,-Map=" .. map_path, {force = true})
        end
        
        -- Store MCU for flash task
        target:data_set("embedded.mcu", mcu)
        
        -- Store final linker script path for display
        local final_linker_script = nil
        local ldflags = target:get("ldflags") or {}
        for _, flag in ipairs(ldflags) do
            if type(flag) == "string" and flag:sub(1, 2) == "-T" then
                final_linker_script = flag:sub(3)
                break
            end
        end
        if final_linker_script then
            target:data_set("embedded.final_linker_script", final_linker_script)
        end
        
        -- Apply semihosting if enabled (for debugging)
        if optimize == "debug" and target:values("embedded.semihosting") and #target:values("embedded.semihosting") > 0 then
            local semihosting_flags = cortex_data.semihosting[toolchain].enable
            for _, flag in ipairs(semihosting_flags) do
                target:add("ldflags", flag, {force = true})
            end
        end
    end)

    -- Hook that runs after on_load to display configuration
    after_load(function(target)
        -- Store configuration for display
        local mcu_name = target:values("embedded.mcu") and target:values("embedded.mcu")[1] or "unknown"
        if mcu_name ~= "unknown" then
            local rule_dir = os.scriptdir()
            local mcu_data_file = path.join(rule_dir, "database", "mcu-database.json")
            local mcu_data = json.loadfile(mcu_data_file)
            if mcu_data and mcu_data.mcus and mcu_data.mcus[mcu_name] then
                local mcu_config = mcu_data.mcus[mcu_name]
                target:data_set("embedded.display_memory_info", {
                    flash = mcu_config.flash,
                    flash_origin = mcu_config.flash_origin,
                    ram = mcu_config.ram,
                    ram_origin = mcu_config.ram_origin
                })
            end
        end
    end)
    
    -- Custom build progress display for ARM embedded
    before_build(function(target)
        -- Load defaults from database
        import("core.base.json")
        import("lib.detect.find_tool")
        local rule_dir = os.scriptdir()
        local database_dir = path.join(rule_dir, "database")
        local build_data = json.loadfile(path.join(database_dir, "build-options.json"))
        
        -- Override progress display for embedded targets
        local build_type = is_mode("debug") and "debug" or "release"
        target:data_set("embedded.display_mode", build_type)
        
        -- Get current settings
        local toolchain = target:values("embedded.toolchain") or build_data.DEFAULTS.toolchain
        local optimize = target:values("embedded.optimize") or build_data.DEFAULTS.optimization
        local debug_level = target:values("embedded.debug_level") or build_data.DEFAULTS.debug_level
        local lto = target:values("embedded.lto") or build_data.DEFAULTS.lto
        local c_standard = target:values("embedded.c_standard") or build_data.DEFAULTS.c_standard
        local cxx_standard = target:values("embedded.cxx_standard") or build_data.DEFAULTS.cxx_standard
        local outputs = target:values("embedded.outputs") or {"elf", "hex", "bin", "map"}
        
        -- Get toolchain version info
        local toolchain_display = toolchain
        if toolchain == "gcc-arm" then
            -- Use xmake package directory for gcc-arm
            import("core.base.global")
            local gcc_path = path.join(global.directory(), "packages/g/gcc-arm")
            if os.isdir(gcc_path) then
                local versions = os.dirs(path.join(gcc_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    -- os.dirs returns full paths, so extract just the version directory name
                    local version_dir = versions[#versions]
                    local version = path.filename(version_dir)
                    
                    -- Map known versions to actual version numbers
                    local version_to_actual = {
                        ["2024.12"] = "14.2.Rel1",
                        ["2025.02"] = "14.3.Rel1"
                    }
                    
                    if version_to_actual[version] then
                        toolchain_display = string.format("%s (Arm GNU Toolchain %s)", toolchain, version_to_actual[version])
                    else
                        toolchain_display = string.format("%s (Arm GNU Toolchain Version %s)", toolchain, version)
                    end
                end
            else
                -- Fallback to find_tool if package not found
                local gcc_tool = find_tool("arm-none-eabi-gcc")
                if gcc_tool and gcc_tool.program then
                    local result = os.iorunv(gcc_tool.program, {"--version"})
                    if result then
                        local version = result:match("%((.-)%)")
                        if version then
                            toolchain_display = string.format("%s (%s)", toolchain, version)
                        end
                    end
                end
            end
        elseif toolchain == "clang-arm" then
            import("core.base.global")
            local clang_path = path.join(global.directory(), "packages/c/clang-arm")
            if os.isdir(clang_path) then
                local versions = os.dirs(path.join(clang_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    -- os.dirs returns full paths, so extract just the version directory name
                    local version_dir = versions[#versions]
                    local version = path.filename(version_dir)
                    -- Use full version directly (e.g., "19.1.5")
                    toolchain_display = string.format("%s (Arm Toolchain for Embedded %s)", toolchain, version)
                end
            end
        end
        
        -- Check if values are defaults
        local function format_value(value, default_value)
            if value == default_value then
                return value .. " (default)"
            else
                return value
            end
        end
        
        -- Format with actual flags
        local function format_with_flags(value, default_value, flag_map)
            local flags = flag_map[value]
            local flag_str = ""
            if flags then
                if type(flags) == "table" then
                    flag_str = " [" .. table.concat(flags, " ") .. "]"
                else
                    flag_str = " [" .. flags .. "]"
                end
            end
            
            if value == default_value then
                return value .. flag_str .. " (default)"
            else
                return value .. flag_str
            end
        end
        
        -- Format outputs list
        local outputs_str = table.concat(outputs, ", ")
        if #outputs == 4 and outputs[1] == "elf" and outputs[2] == "hex" and outputs[3] == "bin" and outputs[4] == "map" then
            outputs_str = outputs_str .. " (default)"
        end
        
        -- Get linker script path and MEMORY information from stored data
        local linker_script_display = ""
        local memory_display = ""
        
        -- Try to get stored linker script path
        local stored_linker_path = target:data("embedded.final_linker_script") or target:data("embedded.linker_script_path")
        if stored_linker_path then
            linker_script_display = stored_linker_path
        else
            -- Fall back to checking embedded.linker_script value
            local custom_linker_script = target:values("embedded.linker_script")
            if custom_linker_script and #custom_linker_script > 0 then
                linker_script_display = custom_linker_script[1]
            else
                linker_script_display = "default (will be generated)"
            end
        end
        
        -- Try to get stored memory info
        local stored_memory_info = target:data("embedded.memory_info") or target:data("embedded.display_memory_info")
        if stored_memory_info then
            memory_display = string.format("FLASH: %s @ 0x%08X, RAM: %s @ 0x%08X", 
                stored_memory_info.flash, stored_memory_info.flash_origin,
                stored_memory_info.ram, stored_memory_info.ram_origin)
        else
            -- Fall back to loading from MCU database
            if mcu_name ~= "unknown" then
                local mcu_data_file = path.join(rule_dir, "database", "mcu-database.json")
                local mcu_data = json.loadfile(mcu_data_file)
                if mcu_data and mcu_data.mcus and mcu_data.mcus[mcu_name] then
                    local mcu_config = mcu_data.mcus[mcu_name]
                    memory_display = string.format("FLASH: %s @ 0x%08X, RAM: %s @ 0x%08X", 
                        mcu_config.flash, mcu_config.flash_origin,
                        mcu_config.ram, mcu_config.ram_origin)
                end
            end
        end
        
        -- Buffer output to prevent interleaving in parallel builds
        local output_lines = {}
        table.insert(output_lines, "================================================================================")
        table.insert(output_lines, "ARM Embedded Build Configuration")
        table.insert(output_lines, "================================================================================")
        table.insert(output_lines, string.format("Target:         %s", target:name()))
        local mcu_name = target:values("embedded.mcu") and target:values("embedded.mcu")[1] or "unknown"
        table.insert(output_lines, string.format("MCU:            %s", mcu_name))
        table.insert(output_lines, string.format("Toolchain:      %s", toolchain_display))
        table.insert(output_lines, string.format("Build type:     %s", build_type))
        table.insert(output_lines, string.format("Optimization:   %s", format_with_flags(optimize, build_data.DEFAULTS.optimization, build_data.OPTIMIZATION_LEVELS)))
        table.insert(output_lines, string.format("Debug level:    %s", format_with_flags(debug_level, build_data.DEFAULTS.debug_level, build_data.DEBUG_INFO_LEVELS)))
        table.insert(output_lines, string.format("LTO:            %s", format_with_flags(lto, build_data.DEFAULTS.lto, build_data.LTO_OPTIONS)))
        table.insert(output_lines, string.format("C standard:     %s", format_with_flags(c_standard, build_data.DEFAULTS.c_standard, build_data.C_STANDARDS)))
        table.insert(output_lines, string.format("C++ standard:   %s", format_with_flags(cxx_standard, build_data.DEFAULTS.cxx_standard, build_data.CXX_STANDARDS)))
        table.insert(output_lines, string.format("Output formats: %s", outputs_str))
        if linker_script_display ~= "" then
            table.insert(output_lines, string.format("Linker script:  %s", linker_script_display))
        end
        if memory_display ~= "" then
            table.insert(output_lines, string.format("Memory layout:  %s", memory_display))
        end
        table.insert(output_lines, "================================================================================")
        
        -- Print all at once
        for _, line in ipairs(output_lines) do
            print(line)
        end
    end)
    
    -- Generate additional output formats and display memory usage after linking
    after_link(function(target)
        local targetfile = target:targetfile()
        if not targetfile or not os.isfile(targetfile) then
            return
        end
        
        -- Generate additional output formats
        local toolchain = target:values("embedded.toolchain") or "gcc-arm"
        local targetdir = path.directory(targetfile)
        local basename = path.basename(targetfile)
        
        -- Get output formats from target values or use defaults
        local output_formats = target:values("embedded.outputs") or {"elf", "hex", "bin", "map"}
        
        -- Find objcopy tool
        local objcopy_cmd = nil
        if toolchain == "clang-arm" then
            -- Use llvm-objcopy
            import("core.base.global")
            local llvm_path = path.join(global.directory(), "packages/c/clang-arm")
            if os.isdir(llvm_path) then
                local versions = os.dirs(path.join(llvm_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest = versions[#versions]
                    local installs = os.dirs(path.join(latest, "*"))
                    if #installs > 0 then
                        local install_dir = installs[1]
                        objcopy_cmd = path.join(install_dir, "bin", "llvm-objcopy")
                    end
                end
            end
        else
            -- Use arm-none-eabi-objcopy
            import("lib.detect.find_tool")
            local gcc_objcopy = find_tool("arm-none-eabi-objcopy")
            if gcc_objcopy then
                objcopy_cmd = gcc_objcopy.program
            end
        end
        
        -- Generate each requested format
        if objcopy_cmd and os.isfile(objcopy_cmd) then
            -- Use ELF file as source for objcopy operations
            local elf_file = path.join(targetdir, basename .. ".elf")
            local objcopy_source = os.isfile(elf_file) and elf_file or targetfile
            
            for _, format in ipairs(output_formats) do
                if format == "elf" then
                    -- Ensure ELF file exists
                    if targetfile ~= elf_file then
                        os.cp(targetfile, elf_file)
                    end
                elseif format == "hex" then
                    -- Generate Intel HEX file
                    local hex_file = path.join(targetdir, basename .. ".hex")
                    os.runv(objcopy_cmd, {"-O", "ihex", objcopy_source, hex_file})
                elseif format == "bin" then
                    -- Generate binary file
                    local bin_file = path.join(targetdir, basename .. ".bin")
                    os.runv(objcopy_cmd, {"-O", "binary", objcopy_source, bin_file})
                end
                -- Note: map file is already generated during linking
            end
        end
        
        -- Get MCU configuration for memory limits
        import("core.base.json")
        local rule_dir = os.scriptdir()
        local database_dir = path.join(rule_dir, "database")
        local mcu_data = json.loadfile(path.join(database_dir, "mcu-database.json"))
        
        local mcu = target:values("embedded.mcu")
        local mcu_config = nil
        if mcu and mcu_data then
            mcu_config = mcu_data.CONFIGS[mcu:lower()]
        end
        
        -- Run size command to get memory usage
        -- Load build data to get defaults
        import("core.base.json")
        local rule_dir = os.scriptdir()
        local database_dir = path.join(rule_dir, "database")
        local build_data = json.loadfile(path.join(database_dir, "build-options.json"))
        
        local toolchain = target:values("embedded.toolchain") or build_data.DEFAULTS.toolchain
        local size_cmd = nil
        
        if toolchain == "clang-arm" then
            -- Use llvm-size
            import("core.base.global")
            local llvm_path = path.join(global.directory(), "packages/c/clang-arm")
            if os.isdir(llvm_path) then
                local versions = os.dirs(path.join(llvm_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest = versions[#versions]
                    local installs = os.dirs(path.join(latest, "*"))
                    if #installs > 0 then
                        local install_dir = installs[1]
                        size_cmd = path.join(install_dir, "bin", "llvm-size")
                    end
                end
            end
        else
            -- Use arm-none-eabi-size
            import("lib.detect.find_tool")
            local gcc_size = find_tool("arm-none-eabi-size")
            if gcc_size then
                size_cmd = gcc_size.program
            end
        end
        
        if size_cmd and os.isfile(size_cmd) then
            -- Buffer all output to prevent interleaving in parallel builds
            local output_lines = {}
            table.insert(output_lines, "================================================================================")
            table.insert(output_lines, string.format("Memory Usage Summary for %s", target:name()))
            
            -- Add linker script info
            local linker_script = nil
            local ldflags = target:get("ldflags") or {}
            for _, flag in ipairs(ldflags) do
                if type(flag) == "string" and flag:sub(1, 2) == "-T" then
                    linker_script = flag:sub(3)
                    break
                end
            end
            if linker_script then
                table.insert(output_lines, string.format("Linker script:  %s", linker_script))
            end
            
            -- Add memory layout info from stored data
            local stored_memory_info = target:data("embedded.memory_info") or target:data("embedded.display_memory_info")
            if stored_memory_info then
                table.insert(output_lines, string.format("Memory layout:  FLASH: %s @ 0x%08X, RAM: %s @ 0x%08X", 
                    stored_memory_info.flash, stored_memory_info.flash_origin,
                    stored_memory_info.ram, stored_memory_info.ram_origin))
            end
            
            table.insert(output_lines, "================================================================================")
            
            -- Run size command with Berkeley format on ELF file
            local elf_file = path.join(path.directory(targetfile), path.basename(targetfile) .. ".elf")
            local size_target = os.isfile(elf_file) and elf_file or targetfile
            local output = os.iorunv(size_cmd, {"-B", size_target})
            if output then
                -- Parse Berkeley format output
                local text, data, bss = 0, 0, 0
                for line in output:gmatch("[^\r\n]+") do
                    local t, d, b = line:match("^%s*(%d+)%s+(%d+)%s+(%d+)")
                    if t then
                        text = tonumber(t)
                        data = tonumber(d)
                        bss = tonumber(b)
                        break
                    end
                end
                
                local flash_used = text + data
                local ram_used = data + bss
                
                -- If we have MCU config, show percentage
                if mcu_config then
                    -- Convert memory sizes to bytes
                    local flash_size = 0
                    local ram_size = 0
                    
                    local function size_to_bytes(size_str)
                        local num, unit = size_str:match("(%d+)([KM]?)")
                        num = tonumber(num)
                        if unit == "K" then
                            return num * 1024
                        elseif unit == "M" then
                            return num * 1024 * 1024
                        else
                            return num
                        end
                    end
                    
                    flash_size = size_to_bytes(mcu_config.flash)
                    ram_size = size_to_bytes(mcu_config.ram)
                    
                    local flash_percent = (flash_used * 100) / flash_size
                    local ram_percent = (ram_used * 100) / ram_size
                    
                    -- Display usage in one line each with percentage
                    table.insert(output_lines, string.format("Flash: %d / %d bytes (%.1f%%)", flash_used, flash_size, flash_percent))
                    table.insert(output_lines, string.format("RAM:   %d / %d bytes (%.1f%%) [data: %d, bss: %d]", ram_used, ram_size, ram_percent, data, bss))
                    
                    -- Warnings
                    if flash_percent > 90 then
                        table.insert(output_lines, "${yellow}warning: Flash usage is over 90%%!")
                    end
                    if ram_percent > 90 then
                        table.insert(output_lines, "${yellow}warning: RAM usage is over 90%%!")
                    end
                else
                    -- Fallback without MCU config
                    table.insert(output_lines, string.format("Flash: %d bytes", flash_used))
                    table.insert(output_lines, string.format("RAM:   %d bytes [data: %d, bss: %d]", ram_used, data, bss))
                end
            end
            
            table.insert(output_lines, "================================================================================")
            
            -- Print all at once to avoid interleaving
            -- Use io.write to ensure atomic output
            local full_output = table.concat(output_lines, "\n") .. "\n"
            -- Replace color codes for warnings
            if full_output:find("${yellow}") then
                -- Split and handle colored lines separately
                for _, line in ipairs(output_lines) do
                    if line:find("${yellow}") then
                        cprint(line)
                    else
                        print(line)
                    end
                end
            else
                -- No colors, print all at once
                io.write(full_output)
                io.flush()
            end
        end
    end)

