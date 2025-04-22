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

import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) throws {
    // MARK: - 🔧 Database Configuration (PostgreSQL)
    let configuration = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor",
        database: Environment.get("DATABASE_NAME") ?? "vapor",
        tls: .disable
    )
    app.databases.use(.postgres(configuration: configuration), as: .psql)

    // MARK: - 🌐 Middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "10mb"

    // MARK: - 🧱 Migrations
    app.migrations.add(CreateChannels())
    app.migrations.add(CreateMessages())

    // MARK: - 🤖 Telegram Service Initialization
    guard
        let apiIDString = Environment.get("TELEGRAM_API_ID"),
        let apiID = Int(apiIDString),
        let apiHash = Environment.get("TELEGRAM_API_HASH"),
        let phoneNumber = Environment.get("TELEGRAM_PHONE_NUMBER")
    else {
        throw Abort(.internalServerError, reason: "Missing Telegram API credentials")
    }

    guard let channelUsername = Environment.get("TELEGRAM_CHANNEL_USERNAME") else {
        throw Abort(.internalServerError, reason: "Missing Telegram channel username")
    }

    // let tdLibWrapper = TDLibClientManagerWrapper()  // Initialize the TDLib client wrapper here
    app.telegramRepository = TelegramRepository(db: app.db)

    let telegramService = try TelegramService(
        logger: app.logger,
        apiID: apiID,
        apiHash: apiHash,
        phoneNumber: phoneNumber,
        channelUsername: channelUsername
    )
    app.telegramService = telegramService

    // Initialize TelegramManager with all dependencies
    let telegramManager = try TelegramManager(
        logger: app.logger,
        apiID: apiID,
        apiHash: apiHash,
        phoneNumber: phoneNumber,
        channelUsername: channelUsername,  // Default username
        // tdLibWrapper: tdLibWrapper,
        telegramRepo: app.telegramRepository,
        telegramService: telegramService
    )
    // Register the TelegramManager as a singleton
    app.telegramManager = telegramManager

    // MARK: - 🚦 Lifecycle Management
    app.lifecycle.use(TelegramManagerLifecycle(manager: telegramManager))

    // MARK: - 📡 Polling Service Setup
    let pollingManager = PollingManager(
        telegramManager: telegramManager,
        eventLoop: app.eventLoopGroup.next(),
        logger: app.logger
    )
    app.pollingManager = pollingManager

    // MARK: - 🚦 Lifecycle Management
    app.lifecycle.use(PollingServiceLifecycle(poller: pollingManager))

    // MARK: - 📬 Register HTTP Routes
    try routes(app)
}
