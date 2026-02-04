package("renode")
    set_kind("binary")
    set_description("Renode - embedded systems emulator")
    set_homepage("https://renode.io/")
    
    -- Version from renode/renode GitHub releases
    add_versions("1.16.0", "dummy")
    
    -- URL patterns for different platforms:
    -- macOS arm64: renode-1.16.0-dotnet.osx-arm64-portable.dmg (78MB, .NET bundled)
    -- macOS x64:   renode_1.16.0.dmg (30MB, requires Mono)
    -- Linux x64:   renode-1.16.0.linux-portable.tar.gz (48MB, Mono bundled)
    --              renode-1.16.0.linux-portable-dotnet.tar.gz (72MB, .NET bundled)
    -- Linux arm64: renode-1.16.0.linux-arm64-portable-dotnet.tar.gz (70MB, .NET bundled)
    -- Windows x64: renode-1.16.0.windows-portable-dotnet.zip (111MB, .NET bundled)
    -- Windows arm64: NOT AVAILABLE
    
    local function get_download_info(version)
        local base_url = "https://github.com/renode/renode/releases/download/v" .. version .. "/"
        
        if is_host("macosx") then
            if os.arch() == "arm64" then
                -- macOS arm64: use dotnet portable DMG
                return base_url .. "renode-" .. version .. "-dotnet.osx-arm64-portable.dmg", "dmg", "arm64"
            else
                -- macOS x64: use standard DMG (requires system Mono)
                return base_url .. "renode_" .. version .. ".dmg", "dmg", "x64"
            end
        elseif is_host("linux") then
            if os.arch() == "arm64" then
                -- Linux arm64: dotnet portable only
                return base_url .. "renode-" .. version .. ".linux-arm64-portable-dotnet.tar.gz", "tar.gz", "arm64"
            else
                -- Linux x64: prefer Mono portable (smaller)
                return base_url .. "renode-" .. version .. ".linux-portable.tar.gz", "tar.gz", "x64"
            end
        elseif is_host("windows") then
            -- Windows x64 only (arm64 not available)
            return base_url .. "renode-" .. version .. ".windows-portable-dotnet.zip", "zip", "x64"
        end
        return nil, nil, nil
    end
    
    -- Disable system fetch to force package installation
    on_fetch(function (package, opt)
        if os.isdir(package:installdir()) then
            local renode_bin = path.join(package:installdir("bin"), "renode")
            if is_host("windows") then
                renode_bin = renode_bin .. ".exe"
            end
            if os.isfile(renode_bin) then
                return {
                    name = package:name(),
                    version = package:version_str(),
                    installdir = package:installdir()
                }
            end
        end
        return nil
    end)
    
    on_install("windows", "macosx", "linux", function (package)
        import("net.http")
        import("utils.archive")
        
        local version = package:version_str()
        local url, archive_type, arch = get_download_info(version)
        
        if not url then
            raise("Renode package is not available for this platform")
        end
        
        print("Downloading Renode from: " .. url)
        
        -- Download the archive
        local archive_file = path.join(os.tmpdir(), path.filename(url))
        http.download(url, archive_file)
        
        if not os.isfile(archive_file) then
            raise("Failed to download Renode archive")
        end
        
        local source_dir = nil
        
        if is_host("macosx") and archive_type == "dmg" then
            -- Handle DMG files on macOS
            local mount_point = path.join(os.tmpdir(), "renode_mount_" .. os.uuid())
            os.mkdir(mount_point)
            
            -- Mount DMG
            local mount_ok = try { function()
                os.runv("hdiutil", {"attach", archive_file, "-nobrowse", "-mountpoint", mount_point})
                return true
            end }
            
            if not mount_ok then
                raise("Failed to mount Renode DMG")
            end
            
            -- Find Renode.app in the mounted volume
            local app_path = path.join(mount_point, "Renode.app")
            if not os.isdir(app_path) then
                os.runv("hdiutil", {"detach", mount_point})
                raise("Renode.app not found in DMG")
            end
            
            -- Copy the application contents to install directory
            local contents_path = path.join(app_path, "Contents", "MacOS")
            os.cp(path.join(contents_path, "*"), package:installdir())
            
            -- Unmount DMG
            os.runv("hdiutil", {"detach", mount_point})
            os.rm(mount_point)
            
            -- Create bin directory with wrapper scripts
            os.mkdir(package:installdir("bin"))
            
            -- Create renode wrapper
            local renode_wrapper = path.join(package:installdir("bin"), "renode")
            local renode_real = path.join(package:installdir(), "renode")
            io.writefile(renode_wrapper, string.format([[#!/bin/sh
exec "%s" "$@"
]], renode_real))
            os.runv("chmod", {"+x", renode_wrapper})
            
            -- Create renode-test wrapper
            local renode_test_real = path.join(package:installdir(), "renode-test")
            if os.isfile(renode_test_real) then
                local renode_test_wrapper = path.join(package:installdir("bin"), "renode-test")
                io.writefile(renode_test_wrapper, string.format([[#!/bin/sh
exec "%s" "$@"
]], renode_test_real))
                os.runv("chmod", {"+x", renode_test_wrapper})
            end
            
        else
            -- Handle tar.gz/zip files
            local extract_dir = path.join(os.tmpdir(), "renode_extract")
            os.mkdir(extract_dir)
            archive.extract(archive_file, extract_dir)
            
            -- Find the extracted directory
            local extracted_dirs = os.dirs(path.join(extract_dir, "renode*"))
            if #extracted_dirs == 0 then
                extracted_dirs = os.dirs(path.join(extract_dir, "*"))
            end
            
            if #extracted_dirs == 0 then
                raise("Failed to find extracted Renode directory")
            end
            
            source_dir = extracted_dirs[1]
            
            -- Copy files to install directory
            os.cp(path.join(source_dir, "*"), package:installdir())
            
            -- Create bin directory with wrapper scripts (for Linux/Windows)
            os.mkdir(package:installdir("bin"))
            
            if is_host("windows") then
                -- Create renode.bat wrapper
                local renode_wrapper = path.join(package:installdir("bin"), "renode.bat")
                local renode_real = path.join(package:installdir(), "renode.exe")
                io.writefile(renode_wrapper, string.format([[
@echo off
"%s" %%*
]], renode_real))
            else
                -- Create renode wrapper
                local renode_wrapper = path.join(package:installdir("bin"), "renode")
                local renode_real = path.join(package:installdir(), "renode")
                io.writefile(renode_wrapper, string.format([[#!/bin/sh
exec "%s" "$@"
]], renode_real))
                os.runv("chmod", {"+x", renode_wrapper})
                
                -- Create renode-test wrapper
                local renode_test_real = path.join(package:installdir(), "renode-test")
                if os.isfile(renode_test_real) then
                    local renode_test_wrapper = path.join(package:installdir("bin"), "renode-test")
                    io.writefile(renode_test_wrapper, string.format([[#!/bin/sh
exec "%s" "$@"
]], renode_test_real))
                    os.runv("chmod", {"+x", renode_test_wrapper})
                end
            end
            
            -- Cleanup extract directory
            os.rm(extract_dir)
        end
        
        -- Cleanup archive file
        os.rm(archive_file)
        
        -- Verify installation
        local renode_bin = path.join(package:installdir("bin"), "renode")
        if is_host("windows") then
            renode_bin = renode_bin .. ".bat"
        end
        
        if not os.isfile(renode_bin) then
            raise("Renode wrapper not found after installation")
        end
        
        -- Verify Renode works
        print("Verifying Renode installation...")
        local verify_ok = try { function()
            local renode_real = path.join(package:installdir(), "renode")
            if is_host("windows") then
                renode_real = renode_real .. ".exe"
            end
            os.vrunv(renode_real, {"--version"})
            return true
        end }
        
        if not verify_ok then
            raise("Renode installed but not functional")
        end
        
        -- Add to PATH
        package:addenv("PATH", "bin")
        
        print("Renode package installed successfully")
    end)
    
    on_load(function (package)
        package:addenv("PATH", "bin")
    end)
    
    on_test(function (package)
        local renode_real = path.join(package:installdir(), "renode")
        if is_host("windows") then
            renode_real = renode_real .. ".exe"
        end
        os.vrunv(renode_real, {"--version"})
    end)
package_end()
