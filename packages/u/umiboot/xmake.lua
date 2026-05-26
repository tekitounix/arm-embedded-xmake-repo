includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umiboot", {"packages", "runtime", "bootloader"}, {
    deps = {"umi.primitive.base_types", "umi.primitive.error", "umidbg", "umidi", "umios.crypto"},
})
