-- Flash task for ARM embedded targets using probe-rs (Phase 4a of probe-rs migration)

task("flash")
    set_category("plugin")
    set_menu {
        usage = "xmake flash [options] [target]",
        description = "Flash ARM embedded target using probe-rs",
        options = {
            {'t', "target", "kv", nil, "Specify target to flash"},
            {'d', "device", "kv", nil, "Override target device (e.g., stm32f407vg)"},
            {'f', "frequency", "kv", nil, "Set SWD clock frequency in kHz (e.g., 4000)"},
            {'e', "erase", "k", nil, "Perform chip erase before programming"},
            {'r', "reset", "k", nil, "Reset target after programming"},
            {'n', "no-reset", "k", nil, "Do not reset target after programming"},
            {'p', "probe", "kv", nil, "Specify debug probe to use (VID:PID[:SERIAL])"},
            {nil, "protocol", "kv", "swd", "Wire protocol (swd or jtag, default swd)"}
        }
    }

    on_run(function()
        import("core.base.option")
        import("core.project.project")
        import("core.project.config")
        import("core.base.json")
        import("core.base.global")
        import("lib.detect.find_tool")

        config.load()

        -- ----- target selection -----
        local targetname = option.get("target")
        local target_obj = nil
        if targetname then
            target_obj = project.target(targetname)
            if not target_obj then
                raise("Target not found: " .. targetname)
            end
        else
            local target_names = {}
            for name, _ in pairs(project.targets()) do
                table.insert(target_names, name)
            end
            table.sort(target_names)
            local default_targets = {}
            for _, name in ipairs(target_names) do
                local t = project.target(name)
                if t:get("default") == true and t:rule("embedded") then
                    table.insert(default_targets, {name = name, target = t})
                end
            end
            if #default_targets > 0 then
                if #default_targets > 1 then
                    local names = {}
                    for _, t in ipairs(default_targets) do
                        table.insert(names, t.name)
                    end
                    print(string.format("Warning: Multiple default targets found: %s",
                        table.concat(names, ", ")))
                    print("Using first target alphabetically: " .. default_targets[1].name)
                end
                target_obj = default_targets[1].target
            end
            if not target_obj then
                for _, t in pairs(project.targets()) do
                    if t:rule("embedded") then
                        target_obj = t
                        break
                    end
                end
            end
            if not target_obj then
                raise("No embedded target found. Please specify a target.")
            end
        end

        print("=> Using target: %s", target_obj:name())

        -- ----- locate built ELF (build it first if missing) -----
        local targetfile = target_obj:targetfile()
        if not targetfile or not os.isfile(targetfile) then
            print("=> Building target: %s", target_obj:name())
            os.execv("xmake", {"build", target_obj:name()})
        else
            local sourcefiles = target_obj:sourcefiles()
            local need_rebuild = false
            for _, sourcefile in ipairs(sourcefiles) do
                if os.mtime(sourcefile) > os.mtime(targetfile) then
                    need_rebuild = true
                    break
                end
            end
            if need_rebuild then
                print("=> Rebuilding target: %s (source files changed)", target_obj:name())
                os.execv("xmake", {"build", target_obj:name()})
            else
                print("=> Target is up-to-date: %s", target_obj:name())
            end
        end

        targetfile = target_obj:targetfile()
        if not targetfile or not os.isfile(targetfile) then
            raise("Target ELF file not found. Make sure the target was built successfully.")
        end

        -- ----- load chip database -----
        local plugin_dir = path.join(global.directory(), "plugins", "flash")
        local database_dir = path.join(plugin_dir, "database")
        local flash_config = json.loadfile(path.join(database_dir, "flash-targets.json"))
        if not flash_config then
            raise("Failed to load flash plugin database/flash-targets.json")
        end

        local function first_value(value)
            if type(value) == "table" then
                return value[1]
            end
            return value
        end

        local function resolve_device(target)
            local device = option.get("device")
            if device then
                return device
            end
            device = first_value(target:data("embedded.mcu"))
            if device then
                return device
            end
            device = first_value(target:values("embedded.mcu"))
            if device then
                return device
            end
            local ctx = target:data("umi.ctx")
            if ctx and ctx.board then
                return ctx.board.mcu
            end
            return nil
        end

        local device = resolve_device(target_obj)
        if not device then
            raise([[
No target device specified. Please specify the device using one of:

1. In your xmake.lua:
   set_values("embedded.mcu", "stm32f407vg")

   Or, for umi.target:
   set_values("umi.platform", "st/stm32f4-disco")

2. Via command line:
   $ xmake flash -d stm32f407vg

For the full list of probe-rs chip names, run:
$ probe-rs chip list
]])
        end

        local original_device = device
        if flash_config.FLASH_TARGETS.target_aliases.aliases[device] then
            device = flash_config.FLASH_TARGETS.target_aliases.aliases[device]
            print("=> Using target alias: %s -> %s", original_device, device)
        end

        -- Resolve probe-rs chip name. Walk both `builtin` and `pack_required`
        -- (legacy key kept for backwards-compat; probe-rs needs no packs).
        local chip = nil
        for _, group in ipairs({"builtin", "pack_required"}) do
            local entries = flash_config.FLASH_TARGETS[group].targets
            if entries[device] and entries[device].probe_rs_chip then
                chip = entries[device].probe_rs_chip
                break
            end
        end
        if not chip then
            raise(string.format([[
error: device '%s' has no `probe_rs_chip` entry in flash-targets.json

probe-rs identifies the chip via the names listed by `probe-rs chip list`.
Add a `probe_rs_chip` field to the matching entry in
plugins/flash/database/flash-targets.json, or pass an explicit
`-d <chip>` argument that maps to such an entry.
]], device))
        end

        -- ----- locate probe-rs binary -----
        local probe_rs = find_tool("probe-rs")
        if not probe_rs then
            raise([[
error: probe-rs not found on PATH

The flash task uses the probe-rs CLI (https://probe.rs/) instead of
PyOCD since Phase 4 of the probe-rs migration. Make probe-rs available
by entering the Nix dev shell (`nix develop` or `direnv allow`) so
`pkgs.probe-rs-tools` is on PATH, or install it manually via
`cargo install probe-rs-tools`.
]])
        end
        print("Using probe-rs: " .. probe_rs.program)

        -- ----- build probe-rs argv -----
        local download_args = {"download", "--chip", chip,
                               "--protocol", option.get("protocol") or "swd",
                               "--verify", "--disable-progressbars"}
        local reset_args = {"reset", "--chip", chip,
                            "--protocol", option.get("protocol") or "swd"}

        local frequency = option.get("frequency")
        if frequency then
            -- probe-rs accepts kHz integers; pyOCD-style "1M/4M" suffixes also handled
            local norm = frequency
            local kHz = tonumber(norm)
            if not kHz then
                local mhz_str = norm:lower():match("^(%d+%.?%d*)m$")
                if mhz_str then
                    kHz = tostring(tonumber(mhz_str) * 1000)
                end
            end
            if not kHz then
                raise("invalid --frequency value: " .. frequency .. " (use kHz integer or e.g. 4M)")
            end
            table.insert(download_args, "--speed")
            table.insert(download_args, tostring(kHz))
            table.insert(reset_args, "--speed")
            table.insert(reset_args, tostring(kHz))
        end

        local probe = option.get("probe") or first_value(target_obj:values("embedded.probe"))
        if probe then
            table.insert(download_args, "--probe")
            table.insert(download_args, probe)
            table.insert(reset_args, "--probe")
            table.insert(reset_args, probe)
            print("=> Using probe: %s", probe)
        else
            print("=> No probe specified; probe-rs will auto-select if exactly one is attached.")
        end

        if option.get("erase") then
            -- probe-rs `download` runs a chip-mass-erase when configured with the
            -- target's `chip-mass-erase` flag; passing it explicitly via the CLI
            -- is the user's intent here.
            table.insert(download_args, "--allow-erase-all")
        end

        table.insert(download_args, targetfile)

        -- ----- execute -----
        local filesize = os.filesize(targetfile)
        local filesize_kb = math.floor(filesize / 1024)
        print("=> Flashing %s (%d KB) to %s (chip=%s)",
              path.filename(targetfile), filesize_kb, device, chip)

        local ok = os.execv(probe_rs.program, download_args)
        local exitcode = ok and 0 or 1
        if exitcode ~= 0 then
            print("")
            print("error: probe-rs download failed (exit code: " .. tostring(exitcode) .. ")")
            print("")
            print("Troubleshooting:")
            print("1. Run `probe-rs list` and verify the probe enumerates.")
            print("2. Confirm `probe-rs chip list` contains '" .. chip .. "'.")
            print("3. Check the probe / target wiring and power supply.")
            print("4. For diagnostics: probe-rs download --chip " .. chip .. " " .. targetfile)
            os.exit(1)
        end

        -- ----- reset behavior -----
        if option.get("no-reset") then
            print("=> Flash completed (target left halted, --no-reset).")
        else
            local reset_ok = os.execv(probe_rs.program, reset_args)
            if not reset_ok then
                print("warning: probe-rs reset returned non-zero, continuing.")
            end
            print("=> Flash and reset completed successfully")
        end
    end)
