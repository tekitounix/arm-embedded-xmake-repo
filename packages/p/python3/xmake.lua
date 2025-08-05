package("python3")
    set_kind("binary")
    set_description("The Python programming language")
    set_homepage("https://www.python.org/")
    
    -- No download needed - we'll use system Python
    add_versions("3.11.5", "dummy")
    
    -- Disable system fetch to force package installation
    on_fetch(function (package, opt)
        -- Check if package is installed
        if os.isdir(package:installdir()) then
            -- Also check if venv exists
            local venv_dir = package:installdir("venv")
            if not os.isdir(venv_dir) then
                cprint("${yellow}warning: Python3 package found but virtual environment is missing: " .. venv_dir)
                cprint("${yellow}warning: This package needs to be reinstalled")
                cprint("${yellow}To fix this issue, run:")
                cprint("${yellow}  $ xmake require --uninstall python3")
                cprint("${yellow}  $ xmake require --force python3")
                return nil  -- Force reinstallation
            end
            
            -- Check if Python binary exists in venv
            local python_bin = nil
            if is_host("windows") then
                python_bin = path.join(venv_dir, "Scripts", "python.exe")
            else
                python_bin = path.join(venv_dir, "bin", "python3")
            end
            
            if not os.isfile(python_bin) then
                cprint("${yellow}warning: Python3 virtual environment is incomplete: " .. python_bin .. " not found")
                cprint("${yellow}To fix this issue, run:")
                cprint("${yellow}  $ xmake require --uninstall python3")
                cprint("${yellow}  $ xmake require --force python3")
                return nil  -- Force reinstallation
            end
            
            return {
                name = package:name(),
                version = package:version_str(),
                installdir = package:installdir()
            }
        end
        -- Return nil to force installation
        return nil
    end)
    
    on_install("windows", "macosx", "linux", function (package)
        -- For macOS and Linux, we'll use system Python or create a virtual environment
        import("lib.detect.find_tool")
        
        -- Try to find Python 3
        local python = nil
        if is_host("windows") then
            -- On Windows, python.exe is more common than python3.exe
            python = find_tool("python") or find_tool("python3")
        else
            -- On Unix-like systems, python3 is preferred
            python = find_tool("python3") or find_tool("python")
        end
        
        if not python then
            raise("Python3 is required but not found in system")
        end
        
        -- Check Python version
        local output = os.iorunv(python.program, {"--version"})
        if output then
            print("Found Python: " .. output:trim())
        end
        
        -- Create a virtual environment in the package directory
        local venv_dir = package:installdir("venv")
        print("Creating virtual environment at: " .. venv_dir)
        
        local ok = try { function()
            os.vrunv(python.program, {"-m", "venv", venv_dir})
            return true
        end }
        
        if not ok then
            raise("Failed to create Python virtual environment")
        end
        
        -- Verify venv was created
        if not os.isdir(venv_dir) then
            raise("Virtual environment directory was not created: " .. venv_dir)
        end
        
        -- Create wrapper scripts
        local python_bin = nil
        local pip_bin = nil
        
        if is_host("windows") then
            python_bin = path.join(venv_dir, "Scripts", "python.exe")
            pip_bin = path.join(venv_dir, "Scripts", "pip.exe")
        else
            python_bin = path.join(venv_dir, "bin", "python3")
            pip_bin = path.join(venv_dir, "bin", "pip3")
        end
        
        -- Verify Python binaries exist
        if not os.isfile(python_bin) then
            raise("Python binary not found in venv: " .. python_bin)
        end
        if not os.isfile(pip_bin) then
            raise("Pip binary not found in venv: " .. pip_bin)
        end
        
        -- Create bin directory
        os.mkdir(package:installdir("bin"))
        
        -- Create python3 wrapper
        local python3_script = path.join(package:installdir("bin"), "python3")
        if is_host("windows") then
            io.writefile(python3_script .. ".bat", string.format([[
@echo off
"%s" %%*
]], python_bin))
        else
            io.writefile(python3_script, string.format([[#!/bin/sh
exec "%s" "$@"
]], python_bin))
            os.runv("chmod", {"+x", python3_script})
        end
        
        -- Create pip3 wrapper
        local pip3_script = path.join(package:installdir("bin"), "pip3")
        if is_host("windows") then
            io.writefile(pip3_script .. ".bat", string.format([[
@echo off
"%s" %%*
]], pip_bin))
        else
            io.writefile(pip3_script, string.format([[#!/bin/sh
exec "%s" "$@"
]], pip_bin))
            os.runv("chmod", {"+x", pip3_script})
        end
        
        -- Upgrade pip
        print("Upgrading pip...")
        local pip_ok = try { function()
            os.vrunv(pip_bin, {"install", "--upgrade", "pip"})
            return true
        end }
        
        if not pip_ok then
            raise("Failed to upgrade pip")
        end
        
        -- Add to PATH
        package:addenv("PATH", "bin")
        
        print("Python3 package installed successfully")
    end)
    
    on_test(function (package)
        local python3 = path.join(package:installdir("bin"), "python3")
        local pip3 = path.join(package:installdir("bin"), "pip3")
        
        if package:is_plat("windows") then
            python3 = python3 .. ".bat"
            pip3 = pip3 .. ".bat"
        end
        
        os.vrun(python3, {"--version"})
        os.vrun(pip3, {"--version"})
    end)