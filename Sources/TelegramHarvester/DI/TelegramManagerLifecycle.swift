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

/// Lifecycle handler to manage the TelegramManager during app startup and shutdown.
struct TelegramManagerLifecycle: LifecycleHandler {
    let manager: TelegramManager

    /// Called when the application has finished booting
    func didBoot(_ application: Application) throws {
        application.logger.info("🚀 TelegramManagerLifecycle didBoot called")

        // Start a detached async task for Telegram Manager to manage the auth and fetching.
        Task {
            // Try to start the authentication flow
            do {
                try await manager.connectToTelegram()
            } catch {
                application.logger.error("❌ Error connectToTelegram: \(error.localizedDescription)")
            }
        }
    }

    /// Called when the application is shutting down
    func willShutdown(_ application: Application) throws {
        application.logger.info("🚨 TelegramManagerLifecycle willShutdown called")

        // Perform any cleanup if necessary, like stopping the client or disconnecting
        // Add any necessary shutdown logic for TelegramManager here if required.
    }
}
