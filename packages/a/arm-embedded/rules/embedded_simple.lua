-- Simplified ARM Embedded Build Rule

-- MCU configurations with core type and memory layout
local MCU_CONFIGS = {
    -- STM32F4 series
    stm32f407vg = { core = "cortex-m4", fpu = "fpv4-sp-d16", flash = "1M", ram = "128K" },
    stm32f411re = { core = "cortex-m4", fpu = "fpv4-sp-d16", flash = "512K", ram = "128K" },
    stm32f429zi = { core = "cortex-m4", fpu = "fpv4-sp-d16", flash = "2M", ram = "192K" },
    
    -- STM32F1 series  
    stm32f103c8 = { core = "cortex-m3", flash = "64K", ram = "20K" },
    stm32f103rb = { core = "cortex-m3", flash = "128K", ram = "64K" },
    
    -- STM32F0 series
    stm32f030r8 = { core = "cortex-m0", flash = "64K", ram = "8K" },
    
    -- STM32L4 series
    stm32l476rg = { core = "cortex-m4", fpu = "fpv4-sp-d16", flash = "1M", ram = "128K" },
    
    -- STM32H7 series
    stm32h743zi = { core = "cortex-m7", fpu = "fpv5-d16", flash = "2M", ram = "1M" }
}

rule("embedded")
    on_load(function(target)
        -- Set target properties
        target:set("kind", "binary")
        target:set("plat", "cross")
        target:set("arch", "arm")
        target:set("strip", "none")  -- Don't strip embedded binaries
        
        -- Get MCU configuration
        local mcu = target:values("embedded.mcu")
        local toolchain = target:values("embedded.toolchain") or "gcc"
        
        if not mcu then
            raise("embedded rule requires 'mcu' configuration")
        end
        
        local config = MCU_CONFIGS[mcu]
        if not config then
            raise("Unknown MCU: " .. mcu)
        end
        
        -- Set toolchain
        if toolchain == "llvm" then
            target:set("toolchains", "llvm-arm-embedded")
        else
            target:set("toolchains", "gcc-arm")
        end
        
        -- Common flags for bare-metal
        target:add("cxflags", "-ffunction-sections", "-fdata-sections", {force = true})
        target:add("ldflags", "-Wl,--gc-sections", "-nostartfiles", "-nostdlib", {force = true})
        
        -- CPU and FPU flags
        target:add("cxflags", "-mcpu=" .. config.core, "-mthumb", {force = true})
        target:add("ldflags", "-mcpu=" .. config.core, "-mthumb", {force = true})
        
        if config.fpu then
            target:add("cxflags", "-mfpu=" .. config.fpu, "-mfloat-abi=hard", {force = true})
            target:add("ldflags", "-mfpu=" .. config.fpu, "-mfloat-abi=hard", {force = true})
        else
            target:add("cxflags", "-mfloat-abi=soft", {force = true})
            target:add("ldflags", "-mfloat-abi=soft", {force = true})
        end
        
        -- Add LLVM-specific flags
        if toolchain == "llvm" then
            local target_triple = "arm-none-eabi"
            target:add("cxflags", "--target=" .. target_triple, {force = true})
            target:add("ldflags", "--target=" .. target_triple, {force = true})
        end
        
        -- C++ flags
        target:add("cxxflags", "-fno-exceptions", "-fno-rtti", "-fno-threadsafe-statics")
        
        -- Define MCU macro
        target:add("defines", "MCU_" .. mcu:upper())
        
        -- Get package installation directory for linker scripts
        import("core.base.global")
        local arm_embedded_dir = nil
        local packages_path = path.join(global.directory(), "packages", "a", "arm-embedded")
        
        if os.isdir(packages_path) then
            local versions = os.dirs(path.join(packages_path, "*"))
            if #versions > 0 then
                table.sort(versions)
                local latest = versions[#versions]
                local installs = os.dirs(path.join(latest, "*"))
                if #installs > 0 then
                    arm_embedded_dir = installs[1]
                end
            end
        end
        
        -- Apply linker script
        if arm_embedded_dir then
            local linker_script = target:values("embedded.linker_script")
            if not linker_script then
                -- Use common linker script with memory symbols
                linker_script = path.join(arm_embedded_dir, "linker", "common.ld")
                if os.isfile(linker_script) then
                    target:add("ldflags", "-T" .. linker_script, {force = true})
                    -- Set memory symbols
                    target:add("ldflags", "-Wl,--defsym,__flash_size=" .. config.flash, {force = true})
                    target:add("ldflags", "-Wl,--defsym,__ram_size=" .. config.ram, {force = true})
                    target:add("ldflags", "-Wl,--defsym,__flash_origin=0x08000000", {force = true})
                    target:add("ldflags", "-Wl,--defsym,__ram_origin=0x20000000", {force = true})
                end
            else
                target:add("ldflags", "-T" .. linker_script, {force = true})
            end
        end
        
        -- Store MCU for flash task
        target:data_set("embedded.mcu", mcu)
    end)
    
    after_build(function(target)
        -- Generate binary file for flashing
        local targetfile = target:targetfile()
        local binfile = path.join(path.directory(targetfile), path.basename(targetfile) .. ".bin")
        
        local objcopy = nil
        local toolchains = target:get("toolchains")
        
        if toolchains and toolchains[1] == "llvm-arm-embedded" then
            -- Get LLVM bindir
            import("core.base.global")
            local llvm_path = path.join(global.directory(), "packages", "l", "llvm-arm-embedded")
            if os.isdir(llvm_path) then
                local versions = os.dirs(path.join(llvm_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest = versions[#versions]
                    local installs = os.dirs(path.join(latest, "*"))
                    if #installs > 0 then
                        objcopy = path.join(installs[1], "bin", "llvm-objcopy")
                    end
                end
            end
            if not objcopy then
                objcopy = "llvm-objcopy"
            end
        else
            -- Get GCC ARM bindir
            import("core.base.global")
            local gcc_path = path.join(global.directory(), "packages", "g", "gcc-arm")
            if os.isdir(gcc_path) then
                local versions = os.dirs(path.join(gcc_path, "*"))
                if #versions > 0 then
                    table.sort(versions)
                    local latest = versions[#versions]
                    local installs = os.dirs(path.join(latest, "*"))
                    if #installs > 0 then
                        objcopy = path.join(installs[1], "bin", "arm-none-eabi-objcopy")
                    end
                end
            end
            if not objcopy then
                objcopy = "arm-none-eabi-objcopy"
            end
        end
        
        print("=> Generating binary: " .. path.filename(binfile))
        -- Only copy loadable sections to avoid huge binaries
        local ok, errors = os.execv(objcopy, {"-O", "binary", "-j", ".isr_vector", "-j", ".text", "-j", ".rodata", "-j", ".data", targetfile, binfile})
        if not ok then
            print("Error generating binary: " .. (errors or "unknown error"))
        end
        
        -- Save binary path for flash task
        target:data_set("embedded.binfile", binfile)
    end)