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

// MARK: - TelegramChannel model representing a channel on Telegram
final class TelegramChannel: Model, Content {
    static let schema = "telegram_channels"  // Table name in the database

    // MARK: - Fields

    // Unique identifier for the database row
    @ID(key: .id)
    var id: UUID?

    // Telegram's unique channel ID
    @Field(key: "channel_id")
    var channelId: Int64

    // Channel's username (if available)
    @Field(key: "username")
    var username: String?

    // Channel's title (if available)
    @Field(key: "title")
    var title: String?

    // Channel's photo URL (if available)
    @Field(key: "photo_url")
    var photoUrl: String?

    // MARK: - Initializers

    // Default initializer required by Fluent
    init() {}

    // Custom initializer for convenience
    init(
        id: UUID? = nil,
        channelId: Int64,
        username: String? = nil,
        title: String? = nil,
        photoUrl: String? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.username = username
        self.title = title
        self.photoUrl = photoUrl
    }
}

// MARK: - Sendable Conformance
// Used when passing this model between threads (e.g. async tasks)
extension TelegramChannel: @unchecked Sendable {
    // ⚠️ `@unchecked` means you're taking responsibility for thread safety
    // The `didSet` on `id` ensures immutability, which helps maintain safety
}
