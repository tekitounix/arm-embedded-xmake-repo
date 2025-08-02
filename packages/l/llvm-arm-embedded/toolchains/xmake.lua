-- LLVM ARM Embeddedツールチェーン定義
toolchain("llvm-arm-embedded")
    set_kind("cross")
    set_description("LLVM Embedded Toolchain for ARM")
    
    -- ツールセットを定義（パスはon_loadで設定）
    set_toolset("cc", "clang")
    set_toolset("cxx", "clang++")
    set_toolset("ld", "clang++")
    set_toolset("sh", "clang++")
    set_toolset("ar", "llvm-ar")
    set_toolset("strip", "llvm-strip")
    set_toolset("ranlib", "llvm-ranlib")
    set_toolset("objcopy", "llvm-objcopy")
    set_toolset("as", "clang")
    
    on_load(function (toolchain)
        -- Get package installation directory
        import("core.project.project")
        local requires = project.required_packages()
        if requires and requires["llvm-arm-embedded"] then
            local pkg = requires["llvm-arm-embedded"]
            local installdir = pkg:installdir()
            if installdir and os.isdir(installdir) then
                local bindir = path.join(installdir, "bin")
                toolchain:set("bindir", bindir)
            end
        end
    end)
    
    on_check(function (toolchain)
        import("lib.detect.find_tool")
        local clang = find_tool("clang", {check = function (tool)
            -- Check if this is ARM embedded clang by looking for arm-none-eabi support
            local ok = try { function()
                os.runv(tool.program, {"--target=arm-none-eabi", "--version"})
                return true
            end }
            return ok
        end})
        
        local clangxx = find_tool("clang++", {check = function (tool)
            -- Check if this is ARM embedded clang++ by looking for arm-none-eabi support
            local ok = try { function()
                os.runv(tool.program, {"--target=arm-none-eabi", "--version"})
                return true
            end }
            return ok
        end})
        
        return clang and clangxx
    end)
toolchain_end()