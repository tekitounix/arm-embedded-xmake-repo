includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.surface", {"packages", "contract", "surface"}, {
    description = "UMI surface authority and execution environment contracts",
    main_header = "umifwk/environment.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-surface",
        tag_prefix = "umi-surface-v",
        versions = {
            ["0.3.1"] = "a5424e51d7b66450b96e15bb9b581d565b73d9813fd585b3ceb73a50b3a1d2aa",
        },
    },
    deps = {"umi.contract.module_abi", "umi.primitive.base_types"},
})
