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

/// Controller to serve static files
struct HomeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        // Serve index.html at root
        routes.get { req -> EventLoopFuture<Response> in
            return self.serveIndex(req)
        }

        // Wildcard route to handle React frontend routing
        routes.get("*") { req -> EventLoopFuture<Response> in
            return self.serveIndex(req)
        }
    }

    // Function to serve the index.html file
    private func serveIndex(_ req: Request) -> EventLoopFuture<Response> {
        let filePath = "\(req.application.directory.publicDirectory)/index.html"
        req.logger.info("Serving file at path: \(filePath)")
        return req.eventLoop.makeSucceededFuture(
            req.fileio.streamFile(at: filePath)
        )
    }
}
