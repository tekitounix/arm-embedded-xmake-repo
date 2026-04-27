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

    on_test(function(package)
        assert(package:check_cxxsnippets({test = [[
            #include <umitest/test.hh>
            void test() {
                umi::test::Suite s("pkg_test");
            }
        ]]}, {configs = {languages = "c++23"}}))
    end)
package_end()
