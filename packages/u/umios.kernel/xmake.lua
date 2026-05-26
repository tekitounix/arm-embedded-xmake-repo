includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umios.kernel", {"packages", "runtime", "os", "kernel"}, {
    deps = {"umi.primitive.crc"},
})
