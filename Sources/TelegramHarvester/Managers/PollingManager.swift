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
/// This class handles adaptive polling: it adjusts the polling interval based
/// on recent activity to optimize resource usage.
final class PollingManager: @unchecked Sendable {
    private let telegramManager: TelegramManager   // Responsible for Telegram-related operations
    private let eventLoop: any EventLoop           // Used for scheduling asynchronous tasks
    private let logger: Logger                     // For logging information, warnings, and errors

    // Polling control and backoff parameters:
    private var isPolling = false                  // Tracks whether polling is currently active
    private var interval: TimeInterval = 5.0       // Initial polling interval in seconds
    private let minInterval: TimeInterval = 1.0    // Minimum polling interval
    private let maxInterval: TimeInterval = 60.0   // Maximum polling interval
    private let increment: Double = 1.5            // Multiplier for backoff when no new messages
    private let decrement: Double = 0.75           // Multiplier for more frequent polling on new messages
    private var lastMessageTime: Date?             // Timestamp of the last successfully fetched message

    init(
        telegramManager: TelegramManager,
        eventLoop: any EventLoop,
        logger: Logger
    ) {
        self.telegramManager = telegramManager
        self.eventLoop = eventLoop
        self.logger = logger
    }

    /// Starts the continuous polling loop.
    /// Will first check if the Telegram client is authenticated before beginning.
    /// Retries every 5 seconds until ready.
    func start() {
        guard !isPolling else {
            logger.warning("Polling already running — skipping start.")
            return
        }

        // Retry loop for checking if Telegram is ready
        Task {
            while true {
                let isReady = telegramManager.isReady

                if isReady {
                    logger.info("✅ Telegram is authenticated. Starting polling...")
                    isPolling = true
                    let newID = try await telegramManager.getLastStoredMessageID()
                    scheduleNext(since: newID)
                    break  // Exit the loop once polling starts
                } else {
                    logger.warning("❌ Telegram is not Ready. Retrying...")
                }

                // Retry again after 5 seconds
                await Task.sleep(5 * 1_000_000_000)
            }
        }
    }

    /// Stops the polling process.
    func stop() {
        isPolling = false
        logger.info("🛑 PollingManager stopped.")
    }

    /// Schedules the next poll task using the current polling interval.
    private func scheduleNext(since lastID: Int64?) {
        guard isPolling else { return }
        logger.debug("⏳ Scheduling next poll in \(interval)s…")

        // Schedule a new task after the `interval` delay
        eventLoop.scheduleTask(in: .seconds(Int64(interval))) { [weak self] in
            guard let self: PollingManager = self, self.isPolling else {
                self?.logger.warning("PollingManager no longer active.")
                return
            }

            // Perform the polling asynchronously
            Task {
                await self.doPoll(since: lastID)
            }
        }
    }

    /// Performs a single polling operation.
    /// Asks TelegramManager to fetch new messages and adjust polling interval accordingly.
    private func doPoll(since lastID: Int64?) async {
        logger.info("📡 Polling for new messages since \(lastID ?? 0)…")

        do {
            // Attempt to fetch and store messages
            let newID = await telegramManager.pollAndStore(lastMessageID: lastID)
            lastMessageTime = Date()

            // Adjust polling interval based on whether we got new messages
            adjustInterval(hadNew: (newID != lastID))

            // Schedule the next poll
            scheduleNext(since: newID)
        } catch {
            // If polling failed, log the error and try again later
            logger.error("❌ PollingManager error: \(error)")

            // Treat error as no new data to increase delay
            adjustInterval(hadNew: false)
            scheduleNext(since: lastID)
        }
    }

    /// Adjusts the polling interval based on whether new messages were received.
    /// If new data was found, the interval is reduced to poll more frequently.
    /// If no data has been seen in a while, the interval is increased to save resources.
    private func adjustInterval(hadNew: Bool) {
        let old = interval

        if hadNew {
            // New data — poll more frequently
            interval = max(minInterval, interval * decrement)
        } else if let last = lastMessageTime,
                  Date().timeIntervalSince(last) > 300 {
            // No new data for 5+ minutes — increase polling delay
            interval = min(maxInterval, interval * increment)
        }

        logger.info("🔧 Interval: \(old)s → \(interval)s")
    }
}
