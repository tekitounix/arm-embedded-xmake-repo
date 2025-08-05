package("gcc-arm")

    set_kind("toolchain")
    set_homepage("https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gcc-arm")
    set_description("GNU Arm Embedded Toolchain")

    add_versions("2020.10", "90057b8737b888c53ca5aee332f1f73c401d6d3873124d2c2906df4347ebef9e")
    add_versions("2021.10", "d287439b3090843f3f4e29c7c41f81d958a5323aecefcf705c203bfd8ae3f2e7")
    add_versions("2024.12", "f074615953f76036e9a51b87f6577fdb4ed8e77d3322a6f68214e92e7859888f")
    add_versions("2025.02", "864c0c8815857d68a1bbba2e5e2782255bb922845c71c97636004a3d74f60986")
    add_versions("14.2.Rel1", "f074615953f76036e9a51b87f6577fdb4ed8e77d3322a6f68214e92e7859888f")
    add_versions("14.3.Rel1", "864c0c8815857d68a1bbba2e5e2782255bb922845c71c97636004a3d74f60986")

    on_load(function (package)
        local version = tostring(package:version())
        
        -- Version aliases
        if version == "14.2.Rel1" then
            version = "2024.12"
        elseif version == "14.3.Rel1" then
            version = "2025.02"
        end
        
        -- Set URLs based on version and platform
        if version == "2020.10" then
            if package:is_plat("windows") then
                package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-win32.zip",
                               "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-win32.zip")
            elseif package:is_plat("linux") then
                if package:is_arch("x86_64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2",
                                   "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2",
                                   "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2")
                end
            elseif package:is_plat("macosx") then
                package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-mac.tar.bz2",
                               "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-mac.tar.bz2")
            end
        elseif version == "2021.10" then
            if package:is_plat("windows") then
                package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-win32.zip",
                               "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-win32.zip")
            elseif package:is_plat("linux") then
                if package:is_arch("x86_64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2",
                                   "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-aarch64-linux.tar.bz2",
                                   "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-aarch64-linux.tar.bz2")
                end
            elseif package:is_plat("macosx") then
                package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-mac.tar.bz2",
                               "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-mac.tar.bz2")
            end
        elseif version == "2024.12" then
            if package:is_plat("windows") then
                if package:is_arch("x64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-x86_64-arm-none-eabi.zip")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-mingw-w64-i686-arm-none-eabi.zip")
                end
            elseif package:is_plat("linux") then
                if package:is_arch("x86_64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-x86_64-arm-none-eabi.tar.xz")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-aarch64-arm-none-eabi.tar.xz")
                end
            elseif package:is_plat("macosx") then
                if package:is_arch("arm64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-darwin-arm64-arm-none-eabi.tar.xz")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-darwin-x86_64-arm-none-eabi.tar.xz")
                end
            end
        elseif version == "2025.02" then
            if package:is_plat("windows") then
                if package:is_arch("x64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-x86_64-arm-none-eabi.zip")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-mingw-w64-i686-arm-none-eabi.zip")
                end
            elseif package:is_plat("linux") then
                if package:is_arch("x86_64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-x86_64-arm-none-eabi.tar.xz")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-aarch64-arm-none-eabi.tar.xz")
                end
            elseif package:is_plat("macosx") then
                if package:is_arch("arm64") then
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-darwin-arm64-arm-none-eabi.tar.xz")
                else
                    package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-darwin-x86_64-arm-none-eabi.tar.xz")
                end
            end
        end
        
        -- Install toolchain definition during on_load
        import("core.base.global")
        local user_toolchain_dir = path.join(global.directory(), "toolchains", "gcc-arm")
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
        os.vcp("*", package:installdir())
        
        -- Verify installation
        local bindir = path.join(package:installdir(), "bin")
        local gcc_exe = is_host("windows") and "arm-none-eabi-gcc.exe" or "arm-none-eabi-gcc"
        local gcc_path = path.join(bindir, gcc_exe)
        
        if not os.isfile(gcc_path) then
            raise("GCC binary not found at: " .. gcc_path)
        end
        
        print("GCC ARM toolchain installed successfully")
    end)

    on_test(function (package)
        local gcc = path.join(package:installdir(), "bin", "arm-none-eabi-gcc")
        if package:is_plat("windows") then
            gcc = gcc .. ".exe"
        end
        os.vrunv(gcc, {"--version"})
    end)