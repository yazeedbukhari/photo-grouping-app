//
//  PipelineCoordinator.swift
//  photo-grouping-app
//
//  Created by Yazeed Bukhari on 2025-12-27.
//

//  This file defines the *orchestrator* (coordinator) of your pipeline.
//
//  Why a coordinator exists:
//  - Services (Gateway/Preprocess/Embed/Group/Suggest) should be "dumb" and focused.
//  - The coordinator is the one place that decides: batching, ordering, persistence, progress, cancellation,
//    and which config values to use.
//  - This keeps your algorithm code testable and your app behavior consistent.
//

import Foundation

// MARK: - Config Persistence (MVP: UserDefaults)
//
// We keep persistence separate from GroupingService because:
// - GroupingService should be deterministic given inputs + config.
// - Persistence is an "outer layer" concern (storage), not algorithm logic.
//
// For MVP, UserDefaults is fine. Later you might replace this with
// a SettingsRepository backed by a database, CloudKit, etc.
final class GroupingConfigStore {

    // UserDefaults keys are part of your app's public "storage API".
    // Keeping them in one place prevents key typos across files.
    private enum Keys {
        static let similarityThreshold = "grouping.similarityThreshold"
        static let timeWindowMins      = "grouping.timeWindowMins"
        static let minClusterSize      = "grouping.minClusterSize"
    }

    private let defaults: UserDefaults

    // Dependency injection:
    // - default is `.standard` for app usage
    // - tests can pass a separate suite for isolation
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // Load config:
    // - If no user settings exist, we supply defaults here (NOT in the service).
    // - This makes "defaults" a product decision (outer layer), not algorithm.
    func load() -> GroupingConfig {
        let similarity = defaults.object(forKey: Keys.similarityThreshold) as? Float ?? 0.85
        let windowSecs = defaults.object(forKey: Keys.timeWindowMins) as? Int64 ?? 5   // 10 minutes
        let minSize    = defaults.object(forKey: Keys.minClusterSize) as? Int ?? 1

        return GroupingConfig(
            similarityThreshold: similarity,
            timeWindowMins: windowSecs,
            minClusterSize: minSize,
            randomSeed: nil
        )
    }

    // Save config:
    // - Called by your settings UI (or by experimentation code).
    // - The coordinator will then read the latest config before running a pipeline.
    func save(_ config: GroupingConfig) {
        defaults.set(config.similarityThreshold, forKey: Keys.similarityThreshold)
        defaults.set(config.timeWindowMins, forKey: Keys.timeWindowMins)
        defaults.set(config.minClusterSize, forKey: Keys.minClusterSize)
    }
}

// MARK: - Coordinator
//
// This is the brain of the pipeline.
// It answers questions like:
// - Which photos do we process?
// - How big are batches?
// - Which model version do we use?
// - When do we stop early?
// - How do we report progress / cancellation?
//
// NOTE: This is deliberately a skeleton. It compiles once you wire the other protocols/types.
final class PipelineCoordinator {

    // Dependencies:
    // You inject these so:
    // - The coordinator is testable (swap in fakes/mocks).
    // - You can evolve implementations without changing orchestration code.

    private let configStore: GroupingConfigStore
    private let groupingService: GroupingService

    // In your app, you'll likely add:
    // private let assetGateway: PhotoAssetGateway
    // private let preprocessingService: PreprocessingService
    // private let embeddingService: EmbeddingService
    // private let embeddingRepository: EmbeddingRepository
    // private let suggestionService: SuggestionService
    //
    // Start with minimal deps; add as you wire each module.

    init(
        configStore: GroupingConfigStore = GroupingConfigStore(),
        groupingService: GroupingService = GroupingService()
    ) {
        self.configStore = configStore
        self.groupingService = groupingService
    }

    // MARK: - Public API

    /// Runs the grouping pipeline.
    ///
    /// Why async:
    /// - Real pipelines do IO (Photos framework, disk, Core ML).
    /// - async lets you run off the main thread and support cancellation.
    ///
    /// What this does (MVP version):
    /// 1) Load current config (persisted user preferences).
    /// 2) Call GroupingService with already-prepared PhotoWithVec.
    ///
    /// In the full pipeline, this method would:
    /// - fetch photo refs from Photos
    /// - generate/refresh embeddings in batches
    /// - then group
    func runGrouping(photosWithVec: [PhotoWithVec]) async -> [PhotoGroup] {
        // Coordinator owns config selection.
        // Services should not reach into UserDefaults.
        let config = configStore.load()

        // The coordinator also owns "preconditions":
        // GroupingService expects time-sorted input; enforce it here so the service stays simple.
        let sorted = photosWithVec.sorted { $0.captureTime < $1.captureTime }

        // Call the algorithmic service.
        // Important: GroupingService should be deterministic given (sorted, config).
        let groups = groupingService.group(photos: sorted, config: config)

        return groups
    }

    // MARK: - Convenience helpers (optional)

    /// Updates grouping config and persists it.
    /// This is typically called by a settings screen.
    func updateGroupingConfig(_ newConfig: GroupingConfig) {
        configStore.save(newConfig)
    }

    /// Reads the current config (useful to populate settings UI).
    func currentGroupingConfig() -> GroupingConfig {
        configStore.load()
    }
}
