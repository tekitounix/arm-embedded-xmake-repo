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

    -- Add all versions at global level
    for version, _ in pairs(version_data) do
        add_versions(version, "dummy")
    end
    for alias, _ in pairs(version_aliases) do
        add_versions(alias, "dummy")
    end

    -- Add URLs for each version and platform combination at global level
    -- 2020.10 and 2021.10 (old format)
    for _, version in ipairs({"2020.10", "2021.10"}) do
        local vdata = version_data[version]
        if vdata then
            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-win32.zip",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-win32.zip",
                     {version = "2020.10", os = "windows", arch = "x64"})
            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2",
                     {version = "2020.10", os = "linux", arch = "x86_64"})
            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2",
                     {version = "2020.10", os = "linux", arch = "arm64"})
            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-mac.tar.bz2",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-mac.tar.bz2",
                     {version = "2020.10", os = "macosx", arch = "x86_64"})

            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-win32.zip",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-win32.zip",
                     {version = "2021.10", os = "windows", arch = "x64"})
            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2",
                     {version = "2021.10", os = "linux", arch = "x86_64"})
            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-aarch64-linux.tar.bz2",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-aarch64-linux.tar.bz2",
                     {version = "2021.10", os = "linux", arch = "arm64"})
            add_urls("https://developer.arm.com/-/media/Files/downloads/gcc-arm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-mac.tar.bz2",
                     "https://github.com/xmake-mirror/gnu-arm-embedded/releases/download/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-mac.tar.bz2",
                     {version = "2021.10", os = "macosx", arch = "x86_64"})
        end
    end

    -- 2024.12 (new format)
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-x86_64-arm-none-eabi.zip",
             {version = "2024.12", os = "windows", arch = "x64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-mingw-w64-i686-arm-none-eabi.zip",
             {version = "2024.12", os = "windows", arch = "x86"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-x86_64-arm-none-eabi.tar.xz",
             {version = "2024.12", os = "linux", arch = "x86_64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-aarch64-arm-none-eabi.tar.xz",
             {version = "2024.12", os = "linux", arch = "arm64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-darwin-x86_64-arm-none-eabi.tar.xz",
             {version = "2024.12", os = "macosx", arch = "x86_64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-darwin-arm64-arm-none-eabi.tar.xz",
             {version = "2024.12", os = "macosx", arch = "arm64"})

    -- 2025.02 (new format)
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-x86_64-arm-none-eabi.zip",
             {version = "2025.02", os = "windows", arch = "x64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-mingw-w64-i686-arm-none-eabi.zip",
             {version = "2025.02", os = "windows", arch = "x86"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-x86_64-arm-none-eabi.tar.xz",
             {version = "2025.02", os = "linux", arch = "x86_64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-aarch64-arm-none-eabi.tar.xz",
             {version = "2025.02", os = "linux", arch = "arm64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-darwin-arm64-arm-none-eabi.tar.xz",
             {version = "2025.02", os = "macosx", arch = "arm64"})

    -- Version aliases
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-x86_64-arm-none-eabi.zip",
             {version = "14.2.Rel1", os = "windows", arch = "x64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-mingw-w64-i686-arm-none-eabi.zip",
             {version = "14.2.Rel1", os = "windows", arch = "x86"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-x86_64-arm-none-eabi.tar.xz",
             {version = "14.2.Rel1", os = "linux", arch = "x86_64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-aarch64-arm-none-eabi.tar.xz",
             {version = "14.2.Rel1", os = "linux", arch = "arm64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-darwin-x86_64-arm-none-eabi.tar.xz",
             {version = "14.2.Rel1", os = "macosx", arch = "x86_64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.Rel1-darwin-arm64-arm-none-eabi.tar.xz",
             {version = "14.2.Rel1", os = "macosx", arch = "arm64"})

    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-x86_64-arm-none-eabi.zip",
             {version = "14.3.Rel1", os = "windows", arch = "x64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-mingw-w64-i686-arm-none-eabi.zip",
             {version = "14.3.Rel1", os = "windows", arch = "x86"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-x86_64-arm-none-eabi.tar.xz",
             {version = "14.3.Rel1", os = "linux", arch = "x86_64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-aarch64-arm-none-eabi.tar.xz",
             {version = "14.3.Rel1", os = "linux", arch = "arm64"})
    add_urls("https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.Rel1-darwin-arm64-arm-none-eabi.tar.xz",
             {version = "14.3.Rel1", os = "macosx", arch = "arm64"})

    -- Add checksums for all versions and platforms
    add_checksums("90057b8737b888c53ca5aee332f1f73c401d6d3873124d2c2906df4347ebef9e", {version = "2020.10", os = "windows", arch = "x64"})
    add_checksums("21134caa478bbf5352e239fbc6e2da3038f8d2207e089efc96c3b55f1edcd618", {version = "2020.10", os = "linux", arch = "x86_64"})
    add_checksums("343d8c812934fe5a904c73583a91edd812b1ac20636eb52de04135bb0f5cf36a", {version = "2020.10", os = "linux", arch = "arm64"})
    add_checksums("bed12de3565d4eb02e7b58be945376eaca79a8ae3ebb785ec7344e7e2db0bdc0", {version = "2020.10", os = "macosx", arch = "x86_64"})

    add_checksums("d287439b3090843f3f4e29c7c41f81d958a5323aecefcf705c203bfd8ae3f2e7", {version = "2021.10", os = "windows", arch = "x64"})
    add_checksums("97dbb4f019ad1650b732faffcc881689cedc14e2b7ee863d390e0a41ef16c9a3", {version = "2021.10", os = "linux", arch = "x86_64"})
    add_checksums("f605b5f23ca898e9b8b665be208510a54a6e9fdd0fa5bfc9592002f6e7431208", {version = "2021.10", os = "linux", arch = "arm64"})
    add_checksums("fb613dacb25149f140f73fe9ff6c380bb43328e6bf813473986e9127e2bc283b", {version = "2021.10", os = "macosx", arch = "x86_64"})

    add_checksums("f074615953f76036e9a51b87f6577fdb4ed8e77d3322a6f68214e92e7859888f", {version = "2024.12", os = "windows", arch = "x64"})
    add_checksums("6facb152ce431ba9a4517e939ea46f057380f8f1e56b62e8712b3f3b87d994e1", {version = "2024.12", os = "windows", arch = "x86"})
    add_checksums("62a63b981fe391a9cbad7ef51b17e49aeaa3e7b0d029b36ca1e9c3b2a9b78823", {version = "2024.12", os = "linux", arch = "x86_64"})
    add_checksums("87330bab085dd8749d4ed0ad633674b9dc48b237b61069e3b481abd364d0a684", {version = "2024.12", os = "linux", arch = "arm64"})
    add_checksums("2d9e717dd4f7751d18936ae1365d25916534105ebcb7583039eff1092b824505", {version = "2024.12", os = "macosx", arch = "x86_64"})
    add_checksums("c7c78ffab9bebfce91d99d3c24da6bf4b81c01e16cf551eb2ff9f25b9e0a3818", {version = "2024.12", os = "macosx", arch = "arm64"})

    add_checksums("864c0c8815857d68a1bbba2e5e2782255bb922845c71c97636004a3d74f60986", {version = "2025.02", os = "windows", arch = "x64"})
    add_checksums("836ebe51fd71b6542dd7884c8fb2011192464b16c28e4b38fddc9350daba5ee8", {version = "2025.02", os = "windows", arch = "x86"})
    add_checksums("8f6903f8ceb084d9227b9ef991490413014d991874a1e34074443c2a72b14dbd", {version = "2025.02", os = "linux", arch = "x86_64"})
    add_checksums("2d465847eb1d05f876270494f51034de9ace9abe87a4222d079f3360240184d3", {version = "2025.02", os = "linux", arch = "arm64"})
    add_checksums("30f4d08b219190a37cded6aa796f4549504902c53cfc3c7e044a8490b6eba1f7", {version = "2025.02", os = "macosx", arch = "arm64"})

    -- Alias checksums
    add_checksums("f074615953f76036e9a51b87f6577fdb4ed8e77d3322a6f68214e92e7859888f", {version = "14.2.Rel1", os = "windows", arch = "x64"})
    add_checksums("6facb152ce431ba9a4517e939ea46f057380f8f1e56b62e8712b3f3b87d994e1", {version = "14.2.Rel1", os = "windows", arch = "x86"})
    add_checksums("62a63b981fe391a9cbad7ef51b17e49aeaa3e7b0d029b36ca1e9c3b2a9b78823", {version = "14.2.Rel1", os = "linux", arch = "x86_64"})
    add_checksums("87330bab085dd8749d4ed0ad633674b9dc48b237b61069e3b481abd364d0a684", {version = "14.2.Rel1", os = "linux", arch = "arm64"})
    add_checksums("2d9e717dd4f7751d18936ae1365d25916534105ebcb7583039eff1092b824505", {version = "14.2.Rel1", os = "macosx", arch = "x86_64"})
    add_checksums("c7c78ffab9bebfce91d99d3c24da6bf4b81c01e16cf551eb2ff9f25b9e0a3818", {version = "14.2.Rel1", os = "macosx", arch = "arm64"})

    add_checksums("864c0c8815857d68a1bbba2e5e2782255bb922845c71c97636004a3d74f60986", {version = "14.3.Rel1", os = "windows", arch = "x64"})
    add_checksums("836ebe51fd71b6542dd7884c8fb2011192464b16c28e4b38fddc9350daba5ee8", {version = "14.3.Rel1", os = "windows", arch = "x86"})
    add_checksums("8f6903f8ceb084d9227b9ef991490413014d991874a1e34074443c2a72b14dbd", {version = "14.3.Rel1", os = "linux", arch = "x86_64"})
    add_checksums("2d465847eb1d05f876270494f51034de9ace9abe87a4222d079f3360240184d3", {version = "14.3.Rel1", os = "linux", arch = "arm64"})
    add_checksums("30f4d08b219190a37cded6aa796f4549504902c53cfc3c7e044a8490b6eba1f7", {version = "14.3.Rel1", os = "macosx", arch = "arm64"})

    on_load(function (package)
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