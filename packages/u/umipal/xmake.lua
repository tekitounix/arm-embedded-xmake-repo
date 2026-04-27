-- umipal: MCU Peripheral Access Layer generator + per-target manifests.
-- Provides public C++ headers under `include/umipal/` plus target manifest
-- JSONs under `share/target-manifest/<vendor>/<family>/<target>.json` consumed
-- by the synthernet `embedded` rule's 3-tier MCU lookup (manifest → mcu-local
-- → mcu-database).

package("umipal")
    set_homepage("https://github.com/tekitounix/umipal")
    set_description("MCU Peripheral Access Layer + per-target manifests")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umipal/releases/download/v$(version)/umipal-$(version).tar.gz")
    -- `dev` version pulls the sibling checkout for local iteration; the first
    -- tagged release will register the SHA256 alongside.
    add_versions("dev", "git:../../../../../../umipal")

    -- umipal headers include <umimmio/...> — the consumer pkg graph must see
    -- umimmio for compilation.
    add_deps("umimmio")

    on_install(function(package)
        -- Public headers (C++ API surface).
        os.cp("include", package:installdir())
        -- Target manifests (consumed by embedded rule's load_mcu_database()).
        if os.isdir("share/target-manifest") then
            os.cp("share/target-manifest", path.join(package:installdir(), "share"))
        end
    end)

    on_test(function(package)
        assert(package:check_cxxsnippets({test = [[
            #include <umipal/vendor/st/stm32f4/stm32f4.hh>
            void test() {}
        ]]}, {configs = {languages = "c++23"}}))
    end)
package_end()
