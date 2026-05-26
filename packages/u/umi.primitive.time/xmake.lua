includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.primitive.time", {"packages", "primitive", "time"}, {
    deps = {"umi.primitive.base_types", "umiutil"},
})
