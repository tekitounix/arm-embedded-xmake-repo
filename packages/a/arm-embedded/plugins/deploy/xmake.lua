-- Deploy Plugin
--
-- Unified deployment tasks for WASM/Python bindings output
-- Usage:
--   xmake deploy -t <target> [--dest <dir>]
--   xmake deploy.webhost       (shortcut for headless_webhost)
--   xmake deploy.serve         (build and serve webhost)
--

-- Main deploy task
task("deploy")
    set_category("action")
    set_menu {
        usage = "xmake deploy -t <target> [--dest <dir>]",
        description = "Deploy build artifacts to destination",
        options = {
            {'t', "target", "kv", nil, "Target to deploy"},
            {'d', "dest", "kv", nil, "Destination directory"}
        }
    }
    
    on_run(function ()
        import("core.base.option")
        import("core.project.project")
        import("core.project.config")
        import("lib.detect.find_tool")
        
        -- Helper: find target and copy to destination
        local function deploy_target(target_name, dest_dir)
            local target = project.target(target_name)
            if not target then
                raise("Target not found: " .. target_name)
            end
            
            local targetfile = target:targetfile()
            if not os.isfile(targetfile) then
                raise("Target file not found: " .. targetfile .. "\nBuild the target first: xmake build " .. target_name)
            end
            
            os.mkdir(dest_dir)
            os.cp(targetfile, dest_dir .. "/")
            
            -- For WASM targets, also copy .js file
            local basename = path.basename(targetfile)
            local js_file = path.join(path.directory(targetfile), basename .. ".js")
            if os.isfile(js_file) then
                os.cp(js_file, dest_dir .. "/")
            end
            
            return targetfile
        end
        
        local target_name = option.get("target")
        local dest_dir = option.get("dest")
        
        if not target_name then
            print("Deploy plugin - copy build artifacts to destination")
            print("")
            print("Usage:")
            print("  xmake deploy -t <target> [--dest <dir>]")
            print("")
            print("Shortcuts:")
            print("  xmake deploy.webhost   Deploy headless_webhost to web/")
            print("  xmake deploy.serve     Deploy and start local server")
            print("")
            print("Examples:")
            print("  xmake deploy -t headless_webhost --dest examples/headless_webhost/web")
            print("  xmake deploy -t tb303_waveshaper_py --dest docs/dsp/tb303/vco/test")
            return
        end
        
        -- Load config
        config.load()

        -- Map legacy target alias
        if target_name == "headless_webhost" then
            target_name = "webhost_sim"
        end
        
        -- Build first
        print("Building " .. target_name .. "...")
        os.execv("xmake", {"build", target_name})
        
        -- Default destination based on target
        if not dest_dir then
            if target_name == "webhost_sim" then
                dest_dir = "examples/headless_webhost/web"
            elseif target_name:match("_py$") then
                -- Python bindings: try to find test directory
                dest_dir = "build/python"
            else
                dest_dir = "build/deploy"
            end
        end
        
        local targetfile = deploy_target(target_name, dest_dir)
        
        print("")
        print(string.rep("=", 60))
        print("Deployed: " .. path.filename(targetfile))
        print("To: " .. dest_dir)
        print(string.rep("=", 60))
    end)
task_end()

-- Webhost shortcut
task("deploy.webhost")
    set_category("action")
    set_menu {
        usage = "xmake deploy.webhost",
        description = "Deploy headless web host WASM module"
    }
    
    on_run(function ()
        import("lib.detect.find_tool")

        local emcc = find_tool("emcc")
        if not emcc then
            print("Emscripten not found. Install to build WASM: brew install emscripten")
        end

        print("Building headless web host...")
        os.execv("xmake", {"build", "webhost_sim"})
        
        local dest_dir = "examples/headless_webhost/web"
        os.mkdir(dest_dir)
        if os.isfile("examples/headless_webhost/build/webhost_sim.js") and os.isfile("examples/headless_webhost/build/webhost_sim.wasm") then
            os.cp("examples/headless_webhost/build/webhost_sim.js", dest_dir .. "/")
            os.cp("examples/headless_webhost/build/webhost_sim.wasm", dest_dir .. "/")
        else
            raise("webhost_sim.wasm not found. Ensure Emscripten is installed and build succeeded.")
        end
        
        print("")
        print(string.rep("=", 60))
        print("Web host build complete!")
        print("Output: " .. dest_dir)
        print(string.rep("=", 60))
    end)
task_end()

-- Webhost serve shortcut
task("deploy.serve")
    set_category("action")
    set_menu {
        usage = "xmake deploy.serve",
        description = "Deploy and serve headless web host"
    }
    
    on_run(function ()
        import("lib.detect.find_tool")

        local emcc = find_tool("emcc")
        if not emcc then
            print("Emscripten not found. Install to build WASM: brew install emscripten")
        end

        print("Building headless web host...")
        os.execv("xmake", {"build", "webhost_sim"})
        
        local dest_dir = "examples/headless_webhost/web"
        os.mkdir(dest_dir)
        if os.isfile("examples/headless_webhost/build/webhost_sim.js") and os.isfile("examples/headless_webhost/build/webhost_sim.wasm") then
            os.cp("examples/headless_webhost/build/webhost_sim.js", dest_dir .. "/")
            os.cp("examples/headless_webhost/build/webhost_sim.wasm", dest_dir .. "/")
        else
            raise("webhost_sim.wasm not found. Ensure Emscripten is installed and build succeeded.")
        end
        
        print("")
        print("Starting local server...")
        print("Open: http://localhost:8080/")
        os.exec("cd " .. dest_dir .. " && python3 -m http.server 8080")
    end)
task_end()
