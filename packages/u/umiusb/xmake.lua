includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umiusb", {"packages", "domain", "usb"}, {
    description = "UMI USB audio and MIDI domain contracts",
    main_header = "umiusb/usb.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-usb",
        tag_prefix = "umi-usb-v",
        versions = {
            ["0.3.1"] = "fbe219455f69afbde38c1f1ede92cac5f24336ea73fb60282cf01023439629b0",
        },
    },
    deps = {"umidsp"},
})
