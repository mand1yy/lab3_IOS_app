//
//  RoomDetailView.swift
//  LAB3
//
//  Created by Oleksii on 05.06.2025.
//

import SwiftUI
import SwiftData

struct RoomDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var room: Room?
    @State private var roomNumber: String = ""
    @State private var type: RoomType
    @State private var pricePerNight: String = ""
    @State private var isOccupied: Bool = false
    @State private var bedCount: String = ""
    @State private var errorMessage: String?
    @State private var showingDeleteAllBookingsConfirmation = false
    @State private var showingDeleteRoomConfirmation = false
    
    // Динамічне завантаження бронювань через @Query
    @Query private var bookings: [Booking]
    
    init(room: Room? = nil) {
        _room = State(initialValue: room)
        if let room = room {
            _roomNumber = State(initialValue: String(room.roomNumber))
            _type = State(initialValue: room.type)
            _pricePerNight = State(initialValue: String(room.pricePerNight))
            _isOccupied = State(initialValue: room.isOccupied)
            _bedCount = State(initialValue: String(room.bedCount))
            let roomID = room.id
            _bookings = Query(filter: #Predicate<Booking> { $0.room?.id == roomID })
        } else {
            _type = State(initialValue: .single)
            _bookings = Query()
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Інформація про номер")) {
                    TextField("Номер кімнати", text: $roomNumber)
                        .keyboardType(.numberPad)
                    Picker("Тип кімнати", selection: $type) {
                        ForEach(RoomType.allCases, id: \.self) { roomType in
                            Text(roomType.rawValue).tag(roomType)
                        }
                    }
                    TextField("Ціна за ніч", text: $pricePerNight)
                        .keyboardType(.decimalPad)
                    Toggle("Зайнято", isOn: $isOccupied)
                    TextField("Кількість ліжок", text: $bedCount)
                        .keyboardType(.numberPad)
                }
                
                if !bookings.isEmpty {
                    Section(header: Text("Бронювання")) {
                        ForEach(bookings) { booking in
                            NavigationLink(destination: BookingView(booking: booking, room: room)) {
                                Text("\(booking.startDate, format: .dateTime.day().month().year()) - \(booking.endDate, format: .dateTime.day().month().year())")
                            }
                        }
                        .onDelete(perform: deleteBookings)
                        Button(action: {
                            showingDeleteAllBookingsConfirmation = true
                        }) {
                            Text("Видалити всі бронювання")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: BookingView(room: room)) {
                        Text("Додати бронювання")
                    }
                }
                
                if room != nil {
                    Section {
                        Button(action: {
                            showingDeleteRoomConfirmation = true
                        }) {
                            Text("Видалити номер")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle(room == nil ? "Додати номер" : "Редагувати номер")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") { saveRoom() }
                }
            }
            .alert(isPresented: Binding<Bool>.init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(title: Text("Помилка"), message: Text(errorMessage ?? "Невірно введені дані"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showingDeleteAllBookingsConfirmation) {
                Alert(
                    title: Text("Підтвердження"),
                    message: Text("Ви впевнені, що хочете видалити всі бронювання для номера \(room?.roomNumber ?? 0)?"),
                    primaryButton: .destructive(Text("Видалити")) {
                        deleteAllBookings()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $showingDeleteRoomConfirmation) {
                Alert(
                    title: Text("Підтвердження видалення"),
                    message: Text("Ви впевнені, що хочете видалити номер \(room?.roomNumber ?? 0)? Усі пов’язані бронювання будуть видалені."),
                    primaryButton: .destructive(Text("Видалити")) {
                        deleteRoom()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                if let room = room {
                    print("Editing room \(room.roomNumber): type = \(room.type.rawValue), bookings count: \(bookings.count)")
                } else {
                    print("Creating new room: type = \(type.rawValue)")
                }
            }
        }
    }
    
    private func saveRoom() {
        do {
            guard let roomNumber = Int(roomNumber),
                  let pricePerNight = Double(pricePerNight),
                  let bedCount = Int(bedCount) else {
                errorMessage = "Будь ласка, заповніть усі поля коректно"
                return
            }
            
            let repository = RoomRepository(modelContext: modelContext)
            
            if let room = room {
                room.roomNumber = roomNumber
                room.type = type
                room.pricePerNight = pricePerNight
                room.isOccupied = isOccupied
                room.bedCount = bedCount
                try repository.updateRoom(room)
                print("Updated room \(roomNumber): type = \(type.rawValue)")
            } else {
                let newRoom = Room(roomNumber: roomNumber, type: type, pricePerNight: pricePerNight, isOccupied: isOccupied, bedCount: bedCount)
                try repository.createRoom(newRoom)
                print("Created room \(roomNumber): type = \(type.rawValue)")
            }
            dismiss()
        } catch {
            errorMessage = "Помилка при збереженні номера: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
    
    private func deleteBookings(at offsets: IndexSet) {
        do {
            let repository = RoomRepository(modelContext: modelContext)
            for index in offsets {
                let booking = bookings[index]
                print("Deleting booking \(booking.id) for room \(room?.roomNumber ?? 0)")
                try repository.deleteBooking(booking)
            }
        } catch {
            errorMessage = "Не вдалося видалити бронювання: \(error.localizedDescription)"
            print("Delete booking error: \(error)")
        }
    }
    
    private func deleteAllBookings() {
        do {
            guard let room = room else { return }
            let repository = RoomRepository(modelContext: modelContext)
            try repository.deleteAllBookings(for: room)
        } catch {
            errorMessage = "Не вдалося видалити всі бронювання: \(error.localizedDescription)"
            print("Delete all bookings error: \(error)")
        }
    }
    
    private func deleteRoom() {
        do {
            guard let room = room else { return }
            let repository = RoomRepository(modelContext: modelContext)
            try repository.deleteRoom(room)
            dismiss()
        } catch {
            errorMessage = "Не вдалося видалити номер \(room?.roomNumber ?? 0): \(error.localizedDescription)"
            print("Delete room error: \(error)")
        }
    }
}
