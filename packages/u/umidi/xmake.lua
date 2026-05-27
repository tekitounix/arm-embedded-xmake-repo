includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umidi", {"packages", "domain", "midi"}, {
    description = "UMI MIDI protocol and event domain library",
    main_header = "umidi/midi.hh",
    release = {
        repo = "tekitounix/synthernet-xmake-repo",
        artifact = "umi-midi",
        tag_prefix = "umi-midi-v",
        versions = {
            ["0.3.1"] = "0da4fe9fcd0d6a48624b088489e973e8fce92be9cf685670990b9611ac2b7bad",
        },
    },
})
