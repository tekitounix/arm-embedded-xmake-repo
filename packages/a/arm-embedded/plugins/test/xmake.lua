--!Test Runner Task
--
-- Discovers and runs all test targets
--

task("test")
    set_category("action")
    
    on_run(function()
        import("core.base.option")
        import("core.project.config")
        import("core.project.project")
        import("core.project.task")
        import("core.base.colors")
        
        -- Parse command line options
        local opt = {}
        opt.group = option.get("group")
        opt.pattern = option.get("pattern")
        opt.verbose = option.get("verbose")
        
        -- Load project configuration
        config.load()
        
        -- Collect test targets
        local test_targets = {}
        for _, target in pairs(project.targets()) do
            local is_test = false
            
            -- Check if it's a test target
            if target:get("group") == "test" or 
               target:data("is_test") or 
               target:data("is_embedded_test") or
               target:rule("host.test") or 
               target:rule("embedded.test") then
                is_test = true
            end
            
            -- Apply filters
            if is_test then
                if opt.group and target:get("group") ~= opt.group then
                    is_test = false
                elseif opt.pattern and not target:name():match(opt.pattern) then
                    is_test = false
                end
            end
            
            if is_test then
                table.insert(test_targets, target)
            end
        end
        
        if #test_targets == 0 then
            print("No test targets found")
            return
        end
        
        print("Found %d test target(s)", #test_targets)
        print("")
        
        -- Build all test targets first
        local build_targets = {}
        for _, target in ipairs(test_targets) do
            table.insert(build_targets, target:name())
        end
        
        print("Building test targets...")
        task.run("build", {target = build_targets})
        print("")
        
        -- Run tests
        local total_tests = #test_targets
        local passed_tests = 0
        local failed_tests = 0
        local skipped_tests = 0
        
        for i, target in ipairs(test_targets) do
            local test_type = target:data("is_embedded_test") and "embedded" or "host"
            print(colors.bright .. string.format("[%d/%d] Running %s test: %s", 
                i, total_tests, test_type, target:name()) .. colors.reset)
            
            -- Check if test can run
            local can_run = true
            if test_type == "embedded" then
                local test_mode = target:values("embedded.test_mode") or "hardware"
                if test_mode == "hardware" and not target:values("embedded.test_serial") then
                    print(colors.yellow .. "  ⚠ Skipped: No serial port configured for hardware test" .. colors.reset)
                    can_run = false
                    skipped_tests = skipped_tests + 1
                end
            end
            
            if can_run then
                local ok = try {
                    function()
                        -- Run the test target
                        os.cd(project.directory())
                        task.run("run", {target = target:name()})
                        return true
                    end,
                    catch {
                        function(errors)
                            if opt.verbose and errors then
                                print(colors.red .. "  Error: " .. tostring(errors) .. colors.reset)
                            end
                            return false
                        end
                    }
                }
                
                if ok then
                    print(colors.green .. "  ✓ PASSED" .. colors.reset)
                    passed_tests = passed_tests + 1
                else
                    print(colors.red .. "  ✗ FAILED" .. colors.reset)
                    failed_tests = failed_tests + 1
                end
            end
            
            print("")
        end
        
        -- Summary
        print(string.rep("=", 60))
        print("Test Summary:")
        print(string.format("  Total:   %d", total_tests))
        print(colors.green .. string.format("  Passed:  %d", passed_tests) .. colors.reset)
        if failed_tests > 0 then
            print(colors.red .. string.format("  Failed:  %d", failed_tests) .. colors.reset)
        end
        if skipped_tests > 0 then
            print(colors.yellow .. string.format("  Skipped: %d", skipped_tests) .. colors.reset)
        end
        print(string.rep("=", 60))
        
        -- Exit with error if tests failed
        if failed_tests > 0 then
            raise("Tests failed: %d", failed_tests)
        end
    end)
    
    -- Define menu
    set_menu {
        usage = "xmake test [options] [target]",
        description = "Run all test targets",
        options = {
            {'g', "group",     "kv", nil, "Run tests from specific group"},
            {'p', "pattern",   "kv", nil, "Run tests matching pattern"},
            {'v', "verbose",   "k",  nil, "Show verbose output"},
            {},
            {nil, "target",    "v",  nil, "Run specific test target"}
        }
    }