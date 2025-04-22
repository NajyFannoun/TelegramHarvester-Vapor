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
import Vapor

// Migration to create the "telegram_channels" table in the database
struct CreateChannels: AsyncMigration {
    // Called when applying the migration (creates the schema)
    func prepare(on database: any Database) async throws {
        try await database.schema("telegram_channels")
            .id()  // Adds a default UUID "id" field
            .field("channel_id", .int64, .required)  // Telegram channel ID
            .field("username", .string)  // Optional channel username
            .field("title", .string)  // Optional channel title
            .field("photo_url", .string)  // Optional channel photo URL
            .unique(on: "channel_id")  // Ensure channel_id is unique
            .create()
    }

    // Called when reverting the migration (drops the schema)
    func revert(on database: any Database) async throws {
        try await database.schema("telegram_channels").delete()
    }
}
