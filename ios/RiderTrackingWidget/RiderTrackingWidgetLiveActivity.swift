import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Required by live_activities plugin
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    public struct ContentState: Codable, Hashable {
        var order_id: String?
        var ride_id: String?
        var app_group_id: String?
        var status: String?
        var title: String?
        var subtitle: String?
        var merchant_name: String?
        var fare: String?
        var eta: String?
        var step: Int?
        var total_steps: Int?
        var vehicle_desc: String?
        var plate_number: String?
        var rider_photo_url: String?
        var is_completed: Bool?
        var is_rider_delivering: Bool?
        var delivery_start_date: Double?
        var eta_seconds: Double?
        var pickup_distance: String?
        var delivery_distance: String?

        enum CodingKeys: String, CodingKey {
            case order_id, ride_id, app_group_id, status, title, subtitle, merchant_name, fare, eta, step, total_steps, is_completed
            case vehicle_desc, plate_number, rider_photo_url, is_rider_delivering
            case delivery_start_date, eta_seconds, pickup_distance, delivery_distance
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            func decodeAsDouble(_ key: CodingKeys) -> Double? {
                if let val = try? container.decode(Double.self, forKey: key) { return val }
                if let val = try? container.decode(Int.self, forKey: key) { return Double(val) }
                if let str = try? container.decode(String.self, forKey: key), let val = Double(str) { return val }
                return nil
            }
            func decodeAsInt(_ key: CodingKeys) -> Int? {
                if let val = try? container.decode(Int.self, forKey: key) { return val }
                if let val = try? container.decode(Double.self, forKey: key) { return Int(val) }
                if let str = try? container.decode(String.self, forKey: key), let val = Int(str) { return val }
                return nil
            }
            func decodeAsBool(_ key: CodingKeys) -> Bool? {
                if let val = try? container.decode(Bool.self, forKey: key) { return val }
                if let val = try? container.decode(Int.self, forKey: key) { return val == 1 }
                return nil
            }

            let o_id = try? container.decodeIfPresent(String.self, forKey: .order_id)
            let r_id = try? container.decodeIfPresent(String.self, forKey: .ride_id)
            order_id = o_id ?? r_id
            ride_id = r_id
            app_group_id = try? container.decodeIfPresent(String.self, forKey: .app_group_id)
            status = try? container.decodeIfPresent(String.self, forKey: .status)
            title = try? container.decodeIfPresent(String.self, forKey: .title)
            subtitle = try? container.decodeIfPresent(String.self, forKey: .subtitle)
            merchant_name = try? container.decodeIfPresent(String.self, forKey: .merchant_name)
            fare = try? container.decodeIfPresent(String.self, forKey: .fare)
            eta = try? container.decodeIfPresent(String.self, forKey: .eta)
            vehicle_desc = try? container.decodeIfPresent(String.self, forKey: .vehicle_desc)
            plate_number = try? container.decodeIfPresent(String.self, forKey: .plate_number)
            rider_photo_url = try? container.decodeIfPresent(String.self, forKey: .rider_photo_url)
            
            is_completed = decodeAsBool(.is_completed)
            is_rider_delivering = decodeAsBool(.is_rider_delivering)
            
            step = decodeAsInt(.step)
            total_steps = decodeAsInt(.total_steps)
            delivery_start_date = decodeAsDouble(.delivery_start_date)
            eta_seconds = decodeAsDouble(.eta_seconds)

            if let val = try? container.decode(String.self, forKey: .pickup_distance) { pickup_distance = val }
            else if let val = try? container.decode(Double.self, forKey: .pickup_distance) { pickup_distance = String(val) }
            else if let val = try? container.decode(Int.self, forKey: .pickup_distance) { pickup_distance = String(val) }
            else { pickup_distance = "0" }

            if let val = try? container.decode(String.self, forKey: .delivery_distance) { delivery_distance = val }
            else if let val = try? container.decode(Double.self, forKey: .delivery_distance) { delivery_distance = String(val) }
            else if let val = try? container.decode(Int.self, forKey: .delivery_distance) { delivery_distance = String(val) }
            else { delivery_distance = "0" }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(order_id, forKey: .order_id)
            try container.encodeIfPresent(ride_id, forKey: .ride_id)
            try container.encodeIfPresent(app_group_id, forKey: .app_group_id)
            try container.encodeIfPresent(status, forKey: .status)
            try container.encodeIfPresent(title, forKey: .title)
            try container.encodeIfPresent(subtitle, forKey: .subtitle)
            try container.encodeIfPresent(merchant_name, forKey: .merchant_name)
            try container.encodeIfPresent(fare, forKey: .fare)
            try container.encodeIfPresent(eta, forKey: .eta)
            try container.encodeIfPresent(step, forKey: .step)
            try container.encodeIfPresent(total_steps, forKey: .total_steps)
            try container.encodeIfPresent(vehicle_desc, forKey: .vehicle_desc)
            try container.encodeIfPresent(plate_number, forKey: .plate_number)
            try container.encodeIfPresent(rider_photo_url, forKey: .rider_photo_url)
            try container.encodeIfPresent(is_completed, forKey: .is_completed)
            try container.encodeIfPresent(is_rider_delivering, forKey: .is_rider_delivering)
            try container.encodeIfPresent(delivery_start_date, forKey: .delivery_start_date)
            try container.encodeIfPresent(eta_seconds, forKey: .eta_seconds)
            try container.encodeIfPresent(pickup_distance, forKey: .pickup_distance)
            try container.encodeIfPresent(delivery_distance, forKey: .delivery_distance)
        }
    }
    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

// MARK: - View Model
struct TrackingViewModel {
    let title: String
    let merchantName: String
    let status: String
    let subtitle: String
    let fare: String
    let vehicleDesc: String
    let plateNumber: String
    let eta: String
    let progressRatio: Double
    let isRiderDelivering: Bool
    let riderPhotoUrl: String
    
    init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
        let state = context.state
        let attributes = context.attributes
        let appGroupId = "group.com.selcom.go"
        let ud = UserDefaults(suiteName: appGroupId)

        self.title             = state.title ?? ud?.string(forKey: attributes.prefixedKey("title")) ?? "Selcom Go Rider"
        let rawStatus = state.status ?? ud?.string(forKey: attributes.prefixedKey("status")) ?? "Finding Driver"
        self.status = rawStatus.replacingOccurrences(of: "_", with: " ").capitalized
        self.merchantName      = state.merchant_name ?? ud?.string(forKey: attributes.prefixedKey("merchant_name")) ?? "John Doe"
        self.subtitle          = state.subtitle ?? ud?.string(forKey: attributes.prefixedKey("subtitle")) ?? ""
        self.fare              = state.fare ?? ud?.string(forKey: attributes.prefixedKey("fare")) ?? ""
        self.vehicleDesc       = state.vehicle_desc ?? ud?.string(forKey: attributes.prefixedKey("vehicle_desc")) ?? "Silver Motorbike"
        self.plateNumber       = state.plate_number ?? ud?.string(forKey: attributes.prefixedKey("plate_number")) ?? "T772 BBE"
        self.riderPhotoUrl     = state.rider_photo_url ?? ud?.string(forKey: attributes.prefixedKey("rider_photo_url")) ?? ""
        self.isRiderDelivering = state.is_rider_delivering ?? (ud?.integer(forKey: attributes.prefixedKey("is_rider_delivering")) == 1)
        
        func formatDuration(_ totalMinutes: Int) -> String {
            if totalMinutes >= 60 {
                let h = totalMinutes / 60
                let m = totalMinutes % 60
                return "\(h)h \(m)m"
            }
            return "\(totalMinutes) min"
        }

        let pD_str             = state.pickup_distance ?? ud?.string(forKey: attributes.prefixedKey("pickup_distance")) ?? "0"
        let dD_str             = state.delivery_distance ?? ud?.string(forKey: attributes.prefixedKey("delivery_distance")) ?? "0"
        let pickupVal          = Double(pD_str) ?? 0.0
        let deliveryVal        = Double(dD_str) ?? 0.0

        let stepVal            = Double(state.step ?? ud?.integer(forKey: attributes.prefixedKey("step")) ?? 0)
        let totalStepsVal      = max(Double(state.total_steps ?? ud?.integer(forKey: attributes.prefixedKey("total_steps")) ?? 5), 5.0)

        if stepVal >= totalStepsVal || (state.is_completed ?? (ud?.integer(forKey: attributes.prefixedKey("is_completed")) == 1)) {
            self.eta = "Arrived"
        } else {
            let etaSec = state.eta_seconds ?? Double(ud?.integer(forKey: attributes.prefixedKey("eta_seconds")) ?? 0)
            if etaSec > 0 {
                self.eta = formatDuration(Int(ceil(etaSec / 60.0)))
            } else {
                let totalDist = (stepVal < totalStepsVal - 1) ? (pickupVal + deliveryVal) : deliveryVal
                let calcMin   = Int(ceil(totalDist / 35.0 * 60.0))
                
                if calcMin > 0 {
                    self.eta = formatDuration(calcMin)
                } else {
                    let be_eta = state.eta ?? ud?.string(forKey: attributes.prefixedKey("eta")) ?? "Soon"
                    self.eta = be_eta.lowercased().replacingOccurrences(of: " min", with: " min")
                }
            }
        }

        self.progressRatio     = min(max(stepVal / totalStepsVal, 0.0), 1.0)
    }
}

// MARK: - Components
struct PlateTag: View {
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
            Image(systemName: "flag.fill") // Placeholder for Tanzanian flag
                .resizable()
                .frame(width: 14, height: 10)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(red: 255/255.0, green: 214/255.0, blue: 0/255.0))
        .cornerRadius(4)
    }
}

// MARK: - Views
struct LockScreenView: View {
    let vm: TrackingViewModel
    let selcomColor = Color(red: 243/255.0, green: 0/255.0, blue: 76/255.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selcom Go Rider").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.7))
                    HStack(spacing: 4) {
                        Text(vm.status).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        Text("•").foregroundColor(.white.opacity(0.7))
                        Text(vm.merchantName).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    }
                    Text(vm.vehicleDesc).font(.system(size: 14)).foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                HStack(spacing: -12) {
                    ZStack {
                        if !vm.riderPhotoUrl.isEmpty, let img = UIImage(contentsOfFile: vm.riderPhotoUrl) {
                            Image(uiImage: img).resizable().scaledToFill().frame(width: 44, height: 44).clipShape(Circle()).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        } else {
                            Circle().fill(Color.gray).frame(width: 44, height: 44)
                        }
                    }
                    
                    Image(systemName: "bicycle") // Placeholder for vehicle type
                        .font(.system(size: 12))
                        .padding(4)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 8, y: -16)
                }
            }
            
            HStack {
                Spacer()
                PlateTag(text: vm.plateNumber)
            }
            .padding(.top, -20)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15)).frame(height: 6)
                Capsule()
                    .fill(selcomColor)
                    .frame(width: 320 * CGFloat(vm.progressRatio), height: 6)
                
                Circle()
                    .stroke(selcomColor, lineWidth: 2)
                    .background(Circle().fill(Color.black))
                    .frame(width: 10, height: 10)
                    .offset(x: 320 * CGFloat(vm.progressRatio) - 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.15).opacity(0.9))
    }
}

struct DynamicIslandExpandedView: View {
    let vm: TrackingViewModel
    let selcomColor = Color(red: 243/255.0, green: 0/255.0, blue: 76/255.0)

    var body: some View {
        VStack(spacing: 16) {
            // Top Row
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bicycle") // Placeholder
                        .foregroundColor(.white)
                    VStack(alignment: .leading) {
                        Text(vm.vehicleDesc).font(.system(size: 12)).foregroundColor(.gray)
                        Text("Selcom Go Rider").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    }
                }
                Spacer()
                if !vm.fare.isEmpty {
                    Text(vm.fare).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                }
            }
            
            // Progress Bar
            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2)).frame(height: 4)
                    Capsule().fill(selcomColor).frame(width: 280 * CGFloat(vm.progressRatio), height: 4)
                    
                    HStack(spacing: 0) {
                        Circle().fill(selcomColor).frame(width: 12, height: 12)
                        Spacer()
                        Circle().fill(Color.white).frame(width: 12, height: 12)
                        Spacer()
                        Circle().fill(Color(white: 0.4)).frame(width: 12, height: 12)
                    }
                    .frame(width: 280)
                }
                HStack {
                    Text("Ride Starting").font(.system(size: 10)).foregroundColor(.gray)
                    Spacer()
                    Text("Arrived").font(.system(size: 10)).foregroundColor(.gray)
                }
            }
            
            // Bottom Row
            HStack {
                HStack(spacing: 12) {
                    if !vm.riderPhotoUrl.isEmpty, let img = UIImage(contentsOfFile: vm.riderPhotoUrl) {
                        Image(uiImage: img).resizable().scaledToFill().frame(width: 48, height: 48).clipShape(Circle())
                    } else {
                        Circle().fill(Color.gray).frame(width: 48, height: 48)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.merchantName).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                        Text(vm.eta).font(.system(size: 18, weight: .bold)).foregroundColor(selcomColor)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "message.fill")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(white: 0.1))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.white)
                            .frame(width: 54, height: 54)
                            .background(selcomColor)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}

// MARK: - Widget Implementation
struct RiderTrackingWidgetLiveActivity: Widget {
    let selcomColor = Color(red: 243/255.0, green: 0/255.0, blue: 76/255.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            LockScreenView(vm: TrackingViewModel(context: context))
        } dynamicIsland: { context in
            let vm = TrackingViewModel(context: context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    DynamicIslandExpandedView(vm: vm)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Circle().fill(selcomColor).frame(width: 15, height: 15)
                    Text("selcom").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                Text(vm.eta).font(.system(size: 10, weight: .bold)).foregroundColor(selcomColor)
            } minimal: {
                Circle().fill(selcomColor).frame(width: 22, height: 22)
            }
            .keylineTint(selcomColor)
        }
    }
}
