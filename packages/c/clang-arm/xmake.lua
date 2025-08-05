package("clang-arm")

    set_kind("toolchain")
    set_homepage("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm")
    set_description("A project dedicated to building LLVM toolchain for 32-bit Arm embedded targets.")
    
    add_versions("18.1.3", "2864324ddff4d328e4818cfcd7e8c3d3970e987edf24071489f4182b80187a48")
    add_versions("19.1.1", "32c9253ab05e111cffc1746864a3e1debffb7fbb48631da88579e4f830fca163")
    add_versions("19.1.5", "0451e67dc9a9066c17f746c26654962fa3889d4df468db1245d1bae69438eaf5")
    
    on_load(function (package)
        package:addenv("PATH", "bin")
        
        local version = tostring(package:version())
        
        -- Set URLs based on version and platform
        local url_base = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download"
        local url_pattern = url_base .. "/release-" .. version .. "/LLVM-ET-Arm-" .. version
        local url_pattern_preview = url_base .. "/preview-" .. version .. "/LLVM-ET-Arm-" .. version
        
        if package:is_plat("linux") then
            if package:is_arch("arm64") then
                package:add_urls(url_pattern .. "-Linux-AArch64.tar.xz", url_pattern_preview .. "-Linux-AArch64.tar.xz")
            else
                package:add_urls(url_pattern .. "-Linux-x86_64.tar.xz", url_pattern_preview .. "-Linux-x86_64.tar.xz")
            end
        elseif package:is_plat("windows") then
            package:add_urls(url_pattern .. "-Windows-x86_64.zip", url_pattern_preview .. "-Windows-x86_64.zip")
        elseif package:is_plat("macosx") then
            package:add_urls(url_pattern .. "-Darwin-universal.dmg", url_pattern_preview .. "-Darwin-universal.dmg")
        end
        
        -- Install toolchain definition during on_load
        import("core.base.global")
        local user_toolchain_dir = path.join(global.directory(), "toolchains", "clang-arm")
        os.mkdir(user_toolchain_dir)
        
        local toolchain_content = io.readfile(path.join(os.scriptdir(), "toolchains", "xmake.lua"))
        if toolchain_content then
            local dest_file = path.join(user_toolchain_dir, "xmake.lua")
            if not os.isfile(dest_file) or io.readfile(dest_file) ~= toolchain_content then
                io.writefile(dest_file, toolchain_content)
                print("=> Toolchain definition installed to: %s", user_toolchain_dir)
            end
        end
    end)
    
    on_install("@windows", "@macosx", "@linux", function (package)
        if is_host("macosx") then
            -- macOS uses DMG, needs special handling
            local dmgfile = package:originfile()
            local tmpdir = os.tmpdir()
            local mountdir = path.join(tmpdir, "llvm-embedded-mount")
            
            -- Clean up any existing mount
            os.tryrunv("hdiutil", {"detach", mountdir}, {try = true})
            os.mkdir(mountdir)
            
            -- Mount the DMG
            os.vrunv("hdiutil", {"attach", dmgfile, "-mountpoint", mountdir, "-nobrowse", "-noverify", "-noautoopen"})
            
            -- Find the actual toolchain directory  
            local toolchaindir = nil
            for _, dir in ipairs(os.dirs(path.join(mountdir, "*"))) do
                if path.filename(dir):startswith("LLVM-ET-Arm") then
                    toolchaindir = dir
                    break
                end
            end
            assert(toolchaindir, "cannot find LLVM-ET-Arm directory in %s", mountdir)
            
            os.vcp(path.join(toolchaindir, "*"), package:installdir())
            os.execv("hdiutil", {"detach", mountdir})
        else
            os.vcp("*", package:installdir())
        end
        
        -- Verify installation
        local bindir = path.join(package:installdir(), "bin")
        local clang_exe = is_host("windows") and "clang.exe" or "clang"
        local clang_path = path.join(bindir, clang_exe)
        
        if not os.isfile(clang_path) then
            raise("Clang binary not found at: " .. clang_path)
        end
        
        -- Quick sanity check
        local ok = try { function()
            os.vrunv(clang_path, {"--version"})
            return true
        end }
        
        if not ok then
            raise("Clang binary exists but is not functional")
        end
        
        print("Clang ARM toolchain installed successfully")
    end)

    on_test(function (package)
        local clang = path.join(package:installdir(), "bin", "clang")
        if package:is_plat("windows") then
            clang = clang .. ".exe"
        end
        -- Test that clang exists and supports ARM targets
        os.vrunv(clang, {"--version"})
        os.vrunv(clang, {"--target=arm-none-eabi", "--version"})
    end)