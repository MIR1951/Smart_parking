import Foundation
internal import Combine
import Supabase
import Realtime

@MainActor
final class ParkingAvailabilityStore: ObservableObject {
    
    
    
    /// parking_id -> available_spots
    @Published private(set) var available: [UUID: Int] = [:]
    
    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?
    
    private var hasLoadedOnce = false
    private var loadTask: Task<Void, Never>?
    
    init(client: SupabaseClient = SB.client) {
        self.client = client
        
    }
    func initialLoad(force: Bool = false) {
        if hasLoadedOnce && !force { return }
        
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.initialLoadAsync(force: force)
        }
    }
    
    private func initialLoadAsync(force: Bool) async {
        if hasLoadedOnce && !force { return }
        
        struct Row: Decodable {
            let parking_id: UUID
            let available_spots: Int
        }
        
        do {
            let rows: [Row] = try await client
                .from("parking_availability")
                .select("parking_id, available_spots")
                .execute()
                .value
            
            var dict: [UUID: Int] = [:]
            for r in rows { dict[r.parking_id] = r.available_spots }
            
            self.available = dict
            self.hasLoadedOnce = true
            print("✅ initialLoad ok:", dict.count)
            
        } catch {
            // ✅ cancelled bo'lsa log qilmaymiz
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            print("❌ initialLoad availability error:", error)
        }
        
        
        func start() {
            guard channel == nil else { return }
            
            let table = "parking_availability"
            let ch = client.channel("availability-lite")
            channel = ch
            
            // INSERT
            ch.onPostgresChange(InsertAction.self, schema: "public", table: table) { [weak self] action in
                guard let self else { return }
                Task { @MainActor in
                    self.apply(dictionary: action.record)
                }
            }
            
            // UPDATE
            ch.onPostgresChange(UpdateAction.self, schema: "public", table: table) { [weak self] action in
                guard let self else { return }
                Task { @MainActor in
                    self.apply(dictionary: action.record)
                }
            }
            
            // DELETE
            ch.onPostgresChange(DeleteAction.self, schema: "public", table: table) { [weak self] action in
                guard let self else { return }
                Task { @MainActor in
                    self.applyDelete(dictionary: action.oldRecord)
                }
            }
            
            Task {
                await ch.subscribe()
                print("✅ Realtime subscribed: public.\(table)")
            }
        }
    }
        
        func stop() {
            guard let ch = channel else { return }
            channel = nil
            Task { await ch.unsubscribe() }
        }
        
        // MARK: - Apply (MainActor)
        
         func apply(dictionary: [String: Any]) {
            guard
                let id = uuid(from: dictionary["parking_id"]),
                let spots = int(from: dictionary["available_spots"])
            else { return }
            
            available[id] = spots
        }
        
         func applyDelete(dictionary: [String: Any]?) {
            guard
                let dictionary,
                let id = uuid(from: dictionary["parking_id"])
            else { return }
            
            available[id] = nil
        }
        
        // MARK: - Helpers
        
        func uuid(from value: Any?) -> UUID? {
            if let s = value as? String { return UUID(uuidString: s) }
            if let u = value as? UUID { return u }
            return nil
        }
        
        func int(from value: Any?) -> Int? {
            if let i = value as? Int { return i }
            if let n = value as? NSNumber { return n.intValue }
            if let s = value as? String { return Int(s) }
            return nil
        }
    }

//extension ParkingAvailabilityStore {
//    func initialLoad() async {
//        struct Row: Decodable {
//            let parking_id: UUID
//            let available_spots: Int
//        }
//
//        do {
//            let rows: [Row] = try await client
//                .from("parking_availability")
//                .select("parking_id, available_spots")
//                .execute()
//                .value
//
//            var dict: [UUID: Int] = [:]
//            for r in rows { dict[r.parking_id] = r.available_spots }
//            available = dict
//
//            print("✅ initial availability loaded:", dict.count)
//        } catch {
//            print("❌ initialLoad availability error:", error)
//        }
//    }
//}

