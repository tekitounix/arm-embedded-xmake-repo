-- xmake check plugin
-- Comprehensive code quality checks

task("check")
    set_category("plugin")
    set_description("Run comprehensive code quality checks")
    
    on_run(function ()
        import("core.base.option")
        import("core.base.task")
        import("lib.detect.find_program")
        
        print("=== Running comprehensive code quality checks ===")
        print("")
        
        -- Step 1: Format check
        print("Step 1/3: Checking code formatting...")
        local format_ok = true
        local ok, errors = pcall(function()
            -- Run format in dry-run mode by checking with clang-format
            local clang_format = find_program("clang-format")
            if clang_format then
                task.run("format", {verbose = option.get("verbose")})
            else
                print("  ⚠ clang-format not found, skipping format check")
                format_ok = false
            end
        end)
        if not ok then
            print("  ✗ Format check failed: " .. tostring(errors))
            format_ok = false
        elseif format_ok then
            print("  ✓ Format check passed")
        end
        print("")
        
        -- Step 2: Lint check
        print("Step 2/3: Running static analysis...")
        local lint_ok = true
        ok, errors = pcall(function()
            local clang_tidy = find_program("clang-tidy")
            if clang_tidy then
                task.run("lint", {
                    verbose = option.get("verbose"),
                    checks = option.get("checks")
                })
            else
                print("  ⚠ clang-tidy not found, skipping lint check")
                lint_ok = false
            end
        end)
        if not ok then
            print("  ✗ Lint check failed: " .. tostring(errors))
            lint_ok = false
        elseif lint_ok then
            print("  ✓ Lint check passed")
        end
        print("")
        
        -- Step 3: Build check
        print("Step 3/3: Checking build integrity...")
        local build_ok = true
        
        if option.get("full") then
            -- Full build check
            ok, errors = pcall(function()
                -- Clean first
                task.run("clean", {all = true})
                -- Then build
                task.run("build", {
                    verbose = option.get("verbose"),
                    warning = true  -- Enable all warnings
                })
            end)
            if not ok then
                print("  ✗ Build check failed: " .. tostring(errors))
                build_ok = false
            else
                print("  ✓ Build check passed")
            end
        else
            -- Quick build check (just check if configured)
            ok, errors = pcall(function()
                task.run("config", {verbose = option.get("verbose")})
            end)
            if not ok then
                print("  ✗ Configuration check failed: " .. tostring(errors))
                build_ok = false
            else
                print("  ✓ Configuration check passed")
                print("  ℹ Use --full for complete build check")
            end
        end
        print("")
        
        -- Summary
        print("=== Check Summary ===")
        local all_passed = format_ok and lint_ok and build_ok
        
        if all_passed then
            print("✓ All checks passed!")
        else
            print("✗ Some checks failed:")
            if not format_ok then
                print("  - Format check failed")
            end
            if not lint_ok then
                print("  - Lint check failed")
            end
            if not build_ok then
                print("  - Build check failed")
            end
            print("")
            print("Please fix the issues and run 'xmake check' again.")
            
            -- Exit with error code
            os.exit(1)
        end
    end)
    
    set_menu {
        usage = "xmake check [options]",
        description = "Run comprehensive code quality checks",
        options = {
            {'f', "full", "k", nil, "Run full build check (clean + rebuild)"},
            {'c', "checks", "kv", nil, "Specify clang-tidy checks to run"},
            {'v', "verbose", "k", nil, "Show verbose output"}
        }
    }