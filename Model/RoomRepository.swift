//
//  RoomRepository.swift
//  LAB3
//
//  Created by Oleksii on 05.06.2025.
//

import SwiftData
import Foundation

class RoomRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createRoom(_ room: Room) throws {
        modelContext.insert(room)
        try modelContext.save()
    }
    
    func fetchRooms() throws -> [Room] {
        let descriptor = FetchDescriptor<Room>(sortBy: [SortDescriptor(\.roomNumber)])
        return try modelContext.fetch(descriptor)
    }
    
    func fetchRoom(by id: UUID) throws -> Room? {
        let descriptor = FetchDescriptor<Room>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }
    
    func updateRoom(_ room: Room) throws {
        try modelContext.save()
    }
    
    func deleteRoom(_ room: Room) throws {
        print("Deleting room \(room.roomNumber) with \(room.bookings?.count ?? 0) bookings")
        modelContext.delete(room)
        try modelContext.save()
    }
    
    func createBooking(_ booking: Booking, for room: Room) throws {
        if let existingBookings = room.bookings {
            for existingBooking in existingBookings {
                if booking.startDate <= existingBooking.endDate && booking.endDate >= existingBooking.startDate {
                    throw BookingError.overlappingBooking
                }
            }
        }
        
        room.bookings?.append(booking)
        booking.room = room
        modelContext.insert(booking)
        try modelContext.save()
        print("Created booking \(booking.id) for room \(room.roomNumber)")
    }
    
    func deleteBooking(_ booking: Booking) throws {
        print("Attempting to delete booking \(booking.id)")
        modelContext.delete(booking)
        try modelContext.save()
        print("Successfully deleted booking \(booking.id)")
    }
    
    func deleteAllBookings(for room: Room) throws {
        print("Attempting to delete all bookings for room \(room.roomNumber)")
        if let bookings = room.bookings {
            for booking in bookings {
                modelContext.delete(booking)
                print("Deleted booking \(booking.id) for room \(room.roomNumber)")
            }
            room.bookings = [] // Очищаємо масив для синхронізації
        }
        try modelContext.save()
        print("Successfully deleted all bookings for room \(room.roomNumber)")
    }
    
    enum BookingError: Error {
        case overlappingBooking
    }
}
