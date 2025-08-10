--!ARM Embedded Host Test Rule
--
-- Rule for creating host-based unit tests with automatic platform detection
--

rule("host.test")
    set_kind("binary")
    
    -- Configure target when rule is loaded
    on_load(function(target)
        -- Automatically set host platform and architecture
        target:set("plat", os.host())
        target:set("arch", os.arch())
        
        -- Mark as test target
        target:set("group", "test")
        
        -- Don't build by default unless explicitly specified
        if target:get("default") == nil then
            target:set("default", false)
        end
        
        -- Set default language standard if not specified
        local languages = target:get("languages")
        if not languages then
            target:set("languages", "c++23")
        end
        
        -- Mark as test for discovery
        target:data_set("is_test", true)
    end)
    
    -- Run the test when invoked
    on_run(function(target)
        import("core.project.depend")
        
        -- Check if rebuild is needed
        depend.on_changed(function()
            -- Dependency check passed, continue
        end, {files = target:targetfile()})
        
        -- Get test runner configuration
        local test_runner = target:values("test.runner")
        local test_args = target:values("test.args") or {}
        local test_env = target:values("test.env") or {}
        
        -- Configure environment variables
        for k, v in pairs(test_env) do
            os.setenv(k, v)
        end
        
        -- Configure test runner specific arguments
        if test_runner == "gtest" then
            -- Google Test arguments
            table.insert(test_args, 1, "--gtest_color=yes")
            if os.getenv("CI") then
                table.insert(test_args, "--gtest_output=xml:test-results.xml")
            end
        elseif test_runner == "catch2" then
            -- Catch2 arguments
            table.insert(test_args, 1, "--use-colour=yes")
            if os.getenv("CI") then
                table.insert(test_args, "--reporter=junit")
                table.insert(test_args, "--out=test-results.xml")
            end
        elseif test_runner == "unity" then
            -- Unity test framework
            -- Unity doesn't need special arguments
        end
        
        -- Run the test
        print("Running test: " .. target:name())
        local ok = try {
            function()
                os.execv(target:targetfile(), test_args)
                return true
            end,
            catch {
                function(errors)
                    print("Test failed: " .. target:name())
                    if errors then
                        print(errors)
                    end
                    return false
                end
            }
        }
        
        -- Handle coverage collection if enabled
        local collect_coverage = target:values("test.coverage")
        if collect_coverage and ok then
            print("Collecting coverage data...")
            local coverage_tool = target:values("test.coverage_tool") or "gcov"
            
            if coverage_tool == "gcov" then
                os.exec("gcov " .. target:objectfiles())
            elseif coverage_tool == "llvm-cov" then
                os.exec("llvm-cov gcov " .. target:objectfiles())
            end
        end
        
        -- Return success/failure
        if not ok then
            raise("Test execution failed")
        end
    end)
    
    -- Configure build flags for test builds
    before_build(function(target)
        -- Add test-specific defines
        target:add("defines", "TESTING")
        
        -- Enable coverage if requested
        if target:values("test.coverage") then
            target:add("cxflags", "--coverage", "-fprofile-arcs", "-ftest-coverage")
            target:add("ldflags", "--coverage", "-fprofile-arcs", "-ftest-coverage")
        end
        
        -- Add sanitizers if requested
        local sanitizers = target:values("test.sanitizers")
        if sanitizers then
            for _, sanitizer in ipairs(sanitizers) do
                target:add("cxflags", "-fsanitize=" .. sanitizer)
                target:add("ldflags", "-fsanitize=" .. sanitizer)
            end
        end
    end)