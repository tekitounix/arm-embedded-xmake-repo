includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.primitive.error", {"packages", "primitive", "error"}, {
    description = "UMI primitive error and status contracts",
    main_header = "umicore/error.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-error",
        tag_prefix = "umi-error-v",
        versions = {
            ["0.3.1"] = "578295a8f761bb64c638a0ecfe5f205cda172d73470b8e576d55e4c708c57f60",
        },
    },
})
