package("umitest")
    set_homepage("https://github.com/tekitounix/umitest")
    set_description("Zero-macro lightweight test framework for C++23")
    set_license("MIT")

    set_kind("library", {headeronly = true})

    add_urls("https://github.com/tekitounix/umitest/releases/download/v$(version)/umitest-$(version).tar.gz")
    add_versions("dev", "git:../../../../lib/umitest")
    add_versions("0.2.0", "a0253b522bd0ab2e88d686eb0eada48ada3f76065efc26886b615ef8b9c86337")

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
