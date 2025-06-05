//
//  ContentView.swift
//  LAB3
//
//  Created by Oleksii on 05.06.2025.
//

import SwiftUI
import SwiftData

struct RoomListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Room.roomNumber) private var rooms: [Room]
    @State private var showingAddRoom = false
    @State private var errorMessage: String?
    @State private var roomToDelete: Room? // Для підтвердження видалення
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(rooms) { room in
                    NavigationLink(destination: RoomDetailView(room: room)) {
                        HStack {
                            Text("Номер \(room.roomNumber)")
                            Spacer()
                            Text(room.isOccupied ? "Зайнято" : "Вільно")
                                .foregroundColor(room.isOccupied ? .red : .green)
                        }
                    }
                    .onAppear {
                        print("Room \(room.roomNumber): type = \(room.type.rawValue), id = \(room.id)")
                    }
                }
                .onDelete { offsets in
                    // Показуємо підтвердження перед видаленням
                    roomToDelete = rooms[offsets.first!]
                    showingDeleteConfirmation = true
                }
            }
            .navigationTitle("Номери готелю")
            .toolbar {
                Button(action: { showingAddRoom = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddRoom) {
                RoomDetailView()
            }
            .alert(isPresented: Binding<Bool>.init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(title: Text("Помилка"), message: Text(errorMessage ?? "Сталася помилка"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Підтвердження"),
                    message: Text("Ви впевнені, що хочете видалити номер \(roomToDelete?.roomNumber ?? 0)? Усі пов’язані бронювання будуть видалені."),
                    primaryButton: .destructive(Text("Видалити")) {
                        if let room = roomToDelete {
                            deleteRoom(room)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                print("Loaded \(rooms.count) rooms")
            }
        }
    }
    
    private func deleteRoom(_ room: Room) {
        do {
            print("Deleting room \(room.roomNumber) with type \(room.type.rawValue)")
            try RoomRepository(modelContext: modelContext).deleteRoom(room)
        } catch {
            errorMessage = "Не вдалося видалити номер: \(error.localizedDescription)"
            print("Delete error: \(error)")
        }
    }
}
