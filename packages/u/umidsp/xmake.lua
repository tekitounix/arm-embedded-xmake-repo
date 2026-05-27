includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umidsp", {"packages", "domain", "dsp"}, {
    description = "UMI DSP building blocks for realtime audio",
    main_header = "umidsp/dsp.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-dsp",
        tag_prefix = "umi-dsp-v",
        versions = {
            ["0.3.1"] = "2195ac7894b06daefc6da0cd51778b490b436a6b7058e92a65d989d1938a2d2f",
        },
    },
    deps = {"umimath", "umi.contract.audio"},
})
