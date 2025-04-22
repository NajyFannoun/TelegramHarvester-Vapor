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

// MARK: - TelegramMessage model representing a message in a Telegram channel
final class TelegramMessage: Model, Content {
    static let schema = "telegram_messages"  // Table name in the database

    // MARK: - Fields

    // Unique identifier for the database row
    @ID(key: .id)
    var id: UUID?

    // Telegram's original message ID
    @Field(key: "message_id")
    var messageId: Int64

    // Telegram channel ID this message belongs to
    @Field(key: "channel_id")
    var channelId: Int64

    // Date the message was created (from Telegram)
    @Field(key: "date")
    var date: Date

    // Message content (text body)
    @Field(key: "text")
    var text: String

    // Optional general media URL (if the message contains media)
    @Field(key: "media_url")
    var mediaUrl: String?

    // Optional photo media URL (if the message contains a photo)
    @Field(key: "photo_media_url")
    var photoMediaUrl: String?

    // MARK: - Initializers

    // Default initializer required by Fluent
    init() {}

    // Custom initializer for convenience
    init(
        id: UUID? = nil,
        messageId: Int64,
        channelId: Int64,
        date: Date,
        text: String,
        mediaUrl: String? = nil,
        photoMediaUrl: String? = nil
    ) {
        self.id = id
        self.messageId = messageId
        self.channelId = channelId
        self.date = date
        self.text = text
        self.mediaUrl = mediaUrl
        self.photoMediaUrl = photoMediaUrl
    }
}

// MARK: - Sendable Conformance
// Used when passing this model between threads (e.g. async tasks)
extension TelegramMessage: @unchecked Sendable {
    // ⚠️ `@unchecked` means you're taking responsibility for thread safety
    // The `didSet` on `id` ensures immutability, which helps maintain safety
}
