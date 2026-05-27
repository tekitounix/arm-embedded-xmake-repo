includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.param_state", {"packages", "contract", "param-state"}, {
    description = "UMI parameter and shared state contracts",
    main_header = "umicore/param.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-param-state",
        tag_prefix = "umi-param-state-v",
        versions = {
            ["0.3.1"] = "b3fea8339b2630168aac05e5d6e2f2156cca3539240225eb7bb516cc4c437c87",
        },
    },
    deps = {"umi.primitive.base_types", "umi.primitive.time"},
})
