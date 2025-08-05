package("clang-arm")

    set_kind("toolchain")
    set_homepage("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm")
    set_description("A project dedicated to building LLVM toolchain for 32-bit Arm embedded targets.")
    
    -- Version data table with platform-specific information
    local version_data = {
        ["18.1.3"] = {
            platforms = {
                ["linux_arm64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-18.1.3/LLVM-ET-Arm-18.1.3-Linux-AArch64.tar.xz",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-18.1.3/LLVM-ET-Arm-18.1.3-Linux-AArch64.tar.xz",
                    checksum = "47cd08804e22cdd260be43a00b632f075c3e1ad5a2636537c5589713ab038505"
                },
                ["linux_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-18.1.3/LLVM-ET-Arm-18.1.3-Linux-x86_64.tar.xz",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-18.1.3/LLVM-ET-Arm-18.1.3-Linux-x86_64.tar.xz",
                    checksum = "7afae248ac33f7daee95005d1b0320774d8a5495e7acfb9bdc9475d3ad400ac9"
                },
                ["windows_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-18.1.3/LLVM-ET-Arm-18.1.3-Windows-x86_64.zip",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-18.1.3/LLVM-ET-Arm-18.1.3-Windows-x86_64.zip",
                    checksum = "3013dcf1dba425b644e64cb4311b9b7f6ff26df01ba1fcd943105d6bb2a6e68b"
                },
                ["macos_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-18.1.3/LLVM-ET-Arm-18.1.3-Darwin-universal.dmg",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-18.1.3/LLVM-ET-Arm-18.1.3-Darwin-universal.dmg",
                    checksum = "2864324ddff4d328e4818cfcd7e8c3d3970e987edf24071489f4182b80187a48"
                },
                ["macos_arm64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-18.1.3/LLVM-ET-Arm-18.1.3-Darwin-universal.dmg",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-18.1.3/LLVM-ET-Arm-18.1.3-Darwin-universal.dmg",
                    checksum = "2864324ddff4d328e4818cfcd7e8c3d3970e987edf24071489f4182b80187a48"
                }
            }
        },
        ["19.1.1"] = {
            platforms = {
                ["linux_arm64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.1/LLVM-ET-Arm-19.1.1-Linux-AArch64.tar.xz",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.1/LLVM-ET-Arm-19.1.1-Linux-AArch64.tar.xz",
                    checksum = "0172cf1768072a398572cb1fc0bb42551d60181b3280f12c19401d94ca5162e6"
                },
                ["linux_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.1/LLVM-ET-Arm-19.1.1-Linux-x86_64.tar.xz",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.1/LLVM-ET-Arm-19.1.1-Linux-x86_64.tar.xz",
                    checksum = "f659c625302f6d3fb50f040f748206f6fd6bb1fc7e398057dd2deaf1c1f5e8d1"
                },
                ["windows_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.1/LLVM-ET-Arm-19.1.1-Windows-x86_64.zip",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.1/LLVM-ET-Arm-19.1.1-Windows-x86_64.zip",
                    checksum = "3bf972ecff428cf9398753f7f2bef11220a0bfa4119aabdb1b6c8c9608105ee4"
                },
                ["macos_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.1/LLVM-ET-Arm-19.1.1-Darwin-universal.dmg",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.1/LLVM-ET-Arm-19.1.1-Darwin-universal.dmg",
                    checksum = "32c9253ab05e111cffc1746864a3e1debffb7fbb48631da88579e4f830fca163"
                },
                ["macos_arm64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.1/LLVM-ET-Arm-19.1.1-Darwin-universal.dmg",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.1/LLVM-ET-Arm-19.1.1-Darwin-universal.dmg",
                    checksum = "32c9253ab05e111cffc1746864a3e1debffb7fbb48631da88579e4f830fca163"
                }
            }
        },
        ["19.1.5"] = {
            platforms = {
                ["linux_arm64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.5/LLVM-ET-Arm-19.1.5-Linux-AArch64.tar.xz",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.5/LLVM-ET-Arm-19.1.5-Linux-AArch64.tar.xz",
                    checksum = "5e2f6b8c77464371ae2d7445114b4bdc19f56138e8aa864495181b52f57d0b85"
                },
                ["linux_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.5/LLVM-ET-Arm-19.1.5-Linux-x86_64.tar.xz",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.5/LLVM-ET-Arm-19.1.5-Linux-x86_64.tar.xz",
                    checksum = "34ee877aadc78c5e9f067e603a1bc9745ed93ca7ae5dbfc9b4406508dc153920"
                },
                ["windows_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.5/LLVM-ET-Arm-19.1.5-Windows-x86_64.zip",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.5/LLVM-ET-Arm-19.1.5-Windows-x86_64.zip",
                    checksum = "f4b26357071a5bae0c1dfe5e0d5061595a8cc1f5d921b6595cc3b269021384eb"
                },
                ["macos_x64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.5/LLVM-ET-Arm-19.1.5-Darwin-universal.dmg",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.5/LLVM-ET-Arm-19.1.5-Darwin-universal.dmg",
                    checksum = "0451e67dc9a9066c17f746c26654962fa3889d4df468db1245d1bae69438eaf5"
                },
                ["macos_arm64"] = {
                    url = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-19.1.5/LLVM-ET-Arm-19.1.5-Darwin-universal.dmg",
                    mirror = "https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/preview-19.1.5/LLVM-ET-Arm-19.1.5-Darwin-universal.dmg",
                    checksum = "0451e67dc9a9066c17f746c26654962fa3889d4df468db1245d1bae69438eaf5"
                }
            }
        }
    }

    -- Determine current platform key
    local function get_platform_key()
        if is_host("windows") then
            return "windows_x64"
        elseif is_host("linux") then
            return os.arch():find("arm64.*") and "linux_arm64" or "linux_x64"
        elseif is_host("macosx") then
            return (os.arch() == "arm64") and "macos_arm64" or "macos_x64"
        end
        return nil
    end

    local platform_key = get_platform_key()

    -- Add versions and URLs only for current platform
    for version, vdata in pairs(version_data) do
        local platform_info = vdata.platforms[platform_key]
        if platform_info then
            add_versions(version, platform_info.checksum)
            if platform_info.mirror then
                add_urls(platform_info.url, platform_info.mirror)
            else
                add_urls(platform_info.url)
            end
        end
    end
    
    on_load(function (package)
        package:addenv("PATH", "bin")
        
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