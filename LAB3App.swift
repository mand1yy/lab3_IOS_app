//
//  LAB3App.swift
//  LAB3
//
//  Created by Oleksii on 05.06.2025.
//

import SwiftUI
import SwiftData

@main
struct HotelApp: App {
    var body: some Scene {
        WindowGroup {
            RoomListView()
        }
        .modelContainer(for: [Room.self, Booking.self], isAutosaveEnabled: true) { result in
            switch result {
            case .success:
                print("SwiftData container initialized successfully")
            case .failure(let error):
                print("Failed to initialize SwiftData container: \(error)")
            }
        }
    }
}
