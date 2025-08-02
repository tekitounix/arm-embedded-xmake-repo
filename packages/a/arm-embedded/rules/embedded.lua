-- ARM Cortex-M Embedded Build Rules

-- LLVM library path prefix
local LLVM_LIB_PREFIX = "lib/clang-runtimes/arm-none-eabi/"

-- Cortex-M Architecture definitions
local CORTEX_M_CORES = {
    ["cortex-m0"] = {
        arch = "armv6-m",
        gcc  = { mcpu = "cortex-m0", mfloat_abi = "soft" },
        llvm = { target = "armv6m-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true },
        lib  = "armv6m_soft/lib"
    },
    ["cortex-m0plus"] = {
        arch = "armv6-m",
        gcc  = { mcpu = "cortex-m0plus", mfloat_abi = "soft" },
        llvm = { target = "armv6m-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true },
        lib  = "armv6m_soft/lib"
    },
    ["cortex-m1"] = {
        arch = "armv6-m",
        gcc  = { mcpu = "cortex-m1", mfloat_abi = "soft" },
        llvm = { target = "armv6m-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true },
        lib  = "armv6m_soft/lib"
    },
    ["cortex-m3"] = {
        arch = "armv7-m",
        gcc  = { mcpu = "cortex-m3", mfloat_abi = "soft" },
        llvm = { target = "armv7m-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true, dsp = false },
        lib  = "armv7m_soft/lib"
    },
    ["cortex-m4"] = {
        arch = "armv7e-m",
        gcc  = { mcpu = "cortex-m4", mfloat_abi = "soft" },
        llvm = { target = "armv7em-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true, dsp = true },
        lib  = "armv7em_soft/lib"
    },
    ["cortex_m4f"] = {
        arch = "armv7e-m",
        gcc  = { mcpu = "cortex-m4", mfpu = "fpv4-sp-d16", mfloat_abi = "hard" },
        llvm = { target = "armv7em-none-eabi", mfpu = "fpv4-sp-d16", mfloat_abi = "hard" },
        features = { thumb = true, dsp = true, fpu = "fpv4-sp-d16" },
        lib  = "armv7em_hard_fpv4_sp_d16/lib"
    },
    ["cortex-m7"] = {
        arch = "armv7e-m",
        gcc  = { mcpu = "cortex-m7", mfloat_abi = "soft" },
        llvm = { target = "armv7em-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true, dsp = true, cache = true },
        lib  = "armv7em_soft/lib"
    },
    ["cortex-m7f"] = {
        arch = "armv7e-m",
        gcc  = { mcpu = "cortex-m7", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        llvm = { target = "armv7em-none-eabi", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        features = { thumb = true, dsp = true, cache = true, fpu = "fpv5-sp-d16" },
        lib  = "armv7em_hard_fpv5_sp_d16/lib"
    },
    ["cortex-m7df"] = {
        arch = "armv7e-m",
        gcc  = { mcpu = "cortex-m7", mfpu = "fpv5-d16", mfloat_abi = "hard" },
        llvm = { target = "armv7em-none-eabi", mfpu = "fpv5-d16", mfloat_abi = "hard" },
        features = { thumb = true, dsp = true, cache = true, fpu = "fpv5-d16" },
        lib  = "armv7em_hard_fpv5_d16/lib"
    },
    ["cortex-m23"] = {
        arch = "armv8-m.base",
        gcc  = { mcpu = "cortex-m23", mfloat_abi = "soft" },
        llvm = { target = "armv8m.base-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true, trustzone = true },
        lib  = "armv8m_base_soft/lib"
    },
    ["cortex-m33"] = {
        arch = "armv8-m.main",
        gcc  = { mcpu = "cortex-m33", mfloat_abi = "soft" },
        llvm = { target = "armv8m.main-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true, dsp = true, trustzone = true },
        lib  = "armv8m_main_soft/lib"
    },
    ["cortex-m33f"] = {
        arch = "armv8-m.main",
        gcc  = { mcpu = "cortex-m33", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        llvm = { target = "armv8m.main-none-eabi", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        features = { thumb = true, dsp = true, trustzone = true, fpu = "fpv5-sp-d16" },
        lib  = "armv8m_main_hard_fpv5_sp_d16/lib"
    },
    ["cortex-m35p"] = {
        arch = "armv8-m.main",
        gcc  = { mcpu = "cortex-m35p", mfloat_abi = "soft" },
        llvm = { target = "armv8m.main-none-eabi", mfloat_abi = "soft" },
        features = { thumb = true, dsp = true, trustzone = true, physical_security = true },
        lib  = "armv8m_main_soft/lib"
    },
    ["cortex-m35pf"] = {
        arch = "armv8-m.main",
        gcc  = { mcpu = "cortex-m35p", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        llvm = { target = "armv8m.main-none-eabi", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        features = { thumb = true, dsp = true, trustzone = true, physical_security = true, fpu = "fpv5-sp-d16" },
        lib  = "armv8m_main_hard_fpv5_sp_d16/lib"
    },
    ["cortex-m55"] = {
        arch = "armv8.1-m.main",
        gcc  = { mcpu = "cortex-m55", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        llvm = { target = "armv8.1m.main-none-eabi", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        features = { thumb = true, dsp = true, mve = true, trustzone = true, fpu = "fpv5-sp-d16" },
        lib  = "armv8_1m_main_hard_fpv5_sp_d16/lib"
    },
    ["cortex-m85"] = {
        arch = "armv8.1-m.main",
        gcc  = { mcpu = "cortex-m85", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        llvm = { target = "armv8.1m.main-none-eabi", mfpu = "fpv5-sp-d16", mfloat_abi = "hard" },
        features = { thumb = true, dsp = true, mve = true, trustzone = true, helium = true, fpu = "fpv5-sp-d16" },
        lib  = "armv8_1m_main_hard_fpv5_sp_d16/lib"
    }
}

-- Helper function to get template path
local function get_template_path(filename)
    return path.join(os.projectdir(), "tools", "templates", filename)
end

-- Helper function to generate default files in target directory
local function generate_default_files(target)
    local target_dir = target:targetdir()
    local generated = false
    
    -- Check if user wants to generate default files
    if target:extraconf("rules", "embedded", "generate_defaults") then
        -- Copy default linker script if not exists
        local linker_script = path.join(target_dir, "default_cortex_m.ld")
        if not os.isfile(linker_script) then
            os.cp(get_template_path("cortex_m_default.ld"), linker_script)
            print("Generated default linker script: " .. linker_script)
            generated = true
        end
        
        -- Copy default startup if not exists
        local startup_file = path.join(target_dir, "default_startup.cc")
        if not os.isfile(startup_file) then
            os.cp(get_template_path("cortex_m_startup.cc"), startup_file)
            print("Generated default startup file: " .. startup_file)
            generated = true
        end
    end
    
    return generated
end

-- Get compiler flags for specific architecture
local function get_core_flags(core_name, compiler)
    local core = CORTEX_M_CORES[core_name]
    if not core then
        return nil
    end
    
    local flags = {}
    local cfg = core[compiler] or {}
    
    -- Convert configuration to flags
    for key, value in pairs(cfg) do
        if key == "target" then
            -- Skip target for GCC, use it for LLVM
            if compiler == "llvm" then
                table.insert(flags, "--target=" .. value)
            end
        elseif key == "march" then
            table.insert(flags, "-march=" .. value)
        elseif key == "mcpu" then
            table.insert(flags, "-mcpu=" .. value)
        elseif key == "mfpu" then
            table.insert(flags, "-mfpu=" .. value)
        elseif key == "mfloat_abi" then
            table.insert(flags, "-mfloat-abi=" .. value)
        end
    end
    
    -- Add architecture-specific flags
    if core.features and core.features.thumb then
        table.insert(flags, "-mthumb")
    end
    
    return flags
end

-- Apply architecture core settings directly to target
local function apply_core_settings(target, core_type, is_llvm, toolchains)
    if not core_type then return end
    
    -- Get architecture-specific flags
    local compiler = is_llvm and "llvm" or "gcc"
    local flags = get_core_flags(core_type, compiler)
    
    if not flags then
        print("Error: Unknown core: " .. tostring(core_type))
        return
    end
    
    -- Apply flags to target
    for _, flag in ipairs(flags) do
        target:add("cxflags", flag, {force = true})
        -- Also add to ldflags for --target flag or floating point flags
        if flag:startswith("--target=") or flag:startswith("-mfloat-abi=") or flag:startswith("-mfpu=") or flag:startswith("-mcpu=") or flag == "-mthumb" then
            target:add("ldflags", flag, {force = true})
        end
    end
    
    -- Add library path for LLVM
    if is_llvm then
        local core = CORTEX_M_CORES[core_type]
        if core and core.lib then
            local toolchain = target:toolchain(toolchains[1])
            if toolchain then
                target:add("ldflags", "-L" .. path.join(toolchain:installdir(), LLVM_LIB_PREFIX .. core.lib), {force = true})
            end
        end
    end
end

-- Apply toolchain-specific flags
local function apply_toolchain_flags(target, is_llvm, core_type)
    if is_llvm then
        target:add("ldflags", "-nostdlib", "-fuse-ld=lld", "-lc", "-lm", "-ldummyhost", "-lclang_rt.builtins", {force = true})
    else
        -- GCC: Use newlib-nano with custom startup
        target:add("ldflags", "--specs=nano.specs", "--specs=nosys.specs", "-nostartfiles", {force = true})
        -- Add map file for debugging
        target:add("ldflags", "-Wl,-Map=output.map", {force = true})
        if target:extraconf("rules", "embedded", "printf_float") then
            target:add("ldflags", "-u_printf_float", {force = true})
        end
    end
end

-- Apply memory layout settings
local function apply_memory_layout(target, is_llvm, mcu_configs)
    local custom_linker = target:extraconf("rules", "embedded", "linker_script")
    local use_default_linker = target:extraconf("rules", "embedded", "use_default_linker")
    local target_mcu = target:extraconf("rules", "embedded", "mcu")
    
    -- Note: xmake automatically handles .ld files added via add_files()
    -- So we don't need to manually add them here
    
    -- If using default linker from package, skip this function
    if use_default_linker == true then
        return
    end
    
    -- Get linker directory
    local project_dir = os.scriptdir()
    local arm_embedded_dir = path.join(project_dir, ".ref", "arm-embedded-xmake-repo", "packages", "a", "arm-embedded")
    local linker_dir = path.join(arm_embedded_dir, "linker")
    
    if custom_linker then
        -- Use user-specified linker script
        target:add("ldflags", "-T" .. custom_linker, {force = true})
    elseif use_default_linker ~= false then  -- Default to true if not specified
        -- If MCU is specified, use common.ld; otherwise use fallback behavior
        if target_mcu and mcu_configs[target_mcu] then
            local common_linker = path.join(linker_dir, "common.ld")
            if os.isfile(common_linker) then
                target:add("ldflags", "-T" .. common_linker, {force = true})
                
                -- Apply memory configuration via linker symbols
                local config = mcu_configs[target_mcu]
                target:add("ldflags", "-Wl,--defsym,__flash_size=" .. config.flash_size, {force = true})
                target:add("ldflags", "-Wl,--defsym,__ram_size=" .. config.ram_size, {force = true})
                target:add("ldflags", "-Wl,--defsym,__flash_origin=" .. config.flash_origin, {force = true})
                target:add("ldflags", "-Wl,--defsym,__ram_origin=" .. config.ram_origin, {force = true})
                
                print("Using common linker script with " .. target_mcu .. " memory configuration (via default)")
            else
                print("Warning: Common linker script not found: " .. common_linker)
            end
        else
            -- Use default Cortex-M linker script from templates (old behavior)
            local default_ld = get_template_path("cortex_m_default.ld")
            target:add("ldflags", "-T" .. default_ld, {force = true})
        end
        
        -- Add memory configuration via linker flags if specified
        local flash_size = target:extraconf("rules", "embedded", "flash_size")
        local ram_size = target:extraconf("rules", "embedded", "ram_size")
        local flash_origin = target:extraconf("rules", "embedded", "flash_origin")
        local ram_origin = target:extraconf("rules", "embedded", "ram_origin")
        
        if flash_size then
            target:add("ldflags", "-Wl,--defsym,__flash_size=" .. flash_size, {force = true})
        end
        if ram_size then
            target:add("ldflags", "-Wl,--defsym,__ram_size=" .. ram_size, {force = true})
        end
        if flash_origin then
            target:add("ldflags", "-Wl,--defsym,__flash_origin=" .. flash_origin, {force = true})
        end
        if ram_origin then
            target:add("ldflags", "-Wl,--defsym,__ram_origin=" .. ram_origin, {force = true})
        end
    end
end

-- Apply startup configuration
local function apply_startup_config(target, is_llvm)
    local custom_startup = target:extraconf("rules", "embedded", "startup_file")
    local use_default_startup = target:extraconf("rules", "embedded", "use_default_startup")
    
    if not custom_startup and use_default_startup ~= false then
        -- Add default startup file from templates
        target:add("files", get_template_path("cortex_m_startup.cc"))
    elseif custom_startup then
        target:add("files", custom_startup)
    end
end

-- Apply debug/release optimization settings
local function apply_optimization(target, is_debug, is_llvm)
    if is_debug then
        target:add("cxflags", "-Og", "-ggdb3")
        if target:extraconf("rules", "embedded", "semihost") then
            local semihost_flag = is_llvm and "-lcrt0-semihost" or "--specs=rdimon.specs"
            target:add("ldflags", semihost_flag, {force = true})
        end
    else
        target:add("cxflags", "-fno-unwind-tables", "-fno-omit-frame-pointer")
        
        local opt_map = {
            size = {"-Os"},
            speed = {"-O3"},
            fast = {"-O3", "-ffast-math"},
            balanced = {"-O2"}  -- default
        }
        
        local opt_level = target:extraconf("rules", "embedded", "optimize") or "balanced"
        local flags = opt_map[opt_level] or opt_map.balanced
        
        target:add("cxflags", table.unpack(flags))
    end
end


rule("embedded")
    -- パッケージルールではon_configのみ使用可能
    
    on_config(function(target)
        print("🔧 ARM Embedded on_config called for target: " .. target:name())
        
        -- gcc-armパッケージからツールセットを設定
        import("core.base.global")
        local packages_path = path.join(global.directory(), "packages", "g", "gcc-arm")
        local bindir = nil
        
        if os.isdir(packages_path) then
            local versions = os.dirs(path.join(packages_path, "*"))
            if #versions > 0 then
                table.sort(versions)
                local latest_version = versions[#versions]
                local installs = os.dirs(path.join(latest_version, "*"))
                if #installs > 0 then
                    local gcc_arm_path = installs[1]
                    bindir = path.join(gcc_arm_path, "bin")
                end
            end
        end
        
        if bindir and os.isdir(bindir) then
            -- ARMツールセットを設定
            target:set("toolset", "cc", path.join(bindir, "arm-none-eabi-gcc"))
            target:set("toolset", "cxx", path.join(bindir, "arm-none-eabi-g++"))
            target:set("toolset", "ld", path.join(bindir, "arm-none-eabi-g++"))
            target:set("toolset", "ar", path.join(bindir, "arm-none-eabi-ar"))
            target:set("toolset", "as", path.join(bindir, "arm-none-eabi-as"))
            
            print("✅ Set ARM toolset from gcc-arm package")
            print("   CC: " .. path.join(bindir, "arm-none-eabi-gcc"))
        else
            print("⚠️  gcc-arm package not found")
        end
        
        -- 基本設定（プラットフォーム以外）
        target:set("kind", "binary")
        target:set("languages", "cxx23")
        target:set("default", true)
        
        -- MCU設定からリンカースクリプトを適用
        local target_mcu = target:extraconf("rules", "embedded", "mcu")
        if target_mcu then
            local mcu_configs = {
                stm32f407vg = { flash_size = "1M", ram_size = "128K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" }
            }
            
            if mcu_configs[target_mcu] then
                -- パッケージディレクトリからリンカースクリプトを取得
                import("core.base.global")
                local package_dir = path.join(global.directory(), "packages", "a", "arm-embedded")
                if os.isdir(package_dir) then
                    local versions = os.dirs(path.join(package_dir, "*"))
                    if #versions > 0 then
                        table.sort(versions)
                        local latest = versions[#versions]
                        local installs = os.dirs(path.join(latest, "*"))
                        if #installs > 0 then
                            local install_dir = installs[1]
                            local linker_script = path.join(install_dir, "linker", "common.ld")
                            if os.isfile(linker_script) then
                                target:add("ldflags", "-T" .. linker_script, {force = true})
                                
                                -- メモリ設定を適用
                                local config = mcu_configs[target_mcu]
                                target:add("ldflags", "-Wl,--defsym,__flash_size=" .. config.flash_size, {force = true})
                                target:add("ldflags", "-Wl,--defsym,__ram_size=" .. config.ram_size, {force = true})
                                target:add("ldflags", "-Wl,--defsym,__flash_origin=" .. config.flash_origin, {force = true})
                                target:add("ldflags", "-Wl,--defsym,__ram_origin=" .. config.ram_origin, {force = true})
                                
                                print("✅ Applied linker script for " .. target_mcu)
                            else
                                print("⚠️  Warning: Linker script not found: " .. linker_script)
                            end
                        end
                    end
                end
            end
        end
        
        -- MCU設定を取得
        local target_mcu = target:extraconf("rules", "embedded", "mcu")
        print("📱 MCU specified: " .. (target_mcu or "none"))
        
        if target_mcu then
            -- コンパイラフラグ設定をテスト
            target:add("cxflags", "-DMCU_" .. target_mcu:upper())
            target:add("defines", "MCU_NAME=\"" .. target_mcu .. "\"")
            print("✅ Added MCU-specific compiler flags")
        end
        
        -- ARM固有フラグ設定をテスト  
        target:add("cxflags", "-mcpu=cortex-m4", "-mthumb")
        target:add("ldflags", "-mcpu=cortex-m4", "-mthumb")
        print("✅ Added ARM-specific flags")
        -- MCU configuration and auto-detection
        local rule_toolchain = target:extraconf("rules", "embedded", "toolchain")
        if rule_toolchain == "gcc" or rule_toolchain == "gnu" then
            -- Force GNU ARM toolchain
            import("core.base.global")
            local packages_path = path.join(global.directory(), "packages", "g", "gnu-rm")
            
            if os.isdir(packages_path) then
                local versions = os.dirs(path.join(packages_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest_version = versions[#versions]
                    local installs = os.dirs(path.join(latest_version, "*"))
                    if #installs > 0 then
                        local gnu_rm_path = installs[1]
                        local bindir = path.join(gnu_rm_path, "bin")
                        local gcc_path = path.join(bindir, "arm-none-eabi-gcc")
                        local gxx_path = path.join(bindir, "arm-none-eabi-g++")
                        print("DEBUG: Force setting GCC path: " .. gcc_path)
                        target:set("toolset", "cc", gcc_path)
                        target:set("toolset", "cxx", gxx_path)
                        target:set("toolset", "ld", gxx_path)
                        target:set("toolset", "ar", path.join(bindir, "arm-none-eabi-ar"))
                        target:set("toolset", "as", path.join(bindir, "arm-none-eabi-as"))
                        
                        -- Also set the toolchain for the platform
                        target:set("toolchain", "cross")
                        
                        -- Note: Cannot call target:tool() in on_load, only in on_config
                    end
                end
            end
        end
    end)
    
    after_build(function(target)
        -- Generate .bin file from ELF for flashing
        local targetfile = target:targetfile()
        local binfile = path.join(path.directory(targetfile), path.basename(targetfile) .. ".bin")
        
        -- Find objcopy tool (should be set by toolchain)
        local objcopy = "arm-none-eabi-objcopy"
        
        print("Generating binary file: " .. path.filename(binfile))
        os.execv(objcopy, {"-O", "binary", targetfile, binfile})
    end)
    
    on_config(function(target)
        -- Ensure debug/release modes are available
        target:add("rules", "mode.debug", "mode.release")
        
        -- Disable macOS-specific linker flags for embedded targets
        target:set("strip", "none")
        target:set("symbols", "debug")
        
        -- Remove macOS specific flags
        -- Note: remove API is not available, so we'll handle this differently
        
        -- Main configuration
        local toolchains = target:get("toolchains")
        local is_llvm = false
        
        -- First check if toolchain is explicitly specified in rule config
        local rule_toolchain = target:extraconf("rules", "embedded", "toolchain")
        if rule_toolchain then
            if rule_toolchain == "gcc" or rule_toolchain == "gnu" then
                is_llvm = false
            elseif rule_toolchain == "llvm" or rule_toolchain == "clang" then
                is_llvm = true
            end
        elseif toolchains then
            for _, toolchain in ipairs(toolchains) do
                if tostring(toolchain):find("llvm") then
                    is_llvm = true
                    break
                end
            end
        else
            -- No toolchains specified, check if clang is being used
            local cc = target:tool("cc")
            if cc and (cc:find("clang") or cc:find("llvm")) then
                is_llvm = true
            end
        end
        local is_gnu = not is_llvm  -- If not LLVM, assume GNU ARM toolchain
        local is_debug = is_mode("debug")
        
        -- Auto-detect core and toolchain from MCU if specified
        local target_mcu = target:extraconf("rules", "embedded", "mcu")
        local core_type = target:extraconf("rules", "embedded", "core")
        
        -- Load MCU configs early for auto-detection
        local mcu_configs = {
            -- STM32F4 series (Cortex-M4F with FPU)
            stm32f407vg = { flash_size = "1M", ram_size = "128K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" },
            stm32f407zg = { flash_size = "1M", ram_size = "192K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" },
            stm32f411re = { flash_size = "512K", ram_size = "128K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" },
            stm32f429zi = { flash_size = "2M", ram_size = "192K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" },
            
            -- STM32F1 series (Cortex-M3)
            stm32f103c8 = { flash_size = "64K", ram_size = "20K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex-m3", toolchain = "gcc" },
            stm32f103cb = { flash_size = "128K", ram_size = "20K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex-m3", toolchain = "gcc" },
            
            -- STM32F0 series (Cortex-M0)
            stm32f030r8 = { flash_size = "64K", ram_size = "8K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex-m0", toolchain = "gcc" },
            stm32f030c8 = { flash_size = "64K", ram_size = "8K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex-m0", toolchain = "gcc" },
            
            -- STM32L4 series (Cortex-M4F with FPU)
            stm32l476rg = { flash_size = "1M", ram_size = "128K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" },
            
            -- STM32H7 series (Cortex-M7F with FPU)
            stm32h743zi = { flash_size = "2M", ram_size = "1M", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m7f", toolchain = "gcc" },
            
            -- STM32G4 series (Cortex-M4F with FPU)
            stm32g474re = { flash_size = "512K", ram_size = "128K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" },
            
            -- STM32WB series (Cortex-M4F with FPU)
            stm32wb55rg = { flash_size = "1M", ram_size = "256K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m4f", toolchain = "gcc" },
            
            -- STM32U5 series (Cortex-M33F with FPU)
            stm32u575zi = { flash_size = "2M", ram_size = "786K", flash_origin = "0x08000000", ram_origin = "0x20000000", core = "cortex_m33f", toolchain = "gcc" }
        }
        
        if target_mcu and mcu_configs[target_mcu] then
            local mcu_config = mcu_configs[target_mcu]
            -- Auto-set core type if not explicitly specified
            if not core_type and mcu_config.core then
                core_type = mcu_config.core
                print("Auto-detected core: " .. core_type .. " for MCU: " .. target_mcu)
            end
            -- Auto-set toolchain if not explicitly specified via rule_toolchain
            if not rule_toolchain and mcu_config.toolchain then
                if mcu_config.toolchain == "gcc" or mcu_config.toolchain == "gnu" then
                    is_llvm = false
                elseif mcu_config.toolchain == "llvm" or mcu_config.toolchain == "clang" then
                    is_llvm = true
                end
                is_gnu = not is_llvm
            end
            -- Auto-enable default linker for MCU-based configuration
            if not target:extraconf("rules", "embedded", "use_default_linker") then
                target:set("extraconf", "rules", "embedded", "use_default_linker", true)
                print("Auto-enabled default linker for MCU: " .. target_mcu)
            end
            
            -- Auto-set PyOCD target for flashing
            target:set("pyocd_target", target_mcu)
            print("Auto-set PyOCD target: " .. target_mcu)
        end
        
        -- Configure GNU ARM toolchain if not LLVM
        if is_gnu then
            print("DEBUG: Configuring GNU ARM toolchain")
            -- Try to find gcc-arm package path directly
            import("core.base.global")
            local packages_path = path.join(global.directory(), "packages", "g", "gnu-rm")
            
            local gnu_rm_path = nil
            if os.isdir(packages_path) then
                -- Find the latest version
                local versions = os.dirs(path.join(packages_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest_version = versions[#versions]
                    local installs = os.dirs(path.join(latest_version, "*"))
                    if #installs > 0 then
                        gnu_rm_path = installs[1]
                    end
                end
            end
            if gnu_rm_path then
                local bindir = path.join(gnu_rm_path, "bin")
                print("DEBUG: Setting GCC toolset from " .. bindir)
                target:set("toolset", "cc", path.join(bindir, "arm-none-eabi-gcc"))
                target:set("toolset", "cxx", path.join(bindir, "arm-none-eabi-g++"))
                target:set("toolset", "ld", path.join(bindir, "arm-none-eabi-g++"))
                target:set("toolset", "ar", path.join(bindir, "arm-none-eabi-ar"))
                target:set("toolset", "as", path.join(bindir, "arm-none-eabi-as"))
                
                -- Add necessary include paths for GNU ARM toolchain
                local arm_include = path.join(gnu_rm_path, "arm-none-eabi", "include")
                local gcc_version = "14.2.1"  -- Get this dynamically if needed
                local gcc_include = path.join(gnu_rm_path, "lib", "gcc", "arm-none-eabi", gcc_version, "include")
                local cxx_include = path.join(gnu_rm_path, "arm-none-eabi", "include", "c++", gcc_version)
                local cxx_target_include = path.join(cxx_include, "arm-none-eabi")
                
                
                -- Add include directories with force flag to ensure they are used
                target:add("includedirs", arm_include, {force = true})
                target:add("includedirs", gcc_include, {force = true})
                target:add("includedirs", cxx_include, {force = true})
                target:add("includedirs", cxx_target_include, {force = true})
                
                -- Also add library paths - use hard float library path for cortex-m4f
                local lib_base = path.join(gnu_rm_path, "arm-none-eabi", "lib")
                if core_type == "cortex_m4f" then
                    -- For Cortex-M4F with hard float, use the thumb/v7e-m+fp/hard directory
                    local hard_float_lib = path.join(lib_base, "thumb", "v7e-m+fp", "hard")
                    if os.isdir(hard_float_lib) then
                        target:add("linkdirs", hard_float_lib, {force = true})
                    else
                        -- Fallback to base lib path
                        target:add("linkdirs", lib_base, {force = true})
                    end
                else
                    target:add("linkdirs", lib_base, {force = true})
                end
            end
        end
        
        -- Configure LLVM toolchain if needed
        if is_llvm then
            -- Get llvm-arm-embedded package
            import("core.base.global")
            local packages_path = path.join(global.directory(), "packages", "l", "llvm-arm-embedded")
            
            local llvm_path = nil
            if os.isdir(packages_path) then
                -- Find the latest version
                local versions = os.dirs(path.join(packages_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest_version = versions[#versions]
                    local installs = os.dirs(path.join(latest_version, "*"))
                    if #installs > 0 then
                        llvm_path = installs[1]
                    end
                end
            end
            
            if llvm_path then
                local bindir = path.join(llvm_path, "bin")
                target:set("toolset", "cc", path.join(bindir, "clang"))
                target:set("toolset", "cxx", path.join(bindir, "clang"))
                target:set("toolset", "ld", path.join(bindir, "clang"))
                target:set("toolset", "ar", path.join(bindir, "llvm-ar"))
                target:set("toolset", "as", path.join(bindir, "llvm-as"))
                
                -- Add include paths for LLVM
                local builtin_include = path.join(llvm_path, "lib", "clang-runtimes", "arm-none-eabi", "include")
                if os.isdir(builtin_include) then
                    target:add("includedirs", builtin_include, {force = true})
                end
            end
        end
        
        -- Common C++ flags
        target:add("cxxflags", "-fno-rtti", "-fno-use-cxa-atexit")
        target:add("cxflags", "-fno-exceptions")
        
        -- Generate default files if requested
        generate_default_files(target)
        
        -- Apply default linker script if requested
        local use_default_linker = target:extraconf("rules", "embedded", "use_default_linker")
        if use_default_linker == true then
            -- Get the arm-embedded package directory
            local project_dir = os.scriptdir()
            local arm_embedded_dir = path.join(project_dir, ".ref", "arm-embedded-xmake-repo", "packages", "a", "arm-embedded")
            
            local linker_dir = path.join(arm_embedded_dir, "linker")
            
            -- Check if user specified a specific MCU
            local target_mcu_check = target:extraconf("rules", "embedded", "mcu")
            
            if target_mcu_check and mcu_configs[target_mcu_check] then
                -- Use common linker script with MCU-specific memory configuration
                local common_linker = path.join(linker_dir, "common.ld")
                if os.isfile(common_linker) then
                    target:add("ldflags", "-T" .. common_linker, {force = true})
                    
                    -- Apply memory configuration via linker symbols
                    local config = mcu_configs[target_mcu_check]
                    target:add("ldflags", "-Wl,--defsym,__flash_size=" .. config.flash_size, {force = true})
                    target:add("ldflags", "-Wl,--defsym,__ram_size=" .. config.ram_size, {force = true})
                    target:add("ldflags", "-Wl,--defsym,__flash_origin=" .. config.flash_origin, {force = true})
                    target:add("ldflags", "-Wl,--defsym,__ram_origin=" .. config.ram_origin, {force = true})
                    
                    print("Using common linker script with " .. target_mcu_check .. " memory configuration")
                else
                    print("Warning: Common linker script not found: " .. common_linker)
                end
            else
                -- Fallback to core-specific linker scripts (existing behavior)
                local linker_map = {
                    cortex_m4f = "stm32f407vg.ld",
                    cortex_m4 = "stm32f407vg.ld",
                    cortex_m3 = "stm32f103c8.ld",
                    cortex_m0 = "stm32f030r8.ld",
                    cortex_m0plus = "stm32f030r8.ld"
                }
                
                local linker_script = linker_map[core_type] or "stm32f407vg.ld" -- Default fallback
                local linker_path = path.join(linker_dir, linker_script)
                
                if os.isfile(linker_path) then
                    target:add("ldflags", "-T" .. linker_path, {force = true})
                    print("Using default linker script: " .. linker_script)
                else
                    print("Warning: Default linker script not found: " .. linker_path)
                end
            end
        end
        
        -- Apply modular configurations
        apply_core_settings(target, core_type, is_llvm, toolchains)
        apply_toolchain_flags(target, is_llvm, core_type)
        apply_startup_config(target, is_llvm)
        apply_memory_layout(target, is_llvm, mcu_configs)
        apply_optimization(target, is_debug, is_llvm)
    end)

-- タスクはパッケージルールでは定義できない
-- flash_tasks.luaに分離済み