//
//  Booking.swift
//  LAB3
//
//  Created by Oleksii on 05.06.2025.
//
import SwiftData
import Foundation

@Model
class Booking {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date
    var room: Room?
    
    init(startDate: Date, endDate: Date) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
    }
}
