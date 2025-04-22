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
import Foundation
import Vapor

/// Response model for paginated Telegram messages
struct MessagesResponse: Content {
    let messages: [TelegramMessage]  // List of messages
    let totalPages: Int  // Total number of available pages
}

/// Controller responsible for handling message-related endpoints
struct MessageController: RouteCollection {
    let repository: TelegramRepository  // Inject the repository

    func boot(routes: any RoutesBuilder) throws {
        // Register the route for fetching messages
        routes.get("messages", use: getMessages)
    }

    /// Handles the request to fetch messages from the database.
    /// Retrieves paginated Telegram messages.
    ///
    /// - Parameters:
    ///   - req: The incoming request, which may include "page" and "per_page" query parameters.
    /// - Returns: A `MessagesResponse` containing the messages and total page count.
    func getMessages(req: Request) async throws -> MessagesResponse {
        // Read pagination parameters from the query (default to page 1, 20 items per page)
        let page = req.query["page"] ?? 1
        let perPage = req.query["per_page"] ?? 20

        do {
            // Call the repository to fetch the paginated messages
            let messagesResponse = try await repository.getMessages(page: page, perPage: perPage)
            return messagesResponse
        } catch {
            throw Abort(
                .internalServerError,
                reason: "Failed to fetch messages: \(error.localizedDescription)")
        }
    }
}
