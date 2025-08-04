package("pyocd")
    set_kind("binary")
    set_description("Python based tool for programming and debugging ARM Cortex-M microcontrollers using CMSIS-DAP")
    set_homepage("https://pyocd.io")
    
    -- Depend on python3 package
    add_deps("python3")
    
    -- Version management
    add_versions("0.34.2", "dummy")
    
    -- Disable system fetch to force package installation
    on_fetch(function (package, opt)
        -- Check if package is installed
        if os.isdir(package:installdir()) then
            return {
                name = package:name(),
                version = package:version_str(),
                installdir = package:installdir()
            }
        end
        -- Return nil to force installation
        return nil
    end)
    
    -- PyOCD will be installed via pip, no download needed
    
    on_install("macosx", "linux", function (package)
        -- Get python3 from dependency
        local python3_pkg = package:dep("python3")
        if not python3_pkg then
            raise("python3 package is required but not found")
        end
        
        -- Get python3 and pip3 from the package
        local python3_bin = path.join(python3_pkg:installdir("bin"), "python3")
        local pip3_bin = path.join(python3_pkg:installdir("bin"), "pip3")
        
        if not os.isfile(python3_bin) then
            raise("python3 not found in python3 package")
        end
        
        -- Install PyOCD using the package's pip
        print("Installing PyOCD using package Python...")
        local install_ok = try { function()
            os.vrunv(pip3_bin, {"install", "pyocd==0.34.2"})
            return true
        end }
        
        if not install_ok then
            raise("Failed to install PyOCD via pip")
        end
        
        -- Create wrapper script that uses the package's python environment
        os.mkdir(package:installdir("bin"))
        local pyocd_script = path.join(package:installdir("bin"), "pyocd")
        
        -- Find where pyocd was installed
        local python3_venv = path.join(python3_pkg:installdir(), "venv")
        local pyocd_bin = nil
        
        if is_host("windows") then
            pyocd_bin = path.join(python3_venv, "Scripts", "pyocd.exe")
            io.writefile(pyocd_script .. ".bat", string.format([[
@echo off
"%s" %%*
]], pyocd_bin))
        else
            pyocd_bin = path.join(python3_venv, "bin", "pyocd")
            io.writefile(pyocd_script, string.format([[#!/bin/sh
exec "%s" "$@"
]], pyocd_bin))
            os.runv("chmod", {"+x", pyocd_script})
        end
        
        -- Verify PyOCD was installed correctly
        if not os.isfile(pyocd_bin) then
            raise("PyOCD binary not found after installation: " .. pyocd_bin)
        end
        
        -- Verify PyOCD works
        print("Verifying PyOCD installation...")
        local verify_ok = try { function()
            os.vrunv(pyocd_bin, {"--version"})
            return true
        end }
        
        if not verify_ok then
            raise("PyOCD installed but not functional. This may indicate missing dependencies.")
        end
        
        -- Add to PATH
        package:addenv("PATH", "bin")
        
        print("PyOCD package installed successfully")
    end)
    
    on_load(function (package)
        -- Prioritize package's pyocd over system pyocd
        package:addenv("PATH", "bin")
    end)
    
    on_test(function (package)
        -- Test using the package's pyocd
        local pyocd_bin = path.join(package:installdir("bin"), "pyocd")
        if os.isfile(pyocd_bin) then
            os.vrun(pyocd_bin, {"--version"})
        else
            os.vrun("pyocd", {"--version"})
        end
    end)