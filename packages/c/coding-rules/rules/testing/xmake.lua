-- Testing automation rule
-- This rule configures testing frameworks and sanitizers for embedded development

rule("coding.test")
    
    -- Configure test settings when rule is loaded
    on_config(function (target)
        -- Set test mode flag
        target:set("coding_test_mode", true)
        
        -- Enable debug symbols for better error reporting
        target:set("symbols", "debug")
        
        -- Get sanitizers configuration
        local sanitizers = target:get("testing.sanitizers")
        if sanitizers then
            -- Configure sanitizers for host testing only
            if not target:is("cross") then
                local san_flags = {}
                
                for _, san in ipairs(sanitizers) do
                    if san == "address" then
                        table.insert(san_flags, "-fsanitize=address")
                        table.insert(san_flags, "-fno-omit-frame-pointer")
                    elseif san == "undefined" then
                        table.insert(san_flags, "-fsanitize=undefined")
                    elseif san == "thread" then
                        table.insert(san_flags, "-fsanitize=thread")
                    elseif san == "memory" then
                        table.insert(san_flags, "-fsanitize=memory")
                    end
                end
                
                if #san_flags > 0 then
                    target:add("cxflags", san_flags)
                    target:add("ldflags", san_flags)
                    print("Enabled sanitizers: " .. table.concat(sanitizers, ", "))
                end
            else
                print("Warning: Sanitizers not available for cross-compilation targets")
            end
        end
        
        -- Enable additional warnings for test builds
        target:add("cxflags", {
            "-Wall",
            "-Wextra",
            "-Wpedantic",
            "-Werror"
        })
        
        -- Define TEST_BUILD macro
        target:add("defines", "TEST_BUILD")
    end)
    
    -- Add test execution support
    after_build(function (target)
        if not target:get("coding_test_mode") then
            return
        end
        
        -- Skip test execution for cross-compilation
        if target:is("cross") then
            print("Skipping test execution for cross-compilation target: " .. target:name())
            return
        end
        
        -- Check if this is a test executable
        if target:kind() == "binary" and (target:name():find("test") or target:name():find("Test")) then
            print("Test target built: " .. target:name())
            print("Run with: xmake run " .. target:name())
        end
    end)
    
    -- Hook into the run command for test targets
    on_run(function (target)
        if not target:get("coding_test_mode") then
            return
        end
        
        print("=== Running tests for: " .. target:name() .. " ===")
        
        -- Set up test environment variables
        local envs = {}
        
        -- Enable sanitizer options
        local sanitizers = target:get("testing.sanitizers")
        if sanitizers then
            for _, san in ipairs(sanitizers) do
                if san == "address" then
                    envs["ASAN_OPTIONS"] = "detect_leaks=1:halt_on_error=1:print_stats=1"
                elseif san == "undefined" then
                    envs["UBSAN_OPTIONS"] = "print_stacktrace=1:halt_on_error=1"
                elseif san == "thread" then
                    envs["TSAN_OPTIONS"] = "halt_on_error=1"
                elseif san == "memory" then
                    envs["MSAN_OPTIONS"] = "halt_on_error=1"
                end
            end
        end
        
        -- Run the test with environment
        os.execv(target:targetfile(), {}, {envs = envs})
    end)
rule_end()

-- Rule for test coverage analysis
rule("coding.test.coverage")
    add_deps("coding.test")
    
    on_config(function (target)
        -- Enable coverage flags
        if target:is("clang") then
            target:add("cxflags", {
                "-fprofile-instr-generate",
                "-fcoverage-mapping"
            })
            target:add("ldflags", {
                "-fprofile-instr-generate",
                "-fcoverage-mapping"
            })
        elseif target:is("gcc") then
            target:add("cxflags", {
                "--coverage",
                "-fprofile-arcs",
                "-ftest-coverage"
            })
            target:add("ldflags", "--coverage")
        end
        
        target:set("coding_coverage_enabled", true)
    end)
    
    after_run(function (target)
        if not target:get("coding_coverage_enabled") then
            return
        end
        
        print("=== Generating coverage report ===")
        
        import("lib.detect.find_program")
        
        if target:is("clang") then
            local llvm_profdata = find_program("llvm-profdata")
            local llvm_cov = find_program("llvm-cov")
            
            if llvm_profdata and llvm_cov then
                -- Merge raw profile data
                os.execv(llvm_profdata, {
                    "merge",
                    "-sparse",
                    "default.profraw",
                    "-o",
                    "default.profdata"
                })
                
                -- Generate coverage report
                os.execv(llvm_cov, {
                    "show",
                    target:targetfile(),
                    "-instr-profile=default.profdata",
                    "-show-line-counts-or-regions",
                    "-output-dir=coverage_report"
                })
                
                print("Coverage report generated in: coverage_report/")
            else
                print("Warning: llvm-profdata or llvm-cov not found")
            end
        elseif target:is("gcc") then
            local gcov = find_program("gcov")
            if gcov then
                -- Run gcov on source files
                for _, sourcefile in ipairs(target:sourcefiles()) do
                    os.execv(gcov, {sourcefile})
                end
                print("Coverage files (*.gcov) generated")
            else
                print("Warning: gcov not found")
            end
        end
    end)
rule_end()
