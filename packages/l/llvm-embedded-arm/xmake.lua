package("llvm-embedded-arm")

    set_kind("toolchain")
    set_homepage("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm")
    set_description("A project dedicated to building LLVM toolchain for 32-bit Arm embedded targets.")
    
    -- Add URLs and versions first (platform-specific)
    if is_host("linux") then
        if os.arch():find("arm64.*") then
            add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Linux-AArch64.tar.xz")
            add_versions("18.1.3", "47cd08804e22cdd260be43a00b632f075c3e1ad5a2636537c5589713ab038505")
        else
            add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Linux-x86_64.tar.xz")
            add_versions("18.1.3", "7afae248ac33f7daee95005d1b0320774d8a5495e7acfb9bdc9475d3ad400ac9")
        end
    elseif is_host("windows") then
        add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Windows-x86_64.zip")
        add_versions("18.1.3", "3013dcf1dba425b644e64cb4311b9b7f6ff26df01ba1fcd943105d6bb2a6e68b")
    elseif is_host("macosx") then
        add_urls("https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-$(version)/LLVM-ET-Arm-$(version)-Darwin-universal.dmg")
        add_versions("18.1.3", "2864324ddff4d328e4818cfcd7e8c3d3970e987edf24071489f4182b80187a48")
    end
    
    -- Toolchain configuration
    on_load(function (package)
        if package:is_library() then
            return
        end
        package:addenv("PATH", "bin")
    end)
    
    on_fetch(function (package, opt)
        if opt.system then
            return
        end
        local result = nil
        local installdir = package:installdir()
        if installdir and os.isdir(installdir) then
            result = result or {}
            result.program = result.program or {}
            result.program.cc = path.join(installdir, "bin", "clang")
            result.program.cxx = path.join(installdir, "bin", "clang++")
            result.program.ld = path.join(installdir, "bin", "clang++")
            result.program.ar = path.join(installdir, "bin", "llvm-ar")
            result.program.strip = path.join(installdir, "bin", "llvm-strip")
            result.program.ranlib = path.join(installdir, "bin", "llvm-ranlib")
            result.program.objcopy = path.join(installdir, "bin", "llvm-objcopy")
            result.program.as = path.join(installdir, "bin", "clang")
            
            -- Toolchain setup
            result.toolname = "llvm-embedded-arm"
            result.toolchain = {
                name = "llvm-embedded-arm",
                kind = "cross",
                cross = "arm-none-eabi-",
                sdkdir = installdir,
                bindir = path.join(installdir, "bin"),
                -- Toolset definition
                toolset = {
                    cc = "clang",
                    cxx = {"clang++", "clang"},
                    ld = {"clang++", "clang"},
                    sh = {"clang++", "clang"},
                    ar = "llvm-ar",
                    ex = "llvm-ar",
                    ranlib = "llvm-ranlib",
                    strip = "llvm-strip",
                    objcopy = "llvm-objcopy",
                    as = "clang"
                }
            }
        end
        return result
    end)

    on_install("linux", "windows", "macosx", function(package)
        if package:is_plat("macosx") then
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
            print("=> Mounted DMG at %s", mountdir)
            
            -- Find LLVM-ET-Arm-* directory in DMG
            local toolchaindir
            for _, dir in ipairs(os.dirs(path.join(mountdir, "*"))) do
                local basename = path.basename(dir)
                if basename:find("LLVM%-ET%-Arm") then
                    toolchaindir = dir
                    break
                end
            end
            assert(toolchaindir, "cannot find LLVM-ET-Arm directory in %s", mountdir)
            print("=> Found toolchain at %s", toolchaindir)
            
            print("=> Copying toolchain files to %s ...", package:installdir())
            os.vcp(path.join(toolchaindir, "*"), package:installdir())
            
            print("=> Unmounting DMG ...")
            os.execv("hdiutil", {"detach", mountdir})
        else
            os.vcp("*", package:installdir())
        end
    end)

    on_test(function (package)
        local clang = "clang"
        if package:is_plat("windows") then
            clang = clang .. ".exe"
        end
        os.vrunv(clang, {"--version"})
    end)