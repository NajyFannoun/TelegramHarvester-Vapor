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

// MARK: - TelegramService Storage Extension

extension Application {
  // Key for storing TelegramService in Application's storage
  private struct TelegramServiceKey: StorageKey {
    typealias Value = TelegramService
  }

  // Accessor for TelegramService
  var telegramService: TelegramService {
    get {
      // Ensure the service is set before accessing
      guard let service = self.storage[TelegramServiceKey.self] else {
        fatalError(
          "TelegramService not configured. Use app.telegramService = ... in configure.swift.")
      }
      return service
    }
    set {
      self.storage[TelegramServiceKey.self] = newValue
    }
  }
}

// MARK: - TelegramManager
private struct TelegramManagerKey: StorageKey {
  typealias Value = TelegramManager
}
extension Application {
  var telegramManager: TelegramManager {
    get {
      guard let m = storage[TelegramManagerKey.self] else {
        fatalError("TelegramManager not configured")
      }
      return m
    }
    set { storage[TelegramManagerKey.self] = newValue }
  }
}

// MARK: - Repositories
private struct TelegramRepositoryKey: StorageKey {
  typealias Value = TelegramRepository
}
extension Application {
  var telegramRepository: TelegramRepository {
    get {
      guard let r = storage[TelegramRepositoryKey.self] else {
        fatalError("TelegramRepository not configured")
      }
      return r
    }
    set { storage[TelegramRepositoryKey.self] = newValue }
  }
}

// MARK: - PollingManager
private struct PollingManagerKey: StorageKey {
  typealias Value = PollingManager
}

extension Application {
  var pollingManager: PollingManager {
    get {
      guard let m = storage[PollingManagerKey.self] else {
        fatalError("PollingManager not configured")
      }
      return m
    }
    set { storage[PollingManagerKey.self] = newValue }
  }
}
