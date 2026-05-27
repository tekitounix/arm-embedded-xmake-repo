includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umidbg", {"packages", "support", "debug"}, {
    description = "UMI low-overhead debug counters and instrumentation",
    main_header = "umidbg/dbg.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-debug",
        tag_prefix = "umi-debug-v",
        versions = {
            ["0.3.1"] = "679a0bd27368c6d02903d7587af754d2e70ba7b2ee00d69545a007ed97780b22",
        },
    },
})
