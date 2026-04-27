package("umitest")
    set_homepage("https://github.com/tekitounix/umitest")
    set_description("Zero-macro lightweight test framework for C++23")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umitest/releases/download/v$(version)/umitest-$(version).tar.gz")
    add_versions("dev", "git:../../../../lib/umitest")
    add_versions("0.2.1", "09804c5dfbd15984eef84f09a8298cd26230ff530a74bfb0403945803fd3d2a8")

    on_install(function(package)
        if not os.isdir("include") then
            local subdirs = os.dirs("umitest-*")
            if subdirs and #subdirs > 0 then
                os.cd(subdirs[1])
            end
        end
        os.cp("include", package:installdir())
    end)

    -- on_test: same rationale as umimmio (C++23 deducing-this consumer).
    -- Skip host-side test_snippet to avoid older host-GCC false-negatives.
package_end()
