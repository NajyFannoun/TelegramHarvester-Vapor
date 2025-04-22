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

/// Controller responsible for handling Telegram channel-related endpoints
struct ChannelController: RouteCollection {
    let repository: TelegramRepository

    func boot(routes: any RoutesBuilder) throws {
        // Register the route for fetching channel details
        routes.get("channel", ":channelId", use: getChannel)

        // Register the route for fetching messages with channel info
        routes.get("messages", ":channelId", use: getMessagesWithChannel)
    }

    /// Fetch channel details by its channelId
    func getChannel(req: Request) async throws -> Response {
        guard let channelId = req.parameters.get("channelId", as: Int64.self) else {
            throw Abort(.badRequest, reason: "Invalid channel ID")
        }

        // Fetch channel details for the given channelId
        let channel = try await repository.getChannel(byChannelID: channelId)

        // Return the channel details
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(channel)))
    }

    /// Fetch messages along with channel info for a given channelId
    func getMessagesWithChannel(req: Request) async throws -> Response {
        guard let channelId = req.parameters.get("channelId", as: Int64.self) else {
            throw Abort(.badRequest, reason: "Invalid channel ID")
        }

        // Fetch messages for the given channel
        let messages = try await repository.fetchMessagesForChannel(
            channelID: channelId, page: 1, per: 20)

        // Return the messages along with channel info
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(messages)))
    }
}
