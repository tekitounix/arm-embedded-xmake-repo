includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.contract.audio", {"packages", "contract", "audio"}, {
    description = "UMI audio plane configuration and realtime contracts",
    main_header = "umicore/audio_context.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-audio",
        tag_prefix = "umi-audio-v",
        versions = {
            ["0.3.1"] = "ef27413e7eccb8f9da1f875d7e22191598a0489b4734f87061fefadac284c729",
        },
    },
    deps = {"umi.primitive.base_types", "umi.primitive.error", "umi.contract.param_state", "umiutil"},
})
