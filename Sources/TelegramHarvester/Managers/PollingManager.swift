//
//  Project: TelegramHarvester
//  Description: A backend system for harvesting and managing public Telegram channel data using TDLib and Vapor.
//  Author: Najy Fannoun
//  Developed By: Najy Fannoun
//  Version: 1.0.0
//  Date: April 2025
//  Copyright: © 2025 Najy Fannoun. All rights reserved.
//
//  License: This project is licensed under the MIT License.
//  You are free to use, modify, and distribute this software under the terms of the MIT License.
//  For more details, please refer to the LICENSE file in the project root directory.
//
//  Disclaimer: This project is intended for educational and research purposes only.
//  The author is not responsible for any misuse or illegal activities that may arise from the use of this software.
//  Please use this software responsibly and in compliance with applicable laws and regulations.
//

import Vapor

/// Periodically drives your TelegramManager to fetch & persist new messages.
final class PollingManager: @unchecked Sendable {
    private let telegramManager: TelegramManager
    private let eventLoop: any EventLoop
    private let logger: Logger

    // Polling control and backoff parameters:
    private var isPolling = false
    private var interval: TimeInterval = 5.0
    private let minInterval: TimeInterval = 1.0
    private let maxInterval: TimeInterval = 60.0
    private let increment: Double = 1.5
    private let decrement: Double = 0.75
    private var lastMessageTime: Date?

    init(
        telegramManager: TelegramManager,
        eventLoop: any EventLoop,
        logger: Logger
    ) {
        self.telegramManager = telegramManager
        self.eventLoop = eventLoop
        self.logger = logger
    }

    /// Public: start the continuous polling loop with retries.
    func start() {
        guard !isPolling else {
            logger.warning("Polling already running — skipping start.")
            return
        }

        // Retry loop for checking authentication and starting polling
        Task {
            while true {
                let isReady = telegramManager.isReady

                if isReady {
                    logger.info("✅ Telegram is authenticated. Starting polling...")
                    isPolling = true
                    let newID = try await telegramManager.getLastStoredMessageID()
                    scheduleNext(since: newID)
                    break  // Exit the loop once polling has started
                } else {
                    logger.warning("❌ Telegram is not Ready. Retrying...")
                }

                // Retry after a delay (e.g., 5 seconds)
                await Task.sleep(5 * 1_000_000_000)  // Sleep for 5 seconds before retrying
            }
        }
    }

    /// Public: stop polling.
    func stop() {
        isPolling = false
        logger.info("🛑 PollingManager stopped.")
    }

    /// Schedule the next poll after `interval` seconds.
    private func scheduleNext(since lastID: Int64?) {
        guard isPolling else { return }
        logger.debug("⏳ Scheduling next poll in \(interval)s…")
        eventLoop.scheduleTask(in: .seconds(Int64(interval))) { [weak self] in
            guard let self: PollingManager = self, self.isPolling else {
                self?.logger.warning("PollingManager no longer active.")
                return
            }
            Task {
                await self.doPoll(since: lastID)
            }
        }
    }

    /// Perform one poll: fetch + store, then reschedule.
    private func doPoll(since lastID: Int64?) async {
        logger.info("📡 Polling for new messages since \(lastID ?? 0)…")
        do {
            // Ask your TelegramManager to fetch & store
            let newID = await telegramManager.pollAndStore(lastMessageID: lastID)
            lastMessageTime = Date()
            // back off more aggressively next time
            adjustInterval(hadNew: (newID != lastID))
            scheduleNext(since: newID)
        } catch {
            logger.error("❌ PollingManager error: \(error)")
            adjustInterval(hadNew: false)
            scheduleNext(since: lastID)
        }
    }

    /// Increase or decrease our interval based on activity.
    private func adjustInterval(hadNew: Bool) {
        let old = interval
        if hadNew {
            interval = max(minInterval, interval * decrement)
        } else if let last = lastMessageTime,
            Date().timeIntervalSince(last) > 300
        {
            interval = min(maxInterval, interval * increment)
        }
        logger.info("🔧 Interval: \(old)s → \(interval)s")
    }
}
