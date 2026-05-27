includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.primitive.base_types", {"packages", "primitive", "base-types"}, {
    description = "Shared scalar and strong-id base contracts",
    main_header = "umicore/types.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-base-types",
        tag_prefix = "umi-base-types-v",
        versions = {
            ["0.3.1"] = "7e3e810118bd28feb45dae9a7f274d1d7a9a5e2826d1271d6ab74603dde27add",
        },
    },
})
