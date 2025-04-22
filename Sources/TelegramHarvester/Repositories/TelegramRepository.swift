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

/// Knows *only* how to persist Message models.
struct TelegramRepository {
    let db: any Database

    func saveChannel(_ channel: TelegramChannel) async throws {
        // skip if exists
        if try await TelegramChannel.query(on: db)
            .filter(\.$channelId == channel.channelId)
            .first() == nil
        {
            try await channel.save(on: db)
        }
    }

    func saveMessage(_ message: TelegramMessage) async throws {
        // skip if already exists
        if try await TelegramMessage.query(on: db)
            .filter(\.$messageId == message.messageId)
            .first() == nil
        {
            try await message.save(on: db)
        }
    }

    func saveMessages(_ messages: [TelegramMessage]) async throws {
        for m: TelegramMessage in messages { try await saveMessage(m) }
    }

    func paginateMessages(page: Int, per: Int) async throws -> Page<TelegramMessage> {
        return try await TelegramMessage.query(on: db)
            .sort(\.$date, .descending)
            .paginate(.init(page: page, per: per))
    }

    /// Returns the highest message_id we have in DB for the given channel, or nil if none yet.
    func getLastStoredMessageID(forChannel channelID: Int64) async throws -> Int64? {
        let row = try await TelegramMessage.query(on: db)
            .filter(\.$channelId == channelID)
            .sort(\.$messageId, .descending)
            .first()
        return row?.messageId
    }

    // Fetches channel info based on the channel ID
    func getChannel(byChannelID channelID: Int64) async throws -> TelegramChannel? {
        return try await TelegramChannel.query(on: db)
            .filter(\.$channelId == channelID)
            .first()
    }

    // Fetch messages for a given channel, along with channel data
    func fetchMessagesForChannel(channelID: Int64, page: Int, per: Int) async throws
        -> [TelegramMessageWithChannel]
    {
        let messages = try await TelegramMessage.query(on: db)
            .filter(\.$channelId == channelID)
            .sort(\.$date, .descending)
            .paginate(.init(page: page, per: per))

        // Get channel info for the given channel ID
        guard let channel = try await getChannel(byChannelID: channelID) else {
            throw Abort(.notFound, reason: "Channel not found")
        }

        // Combine the channel info with each message
        return messages.items.map { message in
            TelegramMessageWithChannel(
                message: message,
                channelTitle: channel.title,
                channelPhotoUrl: channel.photoUrl
            )
        }
    }

    /// Handles the request to fetch messages from the database.
    /// Retrieves paginated Telegram messages.
    ///
    /// - Parameters:
    ///   - req: The incoming request, which may include "page" and "per_page" query parameters.
    /// - Returns: A `MessagesResponse` containing the messages and total page count.
    func getMessages(page: Int, perPage: Int) async throws -> MessagesResponse {

        // Create a pagination request with the given parameters
        let pageRequest = PageRequest(page: page, per: perPage)

        // Query the TelegramMessage model, sorted by date (descending), and paginate results
        let messagesPage = try await TelegramMessage.query(on: db)
            .sort(\.$date, .descending)
            .paginate(pageRequest)

        // Return the messages and total number of pages
        return MessagesResponse(
            messages: messagesPage.items,
            totalPages: messagesPage.metadata.pageCount ?? 1
        )
    }

}

struct TelegramMessageWithChannel: Content {
    let message: TelegramMessage
    let channelTitle: String?
    let channelPhotoUrl: String?
}
