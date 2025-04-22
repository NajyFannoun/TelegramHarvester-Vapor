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

import Foundation
import TDLibKit
import Vapor

/// Top‐level façade that Controllers talk to.
/// It coordinates Service ↔ Repository ↔ Polling.
final class TelegramManager: @unchecked Sendable {
    let service: TelegramService
    let telegramRepo: TelegramRepository
    let logger: Logging.Logger
    let apiHash: String
    let apiID: Int
    let phone: String

    let channelUsername: String
    var isReady: Bool

    init(
        logger: Logging.Logger,
        apiID: Int,
        apiHash: String,
        phoneNumber: String,
        channelUsername: String,
        //        tdLibWrapper: TDLibClientManagerWrapper,
        telegramRepo: TelegramRepository,
        telegramService: TelegramService
    ) throws {
        self.logger = logger
        self.apiID = apiID
        self.apiHash = apiHash
        self.phone = phoneNumber
        self.channelUsername = channelUsername
        self.telegramRepo = telegramRepo
        self.service = telegramService
        self.isReady = false
    }

    func connectToTelegram() async throws {

        do {
            logger.info("🚀 Starting Telegram connection flow...")

            // 1. Create and configure the client
            await service.initializeClient()
            logger.info("✅ Client created with ID: \(self.service.client.id)")

            _ = try await service.getAuthorizationState()

            // Bootstraps TDLibParameters + phone ⟶ TDLib
            try await service.setupClientParameters(
                apiHash: apiHash,
                apiID: apiID)

            self.isReady = await service.isReady()
            if self.isReady {
                return
            }

            try await service.setupClientPhoneNumber(
                phoneNumber: phone
            )

            _ = try await service.getAuthorizationState()

            // At this point, TDLib will wait for the verification code,
            // which will be sent to the user's phone number.
            // The user should enter this code in the app.
            logger.info("📱 Verification code sent to \(phone). Please enter POST /auth/code.")

            self.isReady = true
        } catch {
            logger.error("❗️Error during Telegram connection flow: \(error)")
            // throw error
        }
    }

    /// do when ready
    func doWhenReady() async throws {
        // 2. Wait for the authorization state to be ready
        logger.info("🔄 Waiting for authorization state to be ready...")
        let chat = try await service.getChannel()
        let channel = TelegramChannel(
            channelId: chat.id,
            username: channelUsername,
            title: chat.title,
            photoUrl: chat.photo?.small.remote.id  // Assuming the smallest photo variant URL
        )
        try await telegramRepo.saveChannel(channel)
        logger.info("✅ Authorization state is ready.")
    }

    /// Completes login with the code and stores channel info
    func completeAuth(code: String) async throws {
        let chat = try await service.completeAuth(code: code)
        // you could also fetch a Chat object and save more fields… omitted for brevity
        let channel = TelegramChannel(
            channelId: chat.id,
            username: channelUsername,
            title: chat.title,
            photoUrl: chat.photo?.small.remote.id  // Assuming the smallest photo variant URL
        )

        service.channelID = chat.id
        logger.info("📡 Channel ID: \(channel.channelId)")

        // Save the channel to the database
        try await telegramRepo.saveChannel(channel)
    }

    /// True if fully ready (i.e. channelID resolved)
    func isAuthenticated() async -> Bool {
        return await service.isReady()
    }

    /// Fetch new messages from TDLib and persist them
    func pollAndStore(lastMessageID: Int64?) async -> Int64? {
        do {
            let updates = try await service.fetchUpdates(since: lastMessageID)

            let models = updates.compactMap { msg -> TelegramMessage? in

                var text: String?
                var mediaUrl: String?
                var fotoMediaUrl: String?

                switch msg.content {
                case .messageText(let content):
                    text = content.text.text
                    mediaUrl = extractFirstURL(from: content.text)

                case .messagePhoto(let photo):
                    text = photo.caption.text
                    mediaUrl = photo.photo.sizes.last?.photo.remote.id

                case .messageDocument(let doc):
                    text = doc.caption.text
                    fotoMediaUrl = doc.document.document.remote.id

                default:
                    logger.debug("⏭️ Skipping unsupported message type for ID \(msg.id)")
                    return nil
                }

                guard let messageText = text, !messageText.isEmpty else {
                    logger.debug("⚠️ Skipping message ID \(msg.id) — no usable text.")
                    return nil
                }

                return TelegramMessage(
                    messageId: msg.id,
                    channelId: msg.chatId,
                    date: Date(timeIntervalSince1970: TimeInterval(msg.date)),
                    text: messageText,
                    mediaUrl: mediaUrl,
                    photoMediaUrl: fotoMediaUrl
                )
            }

            try await telegramRepo.saveMessages(models)
            logger.info("✅ Stored \(models.count) messages.")
            // Return the last message ID for the next poll
            return models.last?.messageId ?? lastMessageID

        } catch {
            logger.error("Polling/store error: \(error)")
            return lastMessageID

        }
    }

    func extractFirstURL(from text: FormattedText) -> String? {
        let entities = text.entities

        for entity in entities {
            switch entity.type {
            case .textEntityTypeTextUrl(let data):
                return data.url  // Link from [text](url)
            case .textEntityTypeUrl:
                // Raw URL in plain text, extract using offset and length
                let start = text.text.index(text.text.startIndex, offsetBy: entity.offset)
                let end = text.text.index(start, offsetBy: entity.length)
                return String(text.text[start..<end])
            default:
                continue
            }
        }

        return nil
    }

    /// Get the last stored message ID from the repository.
    func getLastStoredMessageID() async throws -> Int64? {
        guard let cid = service.channelID else {
            logger.warning("❗️No channel ID set in TelegramService.")
            return nil
        }

        let lastMessageID = try await telegramRepo.getLastStoredMessageID(forChannel: cid)
        logger.info(
            "📩 Last stored message ID for channel \(cid): \(String(describing: lastMessageID))")
        return lastMessageID
    }

}
