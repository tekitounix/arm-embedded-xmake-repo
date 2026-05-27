includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.primitive.time", {"packages", "primitive", "time"}, {
    description = "UMI primitive time point and duration contracts",
    main_header = "umicore/time.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-time",
        tag_prefix = "umi-time-v",
        versions = {
            ["0.3.1"] = "d2cb2cd4ba4c49f233a44347c221480c45eb2ff8648ba42ee42b4971ee81b398",
        },
    },
    deps = {"umi.primitive.base_types", "umiutil"},
})
