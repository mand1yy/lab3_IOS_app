//
//  BookingView.swift
//  LAB3
//
//  Created by Oleksii on 05.06.2025.
//

import SwiftUI
import SwiftData

struct BookingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var booking: Booking?
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(86400) // Наступний день
    @State private var errorMessage: String?
    private let room: Room?
    
    init(booking: Booking? = nil, room: Room? = nil) {
        _booking = State(initialValue: booking)
        self.room = room
        if let booking = booking {
            _startDate = State(initialValue: booking.startDate)
            _endDate = State(initialValue: booking.endDate)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Дата початку", selection: $startDate, in: Date()..., displayedComponents: .date)
                DatePicker("Дата закінчення", selection: $endDate, in: Date()..., displayedComponents: .date)
            }
            .navigationTitle(booking == nil ? "Додати бронювання" : "Редагувати бронювання")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") { saveBooking() }
                }
            }
            .alert(isPresented: Binding<Bool>.init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(title: Text("Помилка"), message: Text(errorMessage ?? "Невірно введені дані"), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func saveBooking() {
        do {
            // Перевірка: дата закінчення пізніше дати початку
            guard endDate > startDate else {
                errorMessage = "Дата закінчення має бути пізніше дати початку"
                return
            }
            
            // Перевірка: дата початку не в минулому
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            guard calendar.startOfDay(for: startDate) >= today else {
                errorMessage = "Дата початку не може бути в минулому"
                return
            }
            
            guard let room = room else {
                errorMessage = "Не вибрано номер"
                return
            }
            
            let repository = RoomRepository(modelContext: modelContext)
            
            if let booking = booking {
                // Перевірка накладання для редагування (ігноруємо саме це бронювання)
                if let existingBookings = room.bookings {
                    for existingBooking in existingBookings where existingBooking.id != booking.id {
                        if startDate <= existingBooking.endDate && endDate >= existingBooking.startDate {
                            errorMessage = "Бронювання перетинається з існуючим періодом"
                            return
                        }
                    }
                }
                booking.startDate = startDate
                booking.endDate = endDate
                try repository.updateRoom(room)
                print("Updated booking \(booking.id) for room \(room.roomNumber)")
            } else {
                let newBooking = Booking(startDate: startDate, endDate: endDate)
                try repository.createBooking(newBooking, for: room)
                print("Created booking \(newBooking.id) for room \(room.roomNumber)")
            }
            dismiss()
        } catch RoomRepository.BookingError.overlappingBooking {
            errorMessage = "Бронювання перетинається з існуючим періодом"
        } catch {
            errorMessage = "Помилка при збереженні бронювання: \(error.localizedDescription)"
            print("Save booking error: \(error)")
        }
    }
}
