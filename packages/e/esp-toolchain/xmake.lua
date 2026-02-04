package("esp-toolchain")
    set_kind("toolchain")
    set_homepage("https://github.com/espressif/esp-idf")
    set_description("ESP32 toolchain for Xtensa and RISC-V targets")
    
    -- Supported versions
    add_versions("5.3", "latest")
    add_versions("5.2.1", "5.2.1")
    add_versions("5.1.2", "5.1.2")
    add_versions("5.0.4", "5.0.4")
    
    -- Configuration options
    add_configs("arch", {description = "Target architecture", default = "xtensa", values = {"xtensa", "riscv32"}})
    add_configs("variant", {description = "ESP32 variant", default = "esp32", values = {"esp32", "esp32s2", "esp32s3", "esp32c2", "esp32c3", "esp32c5", "esp32c6", "esp32h2", "esp32p4"}})
    add_configs("idf_path", {description = "Custom ESP-IDF path", default = nil})
    
    -- Map variants to architectures
    local variant_arch_map = {
        esp32   = "xtensa",
        esp32s2 = "xtensa",
        esp32s3 = "xtensa",
        esp32c2 = "riscv32",
        esp32c3 = "riscv32",
        esp32c5 = "riscv32",
        esp32c6 = "riscv32",
        esp32h2 = "riscv32",
        esp32p4 = "riscv32",
    }
    
    on_check(function(package)
        -- Check if espup is available (preferred installation method)
        local espup = os.which("espup")
        
        -- Check for existing ESP-IDF installation
        local idf_path = package:config("idf_path") or os.getenv("IDF_PATH")
        
        if espup or (idf_path and os.isdir(idf_path)) then
            return true
        end
        
        return false
    end)
    
    on_load(function(package)
        -- Determine architecture from variant
        local variant = package:config("variant")
        local arch = variant_arch_map[variant] or package:config("arch")
        package:set("arch", arch)
        
        -- Set toolchain prefix based on architecture
        if arch == "xtensa" then
            package:set("toolchain_prefix", "xtensa-" .. variant .. "-elf-")
        else
            package:set("toolchain_prefix", "riscv32-esp-elf-")
        end
    end)
    
    on_install("linux", "macosx", "windows", function(package)
        local variant = package:config("variant")
        local arch = variant_arch_map[variant] or package:config("arch")
        
        -- Check for espup (Espressif toolchain manager)
        local espup = os.which("espup")
        
        if not espup then
            print("Installing espup (ESP toolchain manager)...")
            
            if is_host("windows") then
                os.runv("winget", {"install", "Espressif.Espup"})
            elseif is_host("macosx") then
                -- Try brew first
                local brew = os.which("brew")
                if brew then
                    os.runv("brew", {"install", "espup"})
                else
                    -- Use cargo
                    os.runv("cargo", {"install", "espup"})
                end
            else
                -- Linux: use cargo
                os.runv("cargo", {"install", "espup"})
            end
            
            espup = os.which("espup")
            if not espup then
                raise("Failed to install espup")
            end
        end
        
        -- Install toolchain with espup
        print("Installing ESP toolchain for " .. variant .. "...")
        
        local espup_args = {"install", "--targets", variant}
        
        -- Nightly channel for latest version
        local version = package:version_str()
        if version ~= "latest" then
            table.insert(espup_args, "--esp-idf-version")
            table.insert(espup_args, version)
        end
        
        os.runv(espup, espup_args)
        
        -- Export environment
        print("Exporting ESP toolchain environment...")
        
        local export_file
        if is_host("windows") then
            export_file = path.join(os.getenv("USERPROFILE"), "export-esp.ps1")
            if os.isfile(export_file) then
                -- Source PowerShell export
                -- Note: This sets environment for subsequent commands
            end
        else
            export_file = path.join(os.getenv("HOME"), "export-esp.sh")
            if os.isfile(export_file) then
                -- Parse and apply environment variables
                local content = io.readfile(export_file)
                for name, value in content:gmatch("export ([%w_]+)=(.-)[\n;]") do
                    os.setenv(name, value:gsub('"', ''))
                end
            end
        end
        
        -- Verify installation
        local toolchain_prefix = package:get("toolchain_prefix")
        local cc = os.which(toolchain_prefix .. "gcc")
        
        if not cc then
            raise("ESP toolchain installation failed. " .. toolchain_prefix .. "gcc not found in PATH")
        end
        
        print("ESP toolchain installed successfully")
        package:set("installdir", path.directory(path.directory(cc)))
    end)
    
    on_fetch(function(package)
        local toolchain_prefix = package:get("toolchain_prefix") or "xtensa-esp32-elf-"
        
        -- Find gcc from toolchain
        local gcc = os.which(toolchain_prefix .. "gcc")
        
        if not gcc then
            -- Try common installation paths
            local search_paths = {}
            
            if is_host("windows") then
                table.insert(search_paths, path.join(os.getenv("USERPROFILE"), ".espressif", "tools"))
            else
                table.insert(search_paths, path.join(os.getenv("HOME"), ".espressif", "tools"))
            end
            
            -- Search for toolchain
            for _, search_path in ipairs(search_paths) do
                if os.isdir(search_path) then
                    local found = find_path(toolchain_prefix .. "gcc", search_path, {suffixes = {"bin"}})
                    if found then
                        gcc = found
                        break
                    end
                end
            end
        end
        
        if not gcc then
            return nil
        end
        
        local bindir = path.directory(gcc)
        local sdkdir = path.directory(bindir)
        
        return {
            bindir = bindir,
            sdkdir = sdkdir,
            cc = gcc,
            cxx = path.join(bindir, toolchain_prefix .. "g++"),
            ar = path.join(bindir, toolchain_prefix .. "ar"),
            ld = path.join(bindir, toolchain_prefix .. "ld"),
            objcopy = path.join(bindir, toolchain_prefix .. "objcopy"),
            objdump = path.join(bindir, toolchain_prefix .. "objdump"),
            size = path.join(bindir, toolchain_prefix .. "size"),
            gdb = path.join(bindir, toolchain_prefix .. "gdb"),
        }
    end)
package_end()
