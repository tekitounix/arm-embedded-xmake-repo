--! ESP32 Toolchain for xmake
--
-- Provides toolchain definition for ESP32 series chips
-- Supports both Xtensa (ESP32/S2/S3) and RISC-V (ESP32-C/H/P) architectures
--

toolchain("esp32-xtensa")
    set_kind("standalone")
    set_sdkdir("$(env ESP_TOOLS_PATH)")
    
    set_toolset("cc", "xtensa-esp32-elf-gcc")
    set_toolset("cxx", "xtensa-esp32-elf-g++")
    set_toolset("ld", "xtensa-esp32-elf-gcc")
    set_toolset("ar", "xtensa-esp32-elf-ar")
    set_toolset("as", "xtensa-esp32-elf-as")
    set_toolset("objcopy", "xtensa-esp32-elf-objcopy")
    set_toolset("objdump", "xtensa-esp32-elf-objdump")
    set_toolset("strip", "xtensa-esp32-elf-strip")
    set_toolset("size", "xtensa-esp32-elf-size")
    
    on_check(function(toolchain)
        return import("lib.detect.find_tool")("xtensa-esp32-elf-gcc")
    end)
    
    on_load(function(toolchain)
        -- Common flags for ESP32 Xtensa
        toolchain:add("cxflags", "-ffunction-sections", "-fdata-sections", "-fstrict-volatile-bitfields")
        toolchain:add("cxflags", "-mlongcalls", "-nostdlib")
        toolchain:add("ldflags", "-nostdlib", "-Wl,--gc-sections")
        toolchain:add("ldflags", "-Wl,--cref", "-Wl,--Map=$(buildir)/$(targetname).map")
        
        -- ESP-IDF requires specific C standard
        toolchain:add("cflags", "-std=gnu17")
        toolchain:add("cxxflags", "-std=gnu++20")
    end)
toolchain_end()

toolchain("esp32s2-xtensa")
    set_kind("standalone")
    set_sdkdir("$(env ESP_TOOLS_PATH)")
    
    set_toolset("cc", "xtensa-esp32s2-elf-gcc")
    set_toolset("cxx", "xtensa-esp32s2-elf-g++")
    set_toolset("ld", "xtensa-esp32s2-elf-gcc")
    set_toolset("ar", "xtensa-esp32s2-elf-ar")
    set_toolset("as", "xtensa-esp32s2-elf-as")
    set_toolset("objcopy", "xtensa-esp32s2-elf-objcopy")
    set_toolset("objdump", "xtensa-esp32s2-elf-objdump")
    set_toolset("strip", "xtensa-esp32s2-elf-strip")
    set_toolset("size", "xtensa-esp32s2-elf-size")
    
    on_check(function(toolchain)
        return import("lib.detect.find_tool")("xtensa-esp32s2-elf-gcc")
    end)
    
    on_load(function(toolchain)
        toolchain:add("cxflags", "-ffunction-sections", "-fdata-sections", "-fstrict-volatile-bitfields")
        toolchain:add("cxflags", "-mlongcalls", "-nostdlib")
        toolchain:add("ldflags", "-nostdlib", "-Wl,--gc-sections")
        toolchain:add("cflags", "-std=gnu17")
        toolchain:add("cxxflags", "-std=gnu++20")
    end)
toolchain_end()

toolchain("esp32s3-xtensa")
    set_kind("standalone")
    set_sdkdir("$(env ESP_TOOLS_PATH)")
    
    set_toolset("cc", "xtensa-esp32s3-elf-gcc")
    set_toolset("cxx", "xtensa-esp32s3-elf-g++")
    set_toolset("ld", "xtensa-esp32s3-elf-gcc")
    set_toolset("ar", "xtensa-esp32s3-elf-ar")
    set_toolset("as", "xtensa-esp32s3-elf-as")
    set_toolset("objcopy", "xtensa-esp32s3-elf-objcopy")
    set_toolset("objdump", "xtensa-esp32s3-elf-objdump")
    set_toolset("strip", "xtensa-esp32s3-elf-strip")
    set_toolset("size", "xtensa-esp32s3-elf-size")
    
    on_check(function(toolchain)
        return import("lib.detect.find_tool")("xtensa-esp32s3-elf-gcc")
    end)
    
    on_load(function(toolchain)
        toolchain:add("cxflags", "-ffunction-sections", "-fdata-sections", "-fstrict-volatile-bitfields")
        toolchain:add("cxflags", "-mlongcalls", "-nostdlib")
        toolchain:add("ldflags", "-nostdlib", "-Wl,--gc-sections")
        toolchain:add("cflags", "-std=gnu17")
        toolchain:add("cxxflags", "-std=gnu++20")
    end)
toolchain_end()

-- RISC-V based ESP32 chips (C2, C3, C5, C6, H2, P4)
toolchain("esp32-riscv")
    set_kind("standalone")
    set_sdkdir("$(env ESP_TOOLS_PATH)")
    
    set_toolset("cc", "riscv32-esp-elf-gcc")
    set_toolset("cxx", "riscv32-esp-elf-g++")
    set_toolset("ld", "riscv32-esp-elf-gcc")
    set_toolset("ar", "riscv32-esp-elf-ar")
    set_toolset("as", "riscv32-esp-elf-as")
    set_toolset("objcopy", "riscv32-esp-elf-objcopy")
    set_toolset("objdump", "riscv32-esp-elf-objdump")
    set_toolset("strip", "riscv32-esp-elf-strip")
    set_toolset("size", "riscv32-esp-elf-size")
    
    on_check(function(toolchain)
        return import("lib.detect.find_tool")("riscv32-esp-elf-gcc")
    end)
    
    on_load(function(toolchain)
        -- RISC-V specific flags
        toolchain:add("cxflags", "-ffunction-sections", "-fdata-sections", "-fstrict-volatile-bitfields")
        toolchain:add("cxflags", "-march=rv32imc", "-mabi=ilp32", "-nostdlib")
        toolchain:add("ldflags", "-nostdlib", "-Wl,--gc-sections")
        toolchain:add("cflags", "-std=gnu17")
        toolchain:add("cxxflags", "-std=gnu++20")
    end)
toolchain_end()

-- Unified ESP32 toolchain that auto-detects variant
toolchain("esp32")
    set_kind("standalone")
    
    on_check(function(toolchain)
        -- Check for any ESP toolchain
        return import("lib.detect.find_tool")("xtensa-esp32-elf-gcc") 
            or import("lib.detect.find_tool")("riscv32-esp-elf-gcc")
    end)
    
    on_load(function(toolchain)
        import("core.project.config")
        
        -- Get variant from config or default to esp32
        local variant = config.get("esp_variant") or "esp32"
        
        -- Variant to architecture mapping
        local xtensa_variants = {
            ["esp32"] = "xtensa-esp32-elf-",
            ["esp32s2"] = "xtensa-esp32s2-elf-",
            ["esp32s3"] = "xtensa-esp32s3-elf-",
        }
        
        local riscv_variants = {
            ["esp32c2"] = true, ["esp32c3"] = true, ["esp32c5"] = true,
            ["esp32c6"] = true, ["esp32h2"] = true, ["esp32p4"] = true,
        }
        
        local prefix
        if xtensa_variants[variant] then
            prefix = xtensa_variants[variant]
            toolchain:add("cxflags", "-mlongcalls")
        elseif riscv_variants[variant] then
            prefix = "riscv32-esp-elf-"
            toolchain:add("cxflags", "-march=rv32imc", "-mabi=ilp32")
        else
            raise("Unknown ESP32 variant: " .. variant)
        end
        
        -- Set toolset
        toolchain:set("toolset", "cc", prefix .. "gcc")
        toolchain:set("toolset", "cxx", prefix .. "g++")
        toolchain:set("toolset", "ld", prefix .. "gcc")
        toolchain:set("toolset", "ar", prefix .. "ar")
        toolchain:set("toolset", "as", prefix .. "as")
        toolchain:set("toolset", "objcopy", prefix .. "objcopy")
        toolchain:set("toolset", "objdump", prefix .. "objdump")
        toolchain:set("toolset", "strip", prefix .. "strip")
        toolchain:set("toolset", "size", prefix .. "size")
        
        -- Common flags
        toolchain:add("cxflags", "-ffunction-sections", "-fdata-sections", "-fstrict-volatile-bitfields", "-nostdlib")
        toolchain:add("ldflags", "-nostdlib", "-Wl,--gc-sections")
        toolchain:add("cflags", "-std=gnu17")
        toolchain:add("cxxflags", "-std=gnu++20")
    end)
toolchain_end()
