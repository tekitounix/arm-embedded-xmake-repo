--! HTTP Server Plugin for Embedded Development
--
-- Provides local HTTP server for:
-- - WASM/Web builds
-- - Web-based debugging interfaces
-- - RTT log viewing
-- - Flash file hosting
--

-- Default server configuration
local _default_config = {
    port = 8080,
    host = "localhost",
    root = nil,  -- defaults to build output directory
}

-- Simple HTTP server implementation using Python
local function start_python_server(config)
    local python = os.which("python3") or os.which("python")
    if not python then
        raise("Python not found. Please install Python 3.")
    end
    
    local serve_dir = config.root or path.join(os.projectdir(), "build", "wasm")
    
    if not os.isdir(serve_dir) then
        raise("Serve directory not found: " .. serve_dir)
    end
    
    print(string.format("Starting HTTP server at http://%s:%d", config.host, config.port))
    print("Serving directory: " .. serve_dir)
    print("")
    print("Press Ctrl+C to stop")
    print("")
    
    -- Change to serve directory and start server
    local args = {
        "-m", "http.server",
        tostring(config.port),
        "--bind", config.host
    }
    
    os.cd(serve_dir)
    os.execv(python, args)
end

-- Check if directory has required files
local function check_wasm_build(dir)
    local required_files = {"index.html"}
    local optional_files = {"*.wasm", "*.js"}
    
    local missing = {}
    for _, file in ipairs(required_files) do
        if not os.isfile(path.join(dir, file)) then
            table.insert(missing, file)
        end
    end
    
    if #missing > 0 then
        return false, "Missing required files: " .. table.concat(missing, ", ")
    end
    
    return true, nil
end

-- Build WASM target if needed
local function ensure_wasm_build(target)
    import("core.project.task")
    
    local output_dir = path.join(os.projectdir(), "build", "wasm")
    local index_html = path.join(output_dir, "index.html")
    
    -- Check if we need to build
    if not os.isfile(index_html) then
        print("Building WASM target...")
        
        -- Try to run webhost task first
        local ok = try { function()
            task.run("webhost")
            return true
        end }
        
        if not ok then
            -- Fallback to building the target
            local targetname = target and target:name() or "headless_webhost"
            task.run("build", {target = targetname})
        end
    end
    
    return output_dir
end

-- Main serve task
task("serve")
    set_category("action")
    set_menu {
        usage = "xmake serve [options]",
        description = "Start HTTP server for web/WASM content",
        options = {
            {'p', "port",   "kv", "8080",       "Server port"},
            {'h', "host",   "kv", "localhost",  "Server host/bind address"},
            {'d', "dir",    "kv", nil,          "Directory to serve (default: build/wasm)"},
            {'t', "target", "kv", nil,          "WASM target to build and serve"},
            {nil, "open",   "k",  nil,          "Open browser automatically"},
            {nil, "build",  "k",  nil,          "Force rebuild before serving"},
            {nil, "cors",   "k",  nil,          "Enable CORS headers"},
        }
    }
    
    on_run(function()
        import("core.base.option")
        import("core.project.config")
        import("core.project.project")
        
        config.load()
        
        local serve_config = {
            port = tonumber(option.get("port")) or 8080,
            host = option.get("host") or "localhost",
            root = option.get("dir"),
        }
        
        -- If no directory specified, try to find WASM build
        if not serve_config.root then
            local targetname = option.get("target")
            local target_obj = nil
            
            if targetname then
                target_obj = project.target(targetname)
            else
                -- Look for WASM target
                for _, t in pairs(project.targets()) do
                    local plat = t:plat() or config.plat()
                    if plat == "wasm" then
                        target_obj = t
                        break
                    end
                end
            end
            
            -- Build if needed or forced
            if option.get("build") or not os.isdir(path.join(os.projectdir(), "build", "wasm")) then
                serve_config.root = ensure_wasm_build(target_obj)
            else
                serve_config.root = path.join(os.projectdir(), "build", "wasm")
            end
        end
        
        -- Verify serve directory
        if not os.isdir(serve_config.root) then
            raise("Directory not found: " .. serve_config.root)
        end
        
        -- Check for index.html
        local ok, err = check_wasm_build(serve_config.root)
        if not ok then
            print("Warning: " .. err)
        end
        
        -- Open browser if requested
        if option.get("open") then
            local url = string.format("http://%s:%d", serve_config.host, serve_config.port)
            
            os.runv(is_host("macosx") and "open" or 
                   (is_host("linux") and "xdg-open" or "start"),
                   {url})
        end
        
        -- Start server
        start_python_server(serve_config)
    end)
task_end()

-- RTT Log viewer server
task("serve.rtt")
    set_category("action")
    set_menu {
        usage = "xmake serve.rtt [options]",
        description = "Start RTT log viewer web interface",
        options = {
            {'p', "port",     "kv", "8081",      "HTTP server port"},
            {nil, "rtt-port", "kv", "19021",     "RTT TCP port from debug server"},
            {nil, "target",   "kv", nil,         "Target for RTT channel configuration"},
        }
    }
    
    on_run(function()
        import("core.base.option")
        
        local http_port = tonumber(option.get("port")) or 8081
        local rtt_port = tonumber(option.get("rtt-port")) or 19021
        
        -- Create RTT viewer HTML
        local html_dir = path.join(os.tmpdir(), "xmake-rtt-viewer")
        os.mkdir(html_dir)
        
        local html_content = [[
<!DOCTYPE html>
<html>
<head>
    <title>RTT Log Viewer</title>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace;
            margin: 0;
            padding: 20px;
            background: #1e1e1e;
            color: #d4d4d4;
        }
        #log {
            background: #0d0d0d;
            padding: 15px;
            border-radius: 8px;
            height: 80vh;
            overflow-y: auto;
            font-family: 'SF Mono', Monaco, Consolas, monospace;
            font-size: 13px;
            line-height: 1.5;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        h1 {
            margin: 0;
            font-size: 20px;
            color: #569cd6;
        }
        .status {
            padding: 5px 12px;
            border-radius: 4px;
            font-size: 12px;
        }
        .status.connected { background: #264f3d; color: #4ec9b0; }
        .status.disconnected { background: #4f2626; color: #f48771; }
        .log-entry { margin: 2px 0; }
        .timestamp { color: #6a9955; }
        .channel { color: #dcdcaa; }
        .controls { display: flex; gap: 10px; }
        button {
            background: #0e639c;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
        }
        button:hover { background: #1177bb; }
    </style>
</head>
<body>
    <div class="header">
        <h1>RTT Log Viewer</h1>
        <div class="controls">
            <button onclick="clearLog()">Clear</button>
            <button onclick="toggleAutoscroll()">Auto-scroll: ON</button>
        </div>
        <span id="status" class="status disconnected">Disconnected</span>
    </div>
    <div id="log"></div>
    <script>
        const log = document.getElementById('log');
        const status = document.getElementById('status');
        let autoscroll = true;
        let ws;
        
        function connect() {
            ws = new WebSocket('ws://localhost:]] .. rtt_port .. [[');
            ws.onopen = () => {
                status.textContent = 'Connected';
                status.className = 'status connected';
            };
            ws.onclose = () => {
                status.textContent = 'Disconnected';
                status.className = 'status disconnected';
                setTimeout(connect, 2000);
            };
            ws.onmessage = (e) => {
                const entry = document.createElement('div');
                entry.className = 'log-entry';
                const time = new Date().toISOString().split('T')[1].slice(0, -1);
                entry.innerHTML = '<span class="timestamp">[' + time + ']</span> ' + e.data;
                log.appendChild(entry);
                if (autoscroll) log.scrollTop = log.scrollHeight;
            };
        }
        
        function clearLog() { log.innerHTML = ''; }
        function toggleAutoscroll() {
            autoscroll = !autoscroll;
            event.target.textContent = 'Auto-scroll: ' + (autoscroll ? 'ON' : 'OFF');
        }
        
        connect();
    </script>
</body>
</html>
]]
        
        local html_file = path.join(html_dir, "index.html")
        io.writefile(html_file, html_content)
        
        print("RTT Log Viewer")
        print(string.format("  HTTP: http://localhost:%d", http_port))
        print(string.format("  RTT:  tcp://localhost:%d", rtt_port))
        print("")
        print("Note: Start your debug server with RTT enabled first.")
        print("Example: xmake debugger --rtt --rtt-port=" .. rtt_port)
        print("")
        
        -- Start HTTP server
        local python = os.which("python3") or os.which("python")
        os.cd(html_dir)
        os.execv(python, {"-m", "http.server", tostring(http_port), "--bind", "localhost"})
    end)
task_end()
