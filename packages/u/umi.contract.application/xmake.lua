includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.application", {"packages", "contract", "application"}, {
    description = "UMI application bundle and processor contracts",
    main_header = "umicore/app.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-application",
        tag_prefix = "umi-application-v",
        versions = {
            ["0.3.1"] = "a3338a05a0f6f6796cb40f13cf15b0d7e7af1b875e990fd1e3875593764cd7c3",
        },
    },
    deps = {"umi.primitive.base_types", "umi.contract.audio", "umi.contract.control", "umi.contract.param_state"},
})
