package("openocd")
    set_kind("binary")
    set_description("Open On-Chip Debugger - debugging, in-system programming and boundary-scan testing")
    set_homepage("https://openocd.org/")
    
    -- Version from xpack-dev-tools
    add_versions("0.12.0-7", "dummy")
    
    -- URL patterns for different platforms
    -- macOS arm64: xpack-openocd-0.12.0-7-darwin-arm64.tar.gz
    -- macOS x64:   xpack-openocd-0.12.0-7-darwin-x64.tar.gz
    -- Linux arm64: xpack-openocd-0.12.0-7-linux-arm64.tar.gz
    -- Linux x64:   xpack-openocd-0.12.0-7-linux-x64.tar.gz
    -- Windows x64: xpack-openocd-0.12.0-7-win32-x64.zip
    
    local function get_download_info(version)
        local base_url = "https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v" .. version .. "/"
        local prefix = "xpack-openocd-" .. version .. "-"
        
        if is_host("macosx") then
            if os.arch() == "arm64" then
                return base_url .. prefix .. "darwin-arm64.tar.gz", prefix:gsub("%-$", "")
            else
                return base_url .. prefix .. "darwin-x64.tar.gz", prefix:gsub("%-$", "")
            end
        elseif is_host("linux") then
            if os.arch() == "arm64" then
                return base_url .. prefix .. "linux-arm64.tar.gz", prefix:gsub("%-$", "")
            else
                return base_url .. prefix .. "linux-x64.tar.gz", prefix:gsub("%-$", "")
            end
        elseif is_host("windows") then
            -- Windows arm64 is not available from xpack
            return base_url .. prefix .. "win32-x64.zip", prefix:gsub("%-$", "")
        end
        return nil, nil
    end
    
    -- Disable system fetch to force package installation
    on_fetch(function (package, opt)
        if os.isdir(package:installdir()) then
            local openocd_bin = path.join(package:installdir("bin"), "openocd")
            if is_host("windows") then
                openocd_bin = openocd_bin .. ".exe"
            end
            if os.isfile(openocd_bin) then
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
        local url, dir_name = get_download_info(version)
        
        if not url then
            raise("OpenOCD package is not available for this platform")
        end
        
        print("Downloading OpenOCD from: " .. url)
        
        -- Download the archive
        local archive_file = path.join(os.tmpdir(), path.filename(url))
        http.download(url, archive_file)
        
        if not os.isfile(archive_file) then
            raise("Failed to download OpenOCD archive")
        end
        
        -- Extract the archive
        local extract_dir = path.join(os.tmpdir(), "openocd_extract")
        os.mkdir(extract_dir)
        archive.extract(archive_file, extract_dir)
        
        -- Find the extracted directory
        local extracted_dirs = os.dirs(path.join(extract_dir, "xpack-openocd-*"))
        if #extracted_dirs == 0 then
            -- Try without pattern match
            extracted_dirs = os.dirs(path.join(extract_dir, "*"))
        end
        
        if #extracted_dirs == 0 then
            raise("Failed to find extracted OpenOCD directory")
        end
        
        local source_dir = extracted_dirs[1]
        
        -- Copy files to install directory
        os.cp(path.join(source_dir, "*"), package:installdir())
        
        -- Cleanup
        os.rm(archive_file)
        os.rm(extract_dir)
        
        -- Verify installation
        local openocd_bin = path.join(package:installdir("bin"), "openocd")
        if is_host("windows") then
            openocd_bin = openocd_bin .. ".exe"
        end
        
        if not os.isfile(openocd_bin) then
            raise("OpenOCD binary not found after installation")
        end
        
        -- Verify OpenOCD works
        print("Verifying OpenOCD installation...")
        local verify_ok = try { function()
            os.vrunv(openocd_bin, {"--version"})
            return true
        end }
        
        if not verify_ok then
            raise("OpenOCD installed but not functional")
        end
        
        -- Add to PATH
        package:addenv("PATH", "bin")
        
        -- Set OPENOCD_SCRIPTS environment variable
        local scripts_dir = path.join(package:installdir(), "openocd", "scripts")
        if os.isdir(scripts_dir) then
            package:addenv("OPENOCD_SCRIPTS", scripts_dir)
        end
        
        print("OpenOCD package installed successfully")
    end)
    
    on_load(function (package)
        package:addenv("PATH", "bin")
        local scripts_dir = path.join(package:installdir(), "openocd", "scripts")
        if os.isdir(scripts_dir) then
            package:addenv("OPENOCD_SCRIPTS", scripts_dir)
        end
    end)
    
    on_test(function (package)
        local openocd_bin = path.join(package:installdir("bin"), "openocd")
        if is_host("windows") then
            openocd_bin = openocd_bin .. ".exe"
        end
        os.vrunv(openocd_bin, {"--version"})
    end)
package_end()
