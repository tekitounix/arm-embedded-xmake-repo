-- Tool Registry for ARM Embedded Development (v2)
--
-- Provides unified tool detection with caching across all plugins.
-- Supports: PyOCD, OpenOCD, Renode, GDB, LLDB, J-Link, QEMU
--
-- All public functions are exported as globals (xmake module style)

import("core.base.global")
import("lib.detect.find_tool")

-- Module-level cache
local _cache = {}

-- Tool definitions
local TOOLS = {
    pyocd = {
        names = {"pyocd"},
        package = "pyocd",
        install_hint = "xmake require pyocd"
    },
    openocd = {
        names = {"openocd"},
        package = "openocd",
        install_hint = "xmake require openocd"
    },
    renode = {
        names = {"renode", "Renode"},
        package = "renode",
        paths = {
            "/Applications/Renode.app/Contents/MacOS/renode",  -- macOS app
        },
        install_hint = "xmake require renode"
    },
    ["renode-test"] = {
        names = {"renode-test"},
        package = "renode",
        paths = {
            "/Applications/Renode.app/Contents/MacOS/renode-test",
        },
        install_hint = "xmake require renode"
    },
    jlink = {
        names = {"JLinkExe", "JLink", "jlink"},
        paths = {
            "/opt/SEGGER/JLink/JLinkExe",
            "/Applications/SEGGER/JLink/JLinkExe",
            "C:\\Program Files\\SEGGER\\JLink\\JLink.exe",
            "C:\\Program Files (x86)\\SEGGER\\JLink\\JLink.exe",
        },
        install_hint = "Download from https://www.segger.com/downloads/jlink/"
    },
    ["jlink-gdb-server"] = {
        names = {"JLinkGDBServer", "JLinkGDBServerCLExe"},
        paths = {
            "/opt/SEGGER/JLink/JLinkGDBServer",
            "/Applications/SEGGER/JLink/JLinkGDBServer",
            "C:\\Program Files\\SEGGER\\JLink\\JLinkGDBServerCLExe.exe",
            "C:\\Program Files (x86)\\SEGGER\\JLink\\JLinkGDBServerCLExe.exe",
        },
        install_hint = "Download J-Link from https://www.segger.com/downloads/jlink/"
    },
    qemu = {
        names = {"qemu-system-arm"},
        install_hint = "brew install qemu / apt install qemu-system-arm"
    },
    ["st-util"] = {
        names = {"st-util"},
        install_hint = "brew install stlink / apt install stlink-tools"
    }
}

-- GDB variants for different toolchains
local GDB_VARIANTS = {
    ["gcc-arm"] = {"arm-none-eabi-gdb"},
    ["clang-arm"] = {"lldb", "gdb-multiarch", "arm-none-eabi-gdb"},
    ["default"] = {"gdb"}
}

--- Find tool in xmake package directory
-- @param package_name string Package name
-- @param tool_name string Tool executable name
-- @return table|nil {program = path, source = "package"} or nil
local function find_in_package(package_name, tool_name)
    local package_path = path.join(global.directory(), "packages", package_name:sub(1, 1), package_name)
    if not os.isdir(package_path) then
        return nil
    end
    
    local versions = os.dirs(path.join(package_path, "*"))
    if #versions == 0 then
        return nil
    end
    
    table.sort(versions)
    local latest = versions[#versions]
    local installs = os.dirs(path.join(latest, "*"))
    
    if #installs == 0 then
        return nil
    end
    
    local install_dir = installs[1]
    local tool_bin = path.join(install_dir, "bin", tool_name)
    
    if is_host("windows") then
        -- Try .exe and .bat
        if os.isfile(tool_bin .. ".exe") then
            tool_bin = tool_bin .. ".exe"
        elseif os.isfile(tool_bin .. ".bat") then
            tool_bin = tool_bin .. ".bat"
        end
    end
    
    if os.isfile(tool_bin) then
        return {program = tool_bin, source = "package", installdir = install_dir}
    end
    
    -- Some packages put binaries directly in install dir (e.g., renode)
    tool_bin = path.join(install_dir, tool_name)
    if is_host("windows") then
        if os.isfile(tool_bin .. ".exe") then
            tool_bin = tool_bin .. ".exe"
        end
    end
    
    if os.isfile(tool_bin) then
        return {program = tool_bin, source = "package", installdir = install_dir}
    end
    
    return nil
end

--- Find a tool by name (internal)
-- Searches in: 1) xmake packages, 2) fixed paths, 3) system PATH
-- @param tool_name string Tool identifier (e.g., "pyocd", "openocd", "renode")
-- @return table|nil {program = path, source = "package"|"fixed_path"|"system"} or nil
local function find_tool_internal(tool_name)
    -- Return cached result
    if _cache[tool_name] ~= nil then
        return _cache[tool_name] or nil
    end
    
    local def = TOOLS[tool_name]
    if not def then
        _cache[tool_name] = false
        return nil
    end
    
    -- 1. Check xmake package
    if def.package then
        local pkg_tool = find_in_package(def.package, def.names[1])
        if pkg_tool then
            -- Verify the tool is functional
            local verify_ok = try { function()
                os.vrunv(pkg_tool.program, {"--version"})
                return true
            end }
            
            if verify_ok then
                pkg_tool.source = "package"
                _cache[tool_name] = pkg_tool
                return pkg_tool
            end
        end
    end
    
    -- 2. Check fixed paths
    if def.paths then
        for _, p in ipairs(def.paths) do
            if os.isfile(p) then
                local result = {program = p, source = "fixed_path"}
                _cache[tool_name] = result
                return result
            end
        end
    end
    
    -- 3. Search in PATH
    for _, name in ipairs(def.names) do
        local found = find_tool(name)
        if found then
            found.source = "system"
            _cache[tool_name] = found
            return found
        end
    end
    
    _cache[tool_name] = false
    return nil
end

--- Require a tool (raises error if not found)
-- @param tool_name string Tool identifier
-- @return table {program = path, source = string}
function require_tool(tool_name)
    local tool = find_tool_internal(tool_name)
    if not tool then
        local def = TOOLS[tool_name]
        local hint = def and def.install_hint or ("Please install " .. tool_name)
        raise(tool_name .. " not found.\n\n" .. hint)
    end
    return tool
end

--- Find PyOCD
-- @return table|nil {program = path} or nil
function find_pyocd()
    return find_tool_internal("pyocd")
end

--- Find OpenOCD
-- @return table|nil {program = path, installdir = dir} or nil
function find_openocd()
    return find_tool_internal("openocd")
end

--- Find Renode
-- @return table|nil {program = path, installdir = dir} or nil
function find_renode()
    return find_tool_internal("renode")
end

--- Find Renode test runner
-- @return table|nil {program = path} or nil
function find_renode_test()
    return find_tool_internal("renode-test")
end

--- Find GDB for the specified toolchain.
-- @param toolchain string "gcc-arm", "clang-arm", or nil for host
-- @return table|nil {program = path, type = "gdb"} or nil
function find_gdb(toolchain)
    toolchain = toolchain or "default"
    local cache_key = "gdb_" .. toolchain
    
    if _cache[cache_key] ~= nil then
        return _cache[cache_key] or nil
    end
    
    local variants = GDB_VARIANTS[toolchain] or GDB_VARIANTS["default"]
    
    for _, gdb_name in ipairs(variants) do
        local gdb = find_tool(gdb_name)
        if gdb then
            gdb.type = gdb_name:find("lldb") and "lldb" or "gdb"
            gdb.toolchain = toolchain
            _cache[cache_key] = gdb
            return gdb
        end
    end
    
    _cache[cache_key] = false
    return nil
end

--- Find LLDB debugger.
-- @return table|nil {program = path, type = "lldb"} or nil
function find_lldb()
    if _cache.lldb ~= nil then
        return _cache.lldb or nil
    end
    
    local lldb = find_tool("lldb")
    if lldb then
        lldb.type = "lldb"
    end
    
    _cache.lldb = lldb or false
    return lldb
end

--- Find the best available debugger for the platform.
-- @param toolchain string|nil Optional toolchain hint
-- @return table|nil Debugger info with {program, type} or nil
function find_debugger(toolchain)
    if toolchain then
        -- Embedded target: use find_gdb with toolchain
        local gdb = find_gdb(toolchain)
        if gdb then
            return gdb
        end
        -- Fallback to lldb for clang-arm
        if toolchain == "clang-arm" then
            local lldb = find_lldb()
            if lldb then
                return lldb
            end
        end
    else
        -- Host target: platform-specific preference
        if is_host("macosx") then
            -- macOS: Prefer LLDB
            local lldb = find_lldb()
            if lldb then
                return lldb
            end
        end
        
        -- Linux/Windows or macOS fallback: Prefer GDB
        local gdb = find_tool("gdb")
        if gdb then
            gdb.type = "gdb"
            return gdb
        end
        
        -- Last resort: try lldb
        local lldb = find_lldb()
        if lldb then
            return lldb
        end
    end
    
    return nil
end

--- Get tool installation hint
-- @param tool_name string Tool identifier
-- @return string Installation hint message
function get_install_hint(tool_name)
    local def = TOOLS[tool_name]
    return def and def.install_hint or ("Please install " .. tool_name)
end

--- Clear the tool cache
function clear_cache()
    _cache = {}
end

--- List all known tools and their status
-- @return table {tool_name = {found = bool, program = path|nil}}
function list_tools()
    local result = {}
    for name, _ in pairs(TOOLS) do
        local tool = find_tool_internal(name)
        result[name] = {
            found = tool ~= nil,
            program = tool and tool.program or nil,
            source = tool and tool.source or nil
        }
    end
    return result
end

