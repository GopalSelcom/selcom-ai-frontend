import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Required by live_activities plugin
struct LiveActivitiesAppAttributes: ActivityAttributes {
    public typealias LiveDeliveryData = ContentState
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

// MARK: - Optimized View Model
struct TrackingViewModel {
    let title: String
    let merchantName: String
    let status: String
    let subtitle: String
    let vehicleDesc: String
    let plateNumber: String
    let eta: String
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
        self.status            = (rawStatus.replacingOccurrences(of: "_", with: " ")).capitalized
        
        self.subtitle          = state.subtitle ?? ud?.string(forKey: attributes.prefixedKey("subtitle")) ?? ""
        self.vehicleDesc       = state.vehicle_desc ?? ud?.string(forKey: attributes.prefixedKey("vehicle_desc")) ?? ""
        self.plateNumber       = state.plate_number ?? ud?.string(forKey: attributes.prefixedKey("plate_number")) ?? ""
        self.isRiderDelivering = state.is_rider_delivering ?? ud?.bool(forKey: attributes.prefixedKey("is_rider_delivering")) ?? false
        
        // 📏 Progress Logic
        let stepVal            = Double(state.step ?? ud?.integer(forKey: attributes.prefixedKey("step")) ?? 0)
        let totalStepsVal      = max(Double(state.total_steps ?? ud?.integer(forKey: attributes.prefixedKey("total_steps")) ?? 5), 5.0)
        self.progressRatio     = min(max(stepVal / totalStepsVal, 0.0), 1.0)

        // 🕰️ ETA Logic
        if self.progressRatio >= 1.0 || (state.is_completed ?? ud?.bool(forKey: attributes.prefixedKey("is_completed")) ?? false) {
            self.eta = "Arrived"
        } else {
            let be_eta = state.eta ?? ud?.string(forKey: attributes.prefixedKey("eta")) ?? ""
            if be_eta.isEmpty {
                self.eta = "Soon"
            } else {
                // Ensure it says "mins" if needed, but usually backend provides "2 min"
                self.eta = be_eta.lowercased().replacingOccurrences(of: " min", with: " mins")
            }
        }
        
        // Cache updates for partial data packets
        if let ud = ud {
            if let s = state.status { ud.set(s, forKey: attributes.prefixedKey("status")) }
            if let t = state.title { ud.set(t, forKey: attributes.prefixedKey("title")) }
            if let m = state.merchant_name { ud.set(m, forKey: attributes.prefixedKey("merchant_name")) }
            if let sub = state.subtitle { ud.set(sub, forKey: attributes.prefixedKey("subtitle")) }
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
struct MainDashboardView: View {
    let vm: TrackingViewModel
    let selcomRed = Color(red: 243/255.0, green: 0/255.0, blue: 76/255.0)
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                // 🏷️ Brand Header
                HStack(spacing: 6) {
                    Circle()
                        .fill(selcomRed)
                        .frame(width: 18, height: 18)
                        .overlay(Text("S").foregroundColor(.white).font(.system(size: 10, weight: .black)))
                    Text("selcom.go").font(.system(size: 16, weight: .black)).foregroundColor(.white)
                }
                .padding(.bottom, 6)

                if vm.eta == "Arrived" {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thank you for your ride!").font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        HStack {
                            Text("Ride arrived").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                            Text("✅").font(.system(size: 24))
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(vm.status).font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        
                        let isSoon = vm.eta.lowercased().contains("soon") || vm.eta.isEmpty
                        let prefix = isSoon ? "Arriving" : "Arriving in"
                        let displayEta = isSoon ? "soon" : vm.eta.lowercased()

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(prefix).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            Text(displayEta).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                        }
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        
                        if !vm.plateNumber.isEmpty || !vm.vehicleDesc.isEmpty {
                            HStack(spacing: 6) {
                                if !vm.plateNumber.isEmpty {
                                    Text(vm.plateNumber.uppercased())
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(3)
                                }
                                Text(vm.vehicleDesc)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    Spacer(minLength: 12)
                    
                    // Capsule Progress Bar
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15)).frame(height: 10)
                        Capsule()
                            .fill(selcomRed)
                            .frame(width: 220 * CGFloat(vm.progressRatio), height: 10)
                    }
                    .frame(maxWidth: 220)
                }
            }
            
            Spacer()
            
            // Photo Area
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
        }
    }
}

// MARK: - Widget Implementation
struct RiderTrackingWidgetLiveActivity: Widget {
    let selcomRed = Color(red: 243/255.0, green: 0/255.0, blue: 76/255.0)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            MainDashboardView(vm: TrackingViewModel(context: context))
                .padding(.horizontal, 20).padding(.vertical, 16)
                .background(Color.black)
        } dynamicIsland: { context in
            let vm = TrackingViewModel(context: context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    MainDashboardView(vm: vm)
                        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 12)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Circle().fill(selcomRed).frame(width: 15, height: 15)
                    Text("selcom").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                ZStack {
                    Capsule()
                        .stroke(selcomRed.opacity(0.5), lineWidth: 2)
                        .frame(width: 54, height: 22)

                    Text(vm.eta == "Arrived" ? "Done" : vm.eta.lowercased())
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 6)
            } minimal: {
                Circle().fill(selcomRed).frame(width: 22, height: 22)
            }
            .keylineTint(selcomRed)
        }
    }
}
