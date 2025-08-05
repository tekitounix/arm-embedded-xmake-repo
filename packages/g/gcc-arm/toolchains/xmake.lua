-- GNU ARM Embedded toolchain definition
toolchain("gcc-arm")
    set_kind("cross")
    set_description("GNU Arm Embedded Toolchain")
    
    -- Toolset definitions
    set_toolset("cc", "arm-none-eabi-gcc")
    set_toolset("cxx", "arm-none-eabi-g++")
    set_toolset("ld", "arm-none-eabi-g++")
    set_toolset("sh", "arm-none-eabi-g++")
    set_toolset("ar", "arm-none-eabi-ar")
    set_toolset("strip", "arm-none-eabi-strip")
    set_toolset("ranlib", "arm-none-eabi-ranlib")
    set_toolset("objcopy", "arm-none-eabi-objcopy")
    set_toolset("as", "arm-none-eabi-as")
    
    on_load(function (toolchain)
        -- Try official approach first using toolchain:packages()
        local packages = toolchain:packages()
        if packages then
            for _, pkg in ipairs(packages) do
                if pkg:name() == "gcc-arm" then
                    local bindir = path.join(pkg:installdir(), "bin")
                    if os.isdir(bindir) then
                        toolchain:set("bindir", bindir)
                        return
                    end
                end
            end
        end
        
        -- Fallback: Get package installation directory directly
        -- This is needed when toolchain is used without package specification
        -- e.g., in embedded rule or set_toolchains("gcc-arm") without @gcc-arm
        import("core.base.global")
        local gcc_arm_path = path.join(global.directory(), "packages/g/gcc-arm")
        if os.isdir(gcc_arm_path) then
            local versions = os.dirs(path.join(gcc_arm_path, "*"))
            if #versions > 0 then
                table.sort(versions)
                local latest = versions[#versions]
                local installs = os.dirs(path.join(latest, "*"))
                if #installs > 0 then
                    local install_dir = installs[1]
                    local bindir = path.join(install_dir, "bin")
                    if os.isdir(bindir) then
                        toolchain:set("bindir", bindir)
                    end
                end
            end
        end
    end)
    
    on_check(function (toolchain)
        return import("lib.detect.find_tool")("arm-none-eabi-gcc")
    end)
toolchain_end()