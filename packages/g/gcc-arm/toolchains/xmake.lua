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
        -- Get package installation directory
        import("core.project.project")
        local requires = project.required_packages()
        if requires and requires["gcc-arm"] then
            local pkg = requires["gcc-arm"]
            local installdir = pkg:installdir()
            if installdir and os.isdir(installdir) then
                local bindir = path.join(installdir, "bin")
                toolchain:set("bindir", bindir)
            end
        end
    end)
    
    on_check(function (toolchain)
        return import("lib.detect.find_tool")("arm-none-eabi-gcc")
    end)
toolchain_end()