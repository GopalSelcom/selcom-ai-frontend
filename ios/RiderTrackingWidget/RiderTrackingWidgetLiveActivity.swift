import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Required by live_activities plugin
struct LiveActivitiesAppAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var order_id: String?
        public var merchant_name: String?
        public var status: String?
        public var title: String?
        public var subtitle: String?
        public var fare: String?
        public var eta: String?
        public var vehicle_desc: String?
        public var plate_number: String?
        public var step: Int?
        public var total_steps: Int?
        public var is_completed: Bool?
        public var is_rider_delivering: Bool?
        public var eta_seconds: Double?
        public var delivery_distance: String?
        public var driver_latitude: Double?
        public var driver_longitude: Double?
    }

    // Static data (doesn't change during the activity)
    var order_id: String?
    var merchant_name: String?
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String { "tracking_\(key)" }
}

// MARK: - View Model
struct TrackingViewModel {
    var title: String
    var merchantName: String
    let status: String
    let subtitle: String
    let fare: String
    let vehicleDesc: String
    let plateNumber: String
    let eta: String
    let arrivalDate: Date?
    let progressRatio: Double
    let isRiderDelivering: Bool
    
    init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
        let state = context.state
        let attributes = context.attributes
        let appGroupId = "group.com.selcom.go"
        let ud = UserDefaults(suiteName: appGroupId)

        self.title             = state.title ?? ud?.string(forKey: attributes.prefixedKey("title")) ?? "Selcom Go"
        self.merchantName      = state.merchant_name ?? attributes.merchant_name ?? ud?.string(forKey: attributes.prefixedKey("merchant_name")) ?? "Selcom Go"
        
        let rawStatus          = state.status ?? ud?.string(forKey: attributes.prefixedKey("status")) ?? "Finding Driver"
        self.status            = rawStatus.replacingOccurrences(of: "_", with: " ").capitalized
        
        self.subtitle          = state.subtitle ?? ud?.string(forKey: attributes.prefixedKey("subtitle")) ?? ""
        self.fare              = state.fare ?? ud?.string(forKey: attributes.prefixedKey("fare")) ?? ""
        self.eta               = state.eta ?? ud?.string(forKey: attributes.prefixedKey("eta")) ?? ""
        self.vehicleDesc       = state.vehicle_desc ?? ud?.string(forKey: attributes.prefixedKey("vehicle_desc")) ?? ""
        self.plateNumber       = state.plate_number ?? ud?.string(forKey: attributes.prefixedKey("plate_number")) ?? ""
        self.isRiderDelivering = state.is_rider_delivering ?? ud?.bool(forKey: attributes.prefixedKey("is_rider_delivering")) ?? false
        
        let stepVal            = Double(state.step ?? ud?.integer(forKey: attributes.prefixedKey("step")) ?? 0)
        let totalStepsVal      = max(Double(state.total_steps ?? ud?.integer(forKey: attributes.prefixedKey("total_steps")) ?? 5), 5.0)
        
        self.progressRatio     = min(max(stepVal / totalStepsVal, 0.0), 1.0)
        if let etaSec = state.eta_seconds, etaSec > 0 {
            self.arrivalDate = Date().addingTimeInterval(etaSec)
        } else {
            self.arrivalDate = nil
        }
        
        // Cache for partial updates
        if let ud = ud {
            if let s = state.status { ud.set(s, forKey: attributes.prefixedKey("status")) }
            if let t = state.title { ud.set(t, forKey: attributes.prefixedKey("title")) }
            if let m = state.merchant_name { ud.set(m, forKey: attributes.prefixedKey("merchant_name")) }
            if let sub = state.subtitle { ud.set(sub, forKey: attributes.prefixedKey("subtitle")) }
            if let f = state.fare { ud.set(f, forKey: attributes.prefixedKey("fare")) }
            if let e = state.eta { ud.set(e, forKey: attributes.prefixedKey("eta")) }
            if let v = state.vehicle_desc { ud.set(v, forKey: attributes.prefixedKey("vehicle_desc")) }
            if let p = state.plate_number { ud.set(p, forKey: attributes.prefixedKey("plate_number")) }
            if let s = state.step { ud.set(s, forKey: attributes.prefixedKey("step")) }
            if let ts = state.total_steps { ud.set(ts, forKey: attributes.prefixedKey("total_steps")) }
            if let rd = state.is_rider_delivering { ud.set(rd, forKey: attributes.prefixedKey("is_rider_delivering")) }
        }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.title.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(selcomColor)
                        .tracking(1)
                    
                    HStack(spacing: 6) {
                        Text(vm.status)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        if !vm.merchantName.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                            Text(vm.merchantName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(vm.vehicleDesc)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        if !vm.plateNumber.isEmpty {
                            Text(vm.plateNumber)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if !vm.fare.isEmpty {
                        Text(vm.fare)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    if let arrivalDate = vm.arrivalDate {
                        Text(timerInterval: Date()...arrivalDate, countsDown: true)
                            .font(.system(size: 14, weight: .bold).monospacedDigit())
                            .foregroundColor(selcomColor)
                    } else {
                        Text(vm.eta)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selcomColor)
                    }
                }
            }
            
            // Progress Bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 6)
                Capsule()
                    .fill(selcomColor)
                    .frame(width: 320 * CGFloat(vm.progressRatio), height: 6)
                
                Circle()
                    .fill(.white)
                    .frame(width: 10, height: 10)
                    .offset(x: 320 * CGFloat(vm.progressRatio) - 5)
                    .shadow(radius: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.8))
    }
}

struct DynamicIslandExpandedView: View {
    let vm: TrackingViewModel
    let selcomColor = Color(red: 243/255.0, green: 0/255.0, blue: 76/255.0)

    var body: some View {
        VStack(spacing: 8) {
            // Header Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 14))
                        .foregroundColor(selcomColor)
                    Text(vm.title.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)
                }
                Spacer()
                if !vm.fare.isEmpty {
                    Text(vm.fare)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 4)
            
            // Info Row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.merchantName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(vm.vehicleDesc)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                
                // Plate Tag
                if !vm.plateNumber.isEmpty {
                    PlateTag(text: vm.plateNumber)
                }
            }
            
            // Status & Progress Row
            VStack(spacing: 6) {
                HStack {
                    Text(vm.status)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    if !vm.eta.isEmpty {
                        if let arrivalDate = vm.arrivalDate {
                            Text(timerInterval: Date()...arrivalDate, countsDown: true)
                                .font(.system(size: 14, weight: .bold).monospacedDigit())
                                .foregroundColor(selcomColor)
                        } else {
                            Text(vm.eta)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selcomColor)
                        }
                    }
                }
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    Capsule()
                        .fill(selcomColor)
                        .frame(width: 320 * CGFloat(vm.progressRatio), height: 6)
                    
                    // Progress Indicator Dot
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .offset(x: 320 * CGFloat(vm.progressRatio) - 5)
                        .shadow(radius: 2)
                }
            }
            // Actions Row
            HStack(spacing: 16) {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "message.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                Button(action: {}) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
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
                if let arrivalDate = vm.arrivalDate {
                    Text(timerInterval: Date()...arrivalDate, countsDown: true)
                        .font(.system(size: 10, weight: .bold).monospacedDigit())
                        .foregroundColor(selcomColor)
                } else {
                    Text(vm.eta)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selcomColor)
                }
            } minimal: {
                Circle().fill(selcomColor).frame(width: 22, height: 22)
            }
            .keylineTint(selcomColor)
        }
    }
}
