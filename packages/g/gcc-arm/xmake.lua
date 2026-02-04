package("gcc-arm")

    set_kind("toolchain")
    set_homepage("https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads")
    set_description("Arm GNU Toolchain for bare-metal targets")

    local version_map = {
        ["14.2.1"] = "14.2.rel1",
        ["14.3.1"] = "14.3.rel1",
        ["15.2.1"] = "15.2.rel1"
    }

    -- Use Azure Blob mirror (no CAPTCHA) - note: path uses lowercase 'files'
    if is_host("windows") then
        if os.arch() == "x86" then
            add_urls("https://armkeil.blob.core.windows.net/developer/files/downloads/gnu/$(version)/binrel/arm-gnu-toolchain-$(version)-mingw-w64-i686-arm-none-eabi.zip", {version = function (version)
                return version_map[tostring(version)]
            end})
            add_versions("14.2.1", "6facb152ce431ba9a4517e939ea46f057380f8f1e56b62e8712b3f3b87d994e1")
            add_versions("14.3.1", "836ebe51fd71b6542dd7884c8fb2011192464b16c28e4b38fddc9350daba5ee8")
            add_versions("15.2.1", "b40db54536d2fdf0ff21f4316b56c1fc4d3b782b792c5b298bcbeaf5eccedb96")
        else
            add_urls("https://armkeil.blob.core.windows.net/developer/files/downloads/gnu/$(version)/binrel/arm-gnu-toolchain-$(version)-mingw-w64-x86_64-arm-none-eabi.zip", {version = function (version)
                return version_map[tostring(version)]
            end})
            add_versions("14.2.1", "f074615953f76036e9a51b87f6577fdb4ed8e77d3322a6f68214e92e7859888f")
            add_versions("14.3.1", "864c0c8815857d68a1bbba2e5e2782255bb922845c71c97636004a3d74f60986")
            add_versions("15.2.1", "7936cac895611023ffb22a64b8e426098c7104cb689778c1894572ca840b9ece")
        end
    elseif is_host("linux") then
        if os.arch() == "arm64" then
            add_urls("https://armkeil.blob.core.windows.net/developer/files/downloads/gnu/$(version)/binrel/arm-gnu-toolchain-$(version)-aarch64-arm-none-eabi.tar.xz", {version = function (version)
                return version_map[tostring(version)]
            end})
            add_versions("14.2.1", "87330bab085dd8749d4ed0ad633674b9dc48b237b61069e3b481abd364d0a684")
            add_versions("14.3.1", "2d465847eb1d05f876270494f51034de9ace9abe87a4222d079f3360240184d3")
            add_versions("15.2.1", "d061559d814b205ed30c5b7c577c03317ec447ca51cd5a159d26b12a5bbeb20c")
        else
            add_urls("https://armkeil.blob.core.windows.net/developer/files/downloads/gnu/$(version)/binrel/arm-gnu-toolchain-$(version)-x86_64-arm-none-eabi.tar.xz", {version = function (version)
                return version_map[tostring(version)]
            end})
            add_versions("14.2.1", "62a63b981fe391a9cbad7ef51b17e49aeaa3e7b0d029b36ca1e9c3b2a9b78823")
            add_versions("14.3.1", "8f6903f8ceb084d9227b9ef991490413014d991874a1e34074443c2a72b14dbd")
            add_versions("15.2.1", "597893282ac8c6ab1a4073977f2362990184599643b4c5ee34870a8215783a16")
        end
    elseif is_host("macosx") and os.arch() ~= "arm64" then
        set_urls("https://armkeil.blob.core.windows.net/developer/files/downloads/gnu/$(version)/binrel/arm-gnu-toolchain-$(version)-darwin-x86_64-arm-none-eabi.tar.xz", {version = function (version)
                return version_map[tostring(version)]
            end})
        add_versions("14.2.1", "2d9e717dd4f7751d18936ae1365d25916534105ebcb7583039eff1092b824505")
        -- Note: 14.3.rel1 and 15.2.rel1 are not available for macOS x64
    elseif is_host("macosx") then
        set_urls(
            "https://armkeil.blob.core.windows.net/developer/files/downloads/gnu/$(version)/binrel/arm-gnu-toolchain-$(version)-darwin-arm64-arm-none-eabi.tar.xz", {version = function (version)
                return version_map[tostring(version)]
            end})
        add_versions("14.2.1", "c7c78ffab9bebfce91d99d3c24da6bf4b81c01e16cf551eb2ff9f25b9e0a3818")
        add_versions("14.3.1", "30f4d08b219190a37cded6aa796f4549504902c53cfc3c7e044a8490b6eba1f7")
        add_versions("15.2.1", "1938a84b7105c192e3fb4fa5e893ba25f425f7ddab40515ae608cd40f68669a8")
    end
    
    -- Package configuration and toolchain definition installation
    on_load(function (package)
        -- Platform-specific version limitations
        if package:is_plat("macosx") and package:arch() == "x86_64" then
            -- 14.3.rel1 and 15.2.rel1 are not available for macOS x64
            local ver = package:version()
            if ver:eq("14.3.1") or ver:eq("15.2.1") then
                raise("gcc-arm %s is not available for macOS x64, please use 14.2.1 instead", package:version_str())
            end
        end
        
        package:addenv("PATH", "bin")
        
        -- Install toolchain definition to user's xmake directory during on_load
        -- This ensures the toolchain is available before set_toolchains() is evaluated
        import("core.base.global")
        local toolchain_file = path.join(package:scriptdir(), "toolchains", "xmake.lua")
        if os.isfile(toolchain_file) then
            local user_toolchain_dir = path.join(global.directory(), "toolchains", "gcc-arm")
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

    on_install("@windows", "@linux", "@macosx", function(package)
        -- Find archive in cache directory
        local cachedir = package:cachedir()
        local originfile = nil
        for _, file in ipairs(os.files(path.join(cachedir, "*.tar.xz"))) do
            originfile = file
            break
        end
        if not originfile then
            for _, file in ipairs(os.files(path.join(cachedir, "*.zip"))) do
                originfile = file
                break
            end
        end

        if not originfile or not os.isfile(originfile) then
            raise("gcc-arm: Archive not found in cache: %s", cachedir)
        end

        -- Extract
        os.vrunv("tar", {"-xJf", originfile, "-C", package:installdir(), "--strip-components=1"})
        
        -- Ensure binaries are executable
        if not is_host("windows") then
            local bindir = path.join(package:installdir(), "bin")
            if os.isdir(bindir) then
                os.vrunv("chmod", {"-R", "+x", bindir})
            end
        end
    end)

    on_test(function (package)
        local gcc = path.join(package:installdir(), "bin", "arm-none-eabi-gcc")
        if is_host("windows") then
            gcc = gcc .. ".exe"
        end
        -- Test that gcc exists and supports ARM targets
        os.vrunv(gcc, {"--version"})
        os.vrunv(gcc, {"--target-help"})
    end)