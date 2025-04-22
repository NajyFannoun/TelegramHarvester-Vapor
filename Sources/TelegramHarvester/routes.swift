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

func routes(_ app: Application) throws {
    // MARK: - 🛠️ Controllers Initialization
    let telegramManager: TelegramManager = app.telegramManager
    let pollingManager: PollingManager = app.pollingManager

    // Migration routes (Controller to handle database migrations)
    let migrationController = MigrationController()
    try app.register(collection: migrationController)

    // Message routes (Controller to handle fetching messages)
    let messageController = MessageController(repository: app.telegramRepository)
    try app.register(collection: messageController)
    // Authentication routes (Controller to handle auth-related endpoints)

    let authController = AuthController(
        telegramManager: telegramManager, pollingManager: pollingManager)
    try app.register(collection: authController)

    // MARK: - 🌍 Serve Static Files (HTML)
    // Serve index.html at root
    let staticFileController = HomeController()
    try app.register(collection: staticFileController)
}
