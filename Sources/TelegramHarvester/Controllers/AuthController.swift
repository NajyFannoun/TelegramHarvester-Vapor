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

/// Controller for handling Telegram authentication endpoints.
struct AuthController: RouteCollection, @unchecked Sendable {
    let telegramManager: TelegramManager
    let pollingManager: PollingManager

    /// Registers authentication-related routes under the "/auth" group.
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        // Endpoint: GET /auth/code?code=123456
        // Used to complete authentication with the provided Telegram code.
        auth.get("code", use: completeAuth)

        // Endpoint: GET /auth/status
        // Returns the current authentication status of the Telegram service
        auth.get("status") { req async -> [String: Bool] in
            return ["isAuthenticated": await self.telegramManager.isAuthenticated()]
        }
    }

    /// Completes Telegram authentication using the provided verification code.
    ///
    /// - Parameter req: The incoming request, expecting a `code` query parameter.
    /// - Throws: `.badRequest` if the code is missing.
    /// - Returns: HTTP 200 OK if authentication succeeds.
    func completeAuth(req: Request) async throws -> HTTPStatus {
        // Extract the code from the query string
        guard let code = req.query[String.self, at: "code"] else {
            throw Abort(.badRequest, reason: "Missing code")
        }

        // Complete the authentication process with the Telegram service
        try await telegramManager.completeAuth(code: code)

        // Start the polling service after successful authentication
        //        pollingManager.start()

        // Respond with HTTP 200 OK
        return .ok
    }

}
