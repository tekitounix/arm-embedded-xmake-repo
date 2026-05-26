includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umibm", {"packages", "runtime", "baremetal"}, {
    deps = {"umi.contract.application", "umi.contract.audio", "umi.primitive.base_types", "umidi", "umihal", "umiutil"},
})
