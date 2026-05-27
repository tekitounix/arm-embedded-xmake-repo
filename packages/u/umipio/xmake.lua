includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umipio", {"packages", "platform", "pio"}, {
    description = "UMI portable RP-style PIO program construction library",
    main_header = "umipio/pio.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umipio",
        tag_prefix = "umipio-v",
        versions = {
            ["0.3.1"] = "5d085dcc346a2f83f3969d32737399b38af1aa6401252b9f71ceeef59d0670cb",
        },
    },
})
