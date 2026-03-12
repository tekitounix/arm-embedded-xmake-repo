package("umitest")
    set_homepage("https://github.com/tekitounix/umitest")
    set_description("Zero-macro lightweight test framework for C++23")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umitest/releases/download/v$(version)/umitest-$(version).tar.gz")
    add_versions("dev", "git:../../../../lib/umitest")
    add_versions("0.3.1", "7a264c81ea207c4ff593f6d0711b4a8db55f27b622107e236d7e0f64604b8e0b")

    on_install(function(package)
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
