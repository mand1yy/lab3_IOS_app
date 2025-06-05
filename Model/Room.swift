//
//  Room.swift
//  LAB3
//
//  Created by Oleksii on 05.06.2025.
//

import SwiftData
import Foundation

enum RoomType: String, Codable, CaseIterable {
    case single = "Single"
    case double = "Double"
    case business = "Business"
    case suite = "Suite"
    case deluxe = "Deluxe"
}

@Model
class Room {
    @Attribute(.unique) var id: UUID
    var roomNumber: Int
    var type: RoomType
    var pricePerNight: Double
    var isOccupied: Bool
    var bedCount: Int
    @Relationship(deleteRule: .cascade) var bookings: [Booking]?
    
    init(roomNumber: Int, type: RoomType, pricePerNight: Double, isOccupied: Bool, bedCount: Int) {
        self.id = UUID()
        self.roomNumber = roomNumber
        self.type = type
        self.pricePerNight = pricePerNight
        self.isOccupied = isOccupied
        self.bedCount = bedCount
        self.bookings = []
    }
}
