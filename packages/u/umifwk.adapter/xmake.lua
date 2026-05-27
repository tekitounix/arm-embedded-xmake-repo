includes(path.join(os.scriptdir(), "..", "umi_source_overlay.lua"))

umi_source_overlay_package("umifwk.adapter", {"packages", "runtime", "framework", "adapter"}, {
    description = "UMI framework adapter package for embedded, plugin, standalone, and WASM harnesses",
    main_header = "umifwk/adapter/audio_block_runner.hh",
    deps = {"umifwk.service", "umi.contract.application", "umi.contract.audio", "umi.contract.control", "umi.primitive.base_types", "umidi", "umiport"},
})
