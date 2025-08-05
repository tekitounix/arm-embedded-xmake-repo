package("gcc-arm")

    set_kind("toolchain")
    set_homepage("https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gcc-arm")
    set_description("GNU Arm Embedded Toolchain")

    -- Version data table
    local version_data = {
        ["2020.10"] = {
            urlpath = "10-2020q4/gcc-arm-none-eabi-10-2020-q4-major",
            checksums = {
                windows_x64 = "90057b8737b888c53ca5aee332f1f73c401d6d3873124d2c2906df4347ebef9e",
                linux_x64   = "21134caa478bbf5352e239fbc6e2da3038f8d2207e089efc96c3b55f1edcd618",
                linux_arm64 = "343d8c812934fe5a904c73583a91edd812b1ac20636eb52de04135bb0f5cf36a",
                macos_x64   = "bed12de3565d4eb02e7b58be945376eaca79a8ae3ebb785ec7344e7e2db0bdc0"
            }
        },
        ["2021.10"] = {
            urlpath = "10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10",
            checksums = {
                windows_x64 = "d287439b3090843f3f4e29c7c41f81d958a5323aecefcf705c203bfd8ae3f2e7",
                linux_x64   = "97dbb4f019ad1650b732faffcc881689cedc14e2b7ee863d390e0a41ef16c9a3",
                linux_arm64 = "f605b5f23ca898e9b8b665be208510a54a6e9fdd0fa5bfc9592002f6e7431208",
                macos_x64   = "fb613dacb25149f140f73fe9ff6c380bb43328e6bf813473986e9127e2bc283b"
            }
        },
        ["2024.12"] = {
            urlpath = "14.2.rel1",
            checksums = {
                windows_x64 = "f074615953f76036e9a51b87f6577fdb4ed8e77d3322a6f68214e92e7859888f",
                windows_x86 = "6facb152ce431ba9a4517e939ea46f057380f8f1e56b62e8712b3f3b87d994e1",
                linux_x64   = "62a63b981fe391a9cbad7ef51b17e49aeaa3e7b0d029b36ca1e9c3b2a9b78823",
                linux_arm64 = "87330bab085dd8749d4ed0ad633674b9dc48b237b61069e3b481abd364d0a684",
                macos_x64   = "2d9e717dd4f7751d18936ae1365d25916534105ebcb7583039eff1092b824505",
                macos_arm64 = "c7c78ffab9bebfce91d99d3c24da6bf4b81c01e16cf551eb2ff9f25b9e0a3818"
            }
        },
        ["2025.02"] = {
            urlpath = "14.3.rel1",
            checksums = {
                windows_x64 = "864c0c8815857d68a1bbba2e5e2782255bb922845c71c97636004a3d74f60986",
                windows_x86 = "836ebe51fd71b6542dd7884c8fb2011192464b16c28e4b38fddc9350daba5ee8",
                linux_x64   = "8f6903f8ceb084d9227b9ef991490413014d991874a1e34074443c2a72b14dbd",
                linux_arm64 = "2d465847eb1d05f876270494f51034de9ace9abe87a4222d079f3360240184d3",
                macos_arm64 = "30f4d08b219190a37cded6aa796f4549504902c53cfc3c7e044a8490b6eba1f7"
            }
        }
    }
    
    -- Version aliases
    local version_aliases = {
        ["14.2.Rel1"] = "2024.12",
        ["14.3.Rel1"] = "2025.02"
    }

    -- Add all versions
    for version, _ in pairs(version_data) do
        add_versions(version, "dummy")
    end
    for alias, _ in pairs(version_aliases) do
        add_versions(alias, "dummy")
    end

    on_load(function (package)
        local version = tostring(package:version())
        
        -- Resolve version aliases
        if version_aliases[version] then
            version = version_aliases[version]
        end
        
        local vdata = version_data[version]
        if not vdata then
            raise("Unknown version: " .. version)
        end
        
        -- Determine platform key
        local platform_key = nil
        if is_host("windows") then
            platform_key = (os.arch() == "x64") and "windows_x64" or "windows_x86"
        elseif is_host("linux") then
            platform_key = os.arch():find("arm64.*") and "linux_arm64" or "linux_x64"
        elseif is_host("macosx") then
            platform_key = (os.arch() == "arm64") and "macos_arm64" or "macos_x64"
        end
        
        if not platform_key or not vdata.checksums[platform_key] then
            raise("Unsupported platform for version " .. version)
        end
        
        -- Set URLs based on version
        if version == "2020.10" or version == "2021.10" then
            -- Old URL format
            local suffix_map = {
                windows_x64 = "-win32.zip",
                linux_x64   = "-x86_64-linux.tar.bz2",
                linux_arm64 = "-aarch64-linux.tar.bz2",
                macos_x64   = "-mac.tar.bz2"
            }
            package:add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/$(version)" .. suffix_map[platform_key], 
                           {version = function(v) return vdata.urlpath end})
            package:add_urls("https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/$(version)/" .. 
                           path.basename(vdata.urlpath) .. suffix_map[platform_key])
        else
            -- New URL format
            local platform_map = {
                windows_x64 = "x86_64-arm-none-eabi.zip",
                windows_x86 = "mingw-w64-i686-arm-none-eabi.zip",
                linux_x64   = "x86_64-arm-none-eabi.tar.xz",
                linux_arm64 = "aarch64-arm-none-eabi.tar.xz",
                macos_x64   = "darwin-x86_64-arm-none-eabi.tar.xz",
                macos_arm64 = "darwin-arm64-arm-none-eabi.tar.xz"
            }
            package:add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/$(version)/binrel/arm-gnu-toolchain-$(version)-" .. platform_map[platform_key],
                           {version = function(v) return vdata.urlpath end})
        end
        
        package:add_checksums(vdata.checksums[platform_key])
        
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