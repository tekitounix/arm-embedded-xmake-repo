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
            return {
                name = package:name(),
                version = package:version_str(),
                installdir = package:installdir()
            }
        end
        -- Return nil to force installation
        return nil
    end)
    
    on_install("macosx", "linux", function (package)
        -- For macOS and Linux, we'll use system Python or create a virtual environment
        import("lib.detect.find_tool")
        
        -- Try to find Python 3
        local python = find_tool("python3") or find_tool("python")
        if not python then
            raise("Python3 is required but not found in system")
        end
        
        -- Create a virtual environment in the package directory
        local venv_dir = package:installdir("venv")
        os.vrunv(python.program, {"-m", "venv", venv_dir})
        
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
        os.vrunv(pip_bin, {"install", "--upgrade", "pip"})
        
        -- Add to PATH
        package:addenv("PATH", "bin")
    end)
    
    on_test(function (package)
        os.vrun("python3", {"--version"})
        os.vrun("pip3", {"--version"})
    end)