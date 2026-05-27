includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umicoro", {"packages", "primitive", "coro"}, {
    description = "UMI allocation-free cooperative coroutine primitives",
    main_header = "umicoro/coro.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umicoro",
        tag_prefix = "umicoro-v",
        versions = {
            ["0.3.1"] = "5d7d04072aa243a13d1c41a9d5033795b6f1bc97d50fe6cde7924ea074568966",
        },
    },
})
