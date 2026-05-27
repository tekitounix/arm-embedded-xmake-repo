includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umidevice", {"packages", "platform", "device"}, {
    description = "UMI board-independent external device drivers",
    main_header = "umidevice/device.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-device",
        tag_prefix = "umi-device-v",
        versions = {
            ["0.3.1"] = "4653927f641c69a82ccb8ee2a299d15474ac129c723ec78ff26af794b6d73f54",
        },
    },
    deps = {"umihal", "umimmio", "umi.contract.audio", "umi.primitive.error", "umiutil"},
})
