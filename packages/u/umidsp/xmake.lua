includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umidsp", {"packages", "domain", "dsp"}, {
    deps = {"umimath", "umi.contract.audio"},
})
