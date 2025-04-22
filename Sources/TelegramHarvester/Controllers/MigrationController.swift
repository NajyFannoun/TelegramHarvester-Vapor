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

/// A controller that handles database migration through a route.
struct MigrationController: RouteCollection {

    /// Registers routes when the controller is booted.
    func boot(routes: any RoutesBuilder) throws {
        // Registers a GET endpoint at /migrate-database to trigger migration
        routes.get("migrate-database", use: migrateDatabase)
    }

    /// Triggers Vapor's auto migration and returns a JSON response.
    ///
    /// - Returns: A future `Response` indicating success or failure of migration.
    func migrateDatabase(req: Request) throws -> EventLoopFuture<Response> {
        return req.application.autoMigrate()
            .map {
                // Success: database tables created or already exist
                let payload = [
                    "status": "ok", "message": "Database tables created or already exist.",
                ]
                let data = try! JSONEncoder().encode(payload)
                return Response(status: .ok, body: .init(data: data))
            }
            .flatMapError { error in
                // Failure: return error message in response
                let payload = [
                    "status": "error", "message": "Migration failed: \(error.localizedDescription)",
                ]
                let data = try! JSONEncoder().encode(payload)
                let res = Response(status: .internalServerError, body: .init(data: data))
                return req.eventLoop.future(res)
            }
    }
}
