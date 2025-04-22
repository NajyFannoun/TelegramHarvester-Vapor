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

import TDLibKit
import Vapor

/// Encapsulates *only* the TDLib calls and *nothing* else.
final class TelegramService: @unchecked Sendable {
    private let logger: Vapor.Logger
    private let channelUsername: String
    var channelID: Int64?
    private let manager: TDLibClientManager

    private var _client: TDLibClient?
    var client: TDLibClient {
        guard let client = _client else {
            fatalError("🚨 TDLib client is not initialized. Call initializeClient() first.")
        }
        return client
    }

    init(
        logger: Vapor.Logger,
        apiID: Int,
        apiHash: String,
        phoneNumber: String,
        channelUsername: String
    ) throws {
        self.logger = logger
        self.channelUsername = channelUsername
        self.manager = TDLibClientManager()
    }

    func initializeClient() async {
        logger.info("📦 Initializing TDLib client...")

        self._client = manager.createClient { [self] data, client in
            do {
                let update: Update = try client.decoder.decode(Update.self, from: data)
                switch update {
                case .updateNewMessage(let newMsg):
                    switch newMsg.message.content {
                    case .messageText(let text):
                        logger.debug("💬 Incoming text message: \(text.text.text.prefix(50))...")
                    default:
                        logger.debug("📎 Received non-text message")
                    }
                case .updateMessageEdited:
                    logger.debug("✏️ Message edited update received")
                default:
                    logger.debug("📡 Unhandled update: \(update)")
                }
            } catch {
                logger.error("❌ Error decoding TDLib update: \(error.localizedDescription)")
            }
        }

        logger.info("🔧 Setting TDLib log verbosity level...")
        do {
            let query = SetLogVerbosityLevel(newVerbosityLevel: 1)
            let result = try self.client.execute(query: DTO(query))
            if let resultDict = result {
                logger.info("✅ Log verbosity set: \(resultDict)")
            }
        } catch {
            logger.error("⚠️ Failed to set log verbosity: \(error.localizedDescription)")
        }
    }

    func getAuthorizationState() async throws -> AuthorizationState {
        logger.info("🔍 Fetching authorization state...")
        let authState = try await client.getAuthorizationState()
        logger.info("📦 Current authorization state: \(authState)")

        return authState
    }

    /// Returns true if TDLib says we’re already fully authenticated
    func isReady() async -> Bool {
        return await verifyAuthentication()
    }

    // Verify if the user is authenticated with Telegram
    func verifyAuthentication() async -> Bool {
        logger.info("🔒 Verifying authentication status...")
        do {
            // Fetch the current authorization state
            let authState: AuthorizationState = try await getAuthorizationState()

            switch authState {
            case .authorizationStateReady:
                // User is authenticated; check if channel ID is saved
                logger.info("🔒 User is authenticated.")

                // Fetch channel ID if it's not already saved
                if self.channelID == nil {
                    logger.info("⚠️ Channel ID not found, trying to fetch it.")
                    do {
                        let _: Chat = try await getChannel()
                        logger.info("✅ Channel ID saved: \(self.channelID ?? -1)")
                    } catch {
                        logger.error("❌ Error fetching channel: \(error.localizedDescription)")
                        return false
                    }
                }

                return true

            case .authorizationStateWaitCode:
                // If waiting for the authentication code, return false
                logger.info("🔑 Waiting for code to authenticate. call auth endpoint.")
                return false

            default:
                // Handle unexpected authorization states
                logger.error("Unexpected authorization state: \(authState)")
                return false
            }
        } catch {
            // Handle error fetching authorization state
            logger.error("❌ Error fetching authorization state: \(error.localizedDescription)")
            return false
        }
    }

    /// Starts the TDLib parameter & phone‐number step.
    func setupClientParameters(apiHash: String, apiID: Int) async throws {
        logger.info("🔐 Starting auth flow")

        try await client.setTdlibParameters(
            apiHash: apiHash, apiId: apiID,
            applicationVersion: "1.0",
            databaseDirectory: FileManager.default.temporaryDirectory.path,
            databaseEncryptionKey: nil,
            deviceModel: "Server",
            filesDirectory: FileManager.default.temporaryDirectory.path,
            systemLanguageCode: "en",
            systemVersion: "1.0",
            useChatInfoDatabase: true,
            useFileDatabase: true,
            useMessageDatabase: true,
            useSecretChats: false,
            useTestDc: false
        )
    }

    /// Starts the TDLib parameter & phone‐number step.
    func setupClientPhoneNumber(phoneNumber: String) async throws {
        logger.info("📱 Sending phone number")
        try await client.setAuthenticationPhoneNumber(
            phoneNumber: phoneNumber,
            settings: .init(
                allowFlashCall: false,
                allowMissedCall: false,
                allowSmsRetrieverApi: false,
                authenticationTokens: [],
                firebaseAuthenticationSettings: nil,
                hasUnknownPhoneNumber: false,
                isCurrentPhoneNumber: true
            )
        )
    }

    /// Submits the one‐off code the user received
    func completeAuth(code: String) async throws -> Chat {
        logger.info("🔑 Checking code")
        try await client.checkAuthenticationCode(code: code)
        logger.info("🔍 Resolving public chat")
        let chat: Chat = try await getChannel()
        logger.info("✅ Channel ID: \(chat.id)")
        return chat
    }

    /// Fetches new messages since a given ID
    func fetchUpdates(since lastMessageID: Int64?) async throws -> [Message] {
        let chat: Chat = try await getChannel()
        let history: Messages = try await client.getChatHistory(
            chatId: chat.id,
            fromMessageId: lastMessageID ?? 0,
            limit: 100, offset: 0, onlyLocal: false
        )
        return history.messages ?? []
    }

    func getChannel() async throws -> Chat {
        let chat: Chat = try await client.searchPublicChat(username: channelUsername)
        self.channelID = chat.id
        return chat
    }

}
