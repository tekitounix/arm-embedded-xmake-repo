package("clang-arm")

    set_kind("toolchain")
    set_homepage("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm")
    set_description("A project dedicated to building LLVM toolchain for 32-bit Arm embedded targets.")
    
    -- Add URLs and versions first (platform-specific)
    if is_host("linux") then
        if os.arch():find("arm64.*") then
            add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Linux-AArch64.tar.xz",
                     "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-$(version)/LLVM-ET-Arm-$(version)-Linux-AArch64.tar.xz")
            add_versions("19.1.5", "5e2f6b8c77464371ae2d7445114b4bdc19f56138e8aa864495181b52f57d0b85")
            add_versions("19.1.1", "0172cf1768072a398572cb1fc0bb42551d60181b3280f12c19401d94ca5162e6")
            add_versions("18.1.3", "47cd08804e22cdd260be43a00b632f075c3e1ad5a2636537c5589713ab038505")
        else
            add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Linux-x86_64.tar.xz",
                     "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-$(version)/LLVM-ET-Arm-$(version)-Linux-x86_64.tar.xz")
            add_versions("19.1.5", "34ee877aadc78c5e9f067e603a1bc9745ed93ca7ae5dbfc9b4406508dc153920")
            add_versions("19.1.1", "f659c625302f6d3fb50f040f748206f6fd6bb1fc7e398057dd2deaf1c1f5e8d1")
            add_versions("18.1.3", "7afae248ac33f7daee95005d1b0320774d8a5495e7acfb9bdc9475d3ad400ac9")
        end
    elseif is_host("windows") then
        add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Windows-x86_64.zip",
                 "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-$(version)/LLVM-ET-Arm-$(version)-Windows-x86_64.zip")
        add_versions("19.1.5", "f4b26357071a5bae0c1dfe5e0d5061595a8cc1f5d921b6595cc3b269021384eb")
        add_versions("19.1.1", "3bf972ecff428cf9398753f7f2bef11220a0bfa4119aabdb1b6c8c9608105ee4")
        add_versions("18.1.3", "3013dcf1dba425b644e64cb4311b9b7f6ff26df01ba1fcd943105d6bb2a6e68b")
    elseif is_host("macosx") then
        add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Darwin-universal.dmg")
        add_versions("19.1.5", "0451e67dc9a9066c17f746c26654962fa3889d4df468db1245d1bae69438eaf5")
        add_versions("19.1.1", "32c9253ab05e111cffc1746864a3e1debffb7fbb48631da88579e4f830fca163")
        add_versions("18.1.3", "2864324ddff4d328e4818cfcd7e8c3d3970e987edf24071489f4182b80187a48")
    end
    
    -- Package configuration and toolchain definition installation
    on_load(function (package)
        -- Show package info
        local installdir = package:installdir()
        if not os.isdir(installdir) or not os.isfile(path.join(installdir, "bin", "clang")) then
            cprint("${green}[clang-arm]${clear} Preparing to install LLVM Embedded Toolchain for Arm %s", package:version_str())
            cprint("${green}[clang-arm]${clear} Expected download size: ~200MB (DMG on macOS)")
            cprint("${green}[clang-arm]${clear} Expected install size: ~800MB (extracted)")
            cprint("${green}[clang-arm]${clear} Download may take several minutes depending on your connection...")
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
            -- This improves performance while ensuring consistency
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
                print("=> Toolchain definition installed to: %s", user_toolchain_dir)
            end
        end
    end)

    on_install("linux", "windows", "macosx", function(package)
        import("core.base.option")
        
        cprint("${green}[clang-arm]${clear} Installing LLVM Embedded Toolchain for Arm %s...", package:version_str())
        
        if package:is_plat("macosx") then
            -- Show DMG info
            local originfile = package:originfile()
            if os.isfile(originfile) then
                local filesize = os.filesize(originfile)
                cprint("${green}[clang-arm]${clear} DMG size: ${bright}%.2f MB${clear}", filesize / 1024 / 1024)
            end
            
            cprint("${green}[clang-arm]${clear} Mounting DMG image...")
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
            assert(mountdir and os.isdir(mountdir), "cannot mount %s", package:originfile())
            cprint("${green}[clang-arm]${clear} Mounted at: %s", mountdir)
            
            -- Find LLVM-ET-Arm-* directory in DMG
            cprint("${green}[clang-arm]${clear} Looking for toolchain directory...")
            local toolchaindir
            for _, dir in ipairs(os.dirs(path.join(mountdir, "*"))) do
                local basename = path.basename(dir)
                if basename:find("LLVM%-ET%-Arm") then
                    toolchaindir = dir
                    break
                end
            end
            assert(toolchaindir, "cannot find LLVM-ET-Arm directory in %s", mountdir)
            cprint("${green}[clang-arm]${clear} Found toolchain: %s", path.basename(toolchaindir))
            
            cprint("${green}[clang-arm]${clear} Copying toolchain files...")
            cprint("${green}[clang-arm]${clear} This may take a few minutes (~800MB of files)...")
            
            if option.get("verbose") or option.get("diagnosis") then
                -- Use shell to expand wildcards
                os.vexecv("bash", {"-c", format("cp -Rv %s/* %s", toolchaindir, package:installdir())})
            else
                -- Show progress with rsync if available
                if os.iorun("which rsync") then
                    -- rsync needs trailing slashes for directory contents
                    os.vrunv("rsync", {"-ah", "--progress", toolchaindir .. "/", package:installdir() .. "/"})
                else
                    -- Fallback to shell cp to handle wildcards
                    io.write("[clang-arm] Copying files")
                    io.flush()
                    os.vexecv("bash", {"-c", format("cp -R %s/* %s", toolchaindir, package:installdir())})
                    print(" done!")
                end
            end
            
            cprint("${green}[clang-arm]${clear} Unmounting DMG...")
            os.execv("hdiutil", {"detach", mountdir})
        else
            -- Linux/Windows extraction
            local originfile = package:originfile()
            if os.isfile(originfile) then
                local filesize = os.filesize(originfile)
                cprint("${green}[clang-arm]${clear} Archive size: ${bright}%.2f MB${clear}", filesize / 1024 / 1024)
            end
            
            cprint("${green}[clang-arm]${clear} Extracting toolchain files...")
            if option.get("verbose") or option.get("diagnosis") then
                os.vrunv("tar", {"-xzvf", originfile, "-C", package:installdir(), "--strip-components=1"})
            else
                io.write("[clang-arm] Extracting")
                io.flush()
                os.vrunv("tar", {"-xzf", originfile, "-C", package:installdir(), "--strip-components=1"})
                print(" done!")
            end
        end
        
        -- Ensure binaries are executable
        cprint("${green}[clang-arm]${clear} Setting up toolchain binaries...")
        if not is_host("windows") then
            local bindir = path.join(package:installdir(), "bin")
            if os.isdir(bindir) then
                os.vrunv("chmod", {"-R", "+x", bindir})
            end
        end
        
        -- Verify installation by checking key binaries
        cprint("${green}[clang-arm]${clear} Verifying installation...")
        local bindir = path.join(package:installdir(), "bin")
        if not os.isdir(bindir) then
            raise("Clang ARM bin directory not found after extraction: " .. bindir)
        end
        
        local clang_exe = is_host("windows") and "clang.exe" or "clang"
        local clang_path = path.join(bindir, clang_exe)
        if not os.isfile(clang_path) then
            raise("Clang ARM compiler not found after extraction: " .. clang_path)
        end
        
        -- Verify the toolchain works
        local verify_ok = try { function()
            os.vrunv(clang_path, {"--version"})
            return true
        end }
        
        if not verify_ok then
            raise("Clang ARM installed but not functional")
        end
        
        cprint("${green}[clang-arm]${clear} Installation completed successfully!")
        cprint("${green}[clang-arm]${clear} Toolchain installed to: ${bright}%s${clear}", package:installdir())
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
