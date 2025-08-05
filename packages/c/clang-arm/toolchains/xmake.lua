-- Clang ARM toolchain definition
toolchain("clang-arm")
    set_kind("cross")
    set_description("Clang/LLVM Toolchain for ARM")
    
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
        -- Try official approach first using toolchain:packages()
        local packages = toolchain:packages()
        if packages then
            for _, pkg in ipairs(packages) do
                if pkg:name() == "clang-arm" then
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
        -- e.g., in embedded rule or set_toolchains("clang-arm") without @clang-arm
        import("core.base.global")
        local clang_arm_path = path.join(global.directory(), "packages/c/clang-arm")
        if os.isdir(clang_arm_path) then
            local versions = os.dirs(path.join(clang_arm_path, "*"))
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