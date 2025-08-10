--!ARM Embedded Hardware Test Rule
--
-- Rule for creating embedded tests that run on actual hardware or simulators
--

rule("embedded.test")
    -- Inherit from embedded rule
    add_deps("embedded")
    
    on_load(function(target)
        -- Mark as test target
        target:set("group", "test")
        
        -- Don't build by default
        if target:get("default") == nil then
            target:set("default", false)
        end
        
        -- Mark as embedded test
        target:data_set("is_embedded_test", true)
        
        -- Add test framework support
        local test_framework = target:values("embedded.test_framework")
        if test_framework == "unity" then
            -- Unity is lightweight and suitable for embedded
            target:add("defines", "UNITY_INCLUDE_CONFIG_H")
        elseif test_framework == "minunit" then
            -- Minimal unit testing
            target:add("defines", "MINUNIT_TESTS")
        end
    end)
    
    on_run(function(target)
        import("core.project.task")
        
        local test_mode = target:values("embedded.test_mode") or "hardware"
        
        if test_mode == "hardware" then
            -- Flash to hardware and monitor output
            print("Running embedded test on hardware: " .. target:name())
            
            -- Flash the test binary
            task.run("flash", {target = target:name()})
            
            -- Monitor serial output for test results
            local serial_port = target:values("embedded.test_serial")
            local baudrate = target:values("embedded.test_baudrate") or 115200
            local timeout = target:values("embedded.test_timeout") or 30
            
            if serial_port then
                print("Monitoring serial port " .. serial_port .. " @ " .. baudrate .. " baud")
                -- Simple serial monitor (would need pyserial or similar)
                local monitor_cmd = string.format([[
                    python3 -c "
import serial
import sys
import time

ser = serial.Serial('%s', %d, timeout=%d)
start_time = time.time()
test_passed = False

while time.time() - start_time < %d:
    if ser.in_waiting:
        line = ser.readline().decode('utf-8').strip()
        print(line)
        if 'TESTS PASSED' in line:
            test_passed = True
            break
        elif 'TESTS FAILED' in line:
            sys.exit(1)

if not test_passed:
    print('Test timeout')
    sys.exit(1)
"
                ]], serial_port, baudrate, timeout, timeout)
                
                local ok = try { function()
                    os.exec(monitor_cmd)
                    return true
                end }
                
                if not ok then
                    raise("Embedded test failed")
                end
            else
                print("Warning: No serial port specified for test monitoring")
                print("Test flashed successfully, but results cannot be verified")
            end
            
        elseif test_mode == "qemu" then
            -- Run in QEMU emulator
            print("Running embedded test in QEMU: " .. target:name())
            
            local mcu = target:values("embedded.mcu")
            local qemu_machine = get_qemu_machine_for_mcu(mcu)
            
            if not qemu_machine then
                raise("QEMU does not support MCU: " .. (mcu and mcu[1] or "unknown"))
            end
            
            local qemu_cmd = string.format(
                "qemu-system-arm -M %s -nographic -kernel %s -semihosting",
                qemu_machine,
                target:targetfile()
            )
            
            print("QEMU command: " .. qemu_cmd)
            os.exec(qemu_cmd)
            
        elseif test_mode == "renode" then
            -- Run in Renode emulator
            print("Running embedded test in Renode: " .. target:name())
            
            local renode_script = target:values("embedded.test_renode_script")
            if not renode_script then
                raise("Renode script not specified")
            end
            
            os.exec("renode " .. renode_script)
            
        else
            raise("Unknown embedded test mode: " .. test_mode)
        end
    end)
    
    -- Helper function to map MCU to QEMU machine
    function get_qemu_machine_for_mcu(mcu)
        local mcu_name = mcu and (type(mcu) == "table" and mcu[1] or mcu) or ""
        
        -- Common mappings
        local qemu_machines = {
            ["stm32f407vg"] = "netduinoplus2",
            ["stm32f405rg"] = "netduino2",
            ["stm32f103c8"] = "stm32vldiscovery",
            ["lpc1768"] = "lpc1768",
            ["nrf52832"] = "microbit",
            ["nrf52840"] = "microbit-v2"
        }
        
        return qemu_machines[mcu_name:lower()]
    end
    
    before_build(function(target)
        -- Add test-specific defines
        target:add("defines", "EMBEDDED_TEST")
        
        -- Configure test output method
        local output_method = target:values("embedded.test_output") or "semihosting"
        
        if output_method == "semihosting" then
            -- ARM semihosting for output
            target:add("defines", "USE_SEMIHOSTING")
            target:add("ldflags", "--specs=rdimon.specs", "-lrdimon")
        elseif output_method == "rtt" then
            -- SEGGER RTT for output
            target:add("defines", "USE_RTT")
        elseif output_method == "uart" then
            -- UART for output
            target:add("defines", "USE_UART_OUTPUT")
        end
        
        -- Add timeout mechanism
        local timeout = target:values("embedded.test_timeout")
        if timeout then
            target:add("defines", "TEST_TIMEOUT_MS=" .. (timeout * 1000))
        end
    end)