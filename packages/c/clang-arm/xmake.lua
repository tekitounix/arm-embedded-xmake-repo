package("clang-arm")

    set_kind("toolchain")
    set_homepage("https://github.com/arm/arm-toolchain")
    set_description("Arm Toolchain for Embedded (LLVM-based toolchain for 32-bit Arm embedded targets)")
    
    -- Version mapping: xmake version -> release tag suffix
    -- Releases after 19.1.5 use new naming: ATfE-X.Y.Z (Arm Toolchain for Embedded)
    -- Older releases use: LLVM-ET-Arm-X.Y.Z
    local new_format_versions = {
        ["21.1.1"] = true,
        ["21.1.0"] = true,
        ["20.1.0"] = true,
    }
    
    -- Add URLs and versions first (platform-specific)
    if is_host("linux") then
        if os.arch():find("arm64.*") then
            -- New format: ATfE-X.Y.Z-Linux-AArch64.tar.xz
            add_urls("https://github.com/arm/arm-toolchain/releases/download/release-$(version)-ATfE/ATfE-$(version)-Linux-AArch64.tar.xz")
            add_versions("21.1.1", "dfd93d7c79f26667f4baf7f388966aa4cbfd938bc5cbcf0ae064553faf3e9604")
            add_versions("21.1.0", "4c26c3424df23d6d22f5b740e99488bc3c16180a22c5eedfdf8f1f0bffeac3f5")
            add_versions("20.1.0", "fbe71ef55db943a27a5f2f0e2995797a1da5471f38f5d55bdf4d9f66d5c6715d")
            
            -- Old format: LLVM-ET-Arm-X.Y.Z-Linux-AArch64.tar.xz
            add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Linux-AArch64.tar.xz",
                     "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-$(version)/LLVM-ET-Arm-$(version)-Linux-AArch64.tar.xz")
            add_versions("19.1.5", "5e2f6b8c77464371ae2d7445114b4bdc19f56138e8aa864495181b52f57d0b85")
            add_versions("19.1.1", "0172cf1768072a398572cb1fc0bb42551d60181b3280f12c19401d94ca5162e6")
            add_versions("18.1.3", "47cd08804e22cdd260be43a00b632f075c3e1ad5a2636537c5589713ab038505")
        else
            -- New format
            add_urls("https://github.com/arm/arm-toolchain/releases/download/release-$(version)-ATfE/ATfE-$(version)-Linux-x86_64.tar.xz")
            add_versions("21.1.1", "fd7fcc2eb4c88c53b71c45f9c6aa83317d45da5c1b51b0720c66f1ac70151e6e")
            add_versions("21.1.0", "b18ee0fcfd5b06249e4b843d01e24ed0c4d1680cf6805c4846768735cb472a58")
            add_versions("20.1.0", "b3b43c1c34c70ebfc5c851cea24bb81ebad6c5f854b1a88899fd27791187edc")
            
            -- Old format
            add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Linux-x86_64.tar.xz",
                     "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-$(version)/LLVM-ET-Arm-$(version)-Linux-x86_64.tar.xz")
            add_versions("19.1.5", "34ee877aadc78c5e9f067e603a1bc9745ed93ca7ae5dbfc9b4406508dc153920")
            add_versions("19.1.1", "f659c625302f6d3fb50f040f748206f6fd6bb1fc7e398057dd2deaf1c1f5e8d1")
            add_versions("18.1.3", "7afae248ac33f7daee95005d1b0320774d8a5495e7acfb9bdc9475d3ad400ac9")
        end
    elseif is_host("windows") then
        -- New format
        add_urls("https://github.com/arm/arm-toolchain/releases/download/release-$(version)-ATfE/ATfE-$(version)-Windows-x86_64.zip")
        add_versions("21.1.1", "12e21352acd6ce514df77b6c9ff77e20978cbb44d4c7f922bd44c60594869460")
        add_versions("21.1.0", "652b59986b621e395bf735eac6404a1aa64dd752c7383ed4a6fbc4e7e4a63aa4")
        add_versions("20.1.0", "c84de7e69cb11b55a5290e40c27657b3e5c72a9d39bd8e3c91ca65ee587bb171")
        
        -- Old format
        add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Windows-x86_64.zip",
                 "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-$(version)/LLVM-ET-Arm-$(version)-Windows-x86_64.zip")
        add_versions("19.1.5", "f4b26357071a5bae0c1dfe5e0d5061595a8cc1f5d921b6595cc3b269021384eb")
        add_versions("19.1.1", "3bf972ecff428cf9398753f7f2bef11220a0bfa4119aabdb1b6c8c9608105ee4")
        add_versions("18.1.3", "3013dcf1dba425b644e64cb4311b9b7f6ff26df01ba1fcd943105d6bb2a6e68b")
    elseif is_host("macosx") then
        -- New format (ATfE: Arm Toolchain for Embedded)
        add_urls("https://github.com/arm/arm-toolchain/releases/download/release-$(version)-ATfE/ATfE-$(version)-Darwin-universal.dmg")
        add_versions("21.1.1", "2173cdb297ead08965ae1a34e4e92389b9024849b4ff4eb875652ff9667b7b2a")
        add_versions("21.1.0", "a310b4e8603bc25d71444d8a70e8ee9c2362cb4c8f4dcdb91a35fa371b45f425")
        add_versions("20.1.0", "11505eed22ceafcb52ef3d678a0640c67af92f511a9dd14309a44a766fafd703")
        
        -- Old format
        add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Darwin-universal.dmg")
        add_versions("19.1.5", "0451e67dc9a9066c17f746c26654962fa3889d4df468db1245d1bae69438eaf5")
        add_versions("19.1.1", "32c9253ab05e111cffc1746864a3e1debffb7fbb48631da88579e4f830fca163")
        add_versions("18.1.3", "2864324ddff4d328e4818cfcd7e8c3d3970e987edf24071489f4182b80187a48")
    end
    
    -- Package configuration and toolchain definition installation
    on_load(function (package)
        -- Warn about known issues with clang-tidy compatibility in affected versions
        -- Note: LLVM 21.x+ clang-tidy is not affected; this warning is for users with clang-tidy 20.x
        if package:version() and package:version():ge("21.1.0") and package:version():le("21.1.1") then
            print("Note: clang-arm " .. package:version_str() .. " multilib.yaml may cause issues with clang-tidy 20.x.")
            print("      If using clang-tidy 21.x+, this warning can be ignored.")
            print("      Patched multilib.yaml.tidy is available if needed.")
        end
        
        package:addenv("PATH", "bin")
        
        -- Install toolchain definition to user's xmake directory during on_load
        -- This ensures the toolchain is available before set_toolchains() is evaluated
        import("core.base.global")
        local toolchain_file = path.join(package:scriptdir(), "toolchains", "xmake.lua")
        if os.isfile(toolchain_file) then
            local user_toolchain_dir = path.join(global.directory(), "toolchains", "clang-arm")
            local dest_file = path.join(user_toolchain_dir, "xmake.lua")
            local need_update = true
            
            -- Compare file contents to avoid unnecessary updates
            if os.isfile(dest_file) then
                local src_content = io.readfile(toolchain_file)
                local dst_content = io.readfile(dest_file)
                if src_content == dst_content then
                    need_update = false
                end
            end
            
            if need_update then
                os.mkdir(user_toolchain_dir)
                os.cp(toolchain_file, dest_file)
            end
        end
    end)

    on_install("linux", "windows", "macosx", function(package)
        if package:is_plat("macosx") then
            -- Mount DMG
            local mountdir
            local result = os.iorunv("hdiutil", {"attach", package:originfile()})
            if result then
                for _, line in ipairs(result:split("\n", {plain = true})) do
                    local pos = line:find("/Volumes", 1, true)
                    if pos then
                        mountdir = line:sub(pos):trim()
                        break
                    end
                end
            end

            local function safe_detach()
                if mountdir and os.isdir(mountdir) then
                    try { function() os.execv("hdiutil", {"detach", mountdir, "-force"}) end }
                end
            end

            if not mountdir or not os.isdir(mountdir) then
                raise("cannot mount DMG: %s", package:originfile())
            end

            -- Find toolchain directory (ATfE-* or LLVM-ET-Arm-*)
            local toolchaindir
            for _, dir in ipairs(os.dirs(path.join(mountdir, "*"))) do
                local basename = path.basename(dir)
                if basename:find("ATfE") or basename:find("LLVM%-ET%-Arm") then
                    toolchaindir = dir
                    break
                end
            end
            if not toolchaindir then
                safe_detach()
                raise("cannot find toolchain directory in %s", mountdir)
            end

            -- Copy files
            local copy_ok = try { function()
                os.vexecv("bash", {"-c", format("cp -R %s/* %s", toolchaindir, package:installdir())})
                return true
            end }

            safe_detach()

            if not copy_ok then
                raise("Failed to copy toolchain files from DMG")
            end
        else
            -- Linux/Windows extraction
            os.vrunv("tar", {"-xzf", package:originfile(), "-C", package:installdir(), "--strip-components=1"})
        end
        
        -- Ensure binaries are executable
        if not is_host("windows") then
            local bindir = path.join(package:installdir(), "bin")
            if os.isdir(bindir) then
                os.vrunv("chmod", {"-R", "+x", bindir})
            end
        end
        
        -- Create patched multilib.yaml for clang-tidy compatibility (21.1.0 and 21.1.1)
        -- The IncludeDirs key was introduced in 21.1.0 and is not recognized by clang-tidy 20.x
        -- We create both versions: multilib.yaml (for build) and multilib.yaml.tidy (for clang-tidy)
        if package:version() and package:version():ge("21.1.0") and package:version():le("21.1.1") then
            local multilib = path.join(package:installdir(), "lib", "clang-runtimes", "multilib.yaml")
            if os.isfile(multilib) then
                -- Create patched version for clang-tidy
                local multilib_tidy = multilib .. ".tidy"
                os.cp(multilib, multilib_tidy)
                io.gsub(multilib_tidy, "\n  IncludeDirs:", "\n  # IncludeDirs (patched for clang-tidy):")
                print("Created multilib.yaml.tidy for clang-tidy compatibility")
            end
        end
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
