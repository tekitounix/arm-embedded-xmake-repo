includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umi.primitive.crc", {"packages", "primitive", "crc"}, {
    description = "UMI CRC helpers and checksum contracts",
    main_header = "umicore/crc.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-crc",
        tag_prefix = "umi-crc-v",
        versions = {
            ["0.3.1"] = "68492b2aa31de2d89a7d0b34e5ab25030725923ebcb64cdd3b97846de21a72b2",
        },
    },
})
