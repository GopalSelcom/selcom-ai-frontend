import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Required by live_activities plugin
struct LiveActivitiesAppAttributes: ActivityAttributes {
    public typealias LiveDeliveryData = ContentState
    public struct ContentState: Codable, Hashable {
        public var status: String?
        public var driver_name: String?
        public var driver_avatar_url: String?
        public var vehicle_name: String?
        public var plate_number: String?
        public var eta_seconds: Double?
        public var driver_latitude: Double?
        public var driver_longitude: Double?
        public var is_completed: Bool?
    }

    // Static data
    var order_id: String?
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String { 
        let id = order_id ?? "default"
        return "tracking_\(id)_\(key)" 
    }
}

// MARK: - Optimized View Model
struct TrackingViewModel {
    let status: String
    let driverName: String
    let driverAvatarUrl: String
    let vehicleName: String
    let plateNumber: String
    let eta: String
    let progressRatio: Double
    let isRiderDelivering: Bool
    
    init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
        let state = context.state
        let activityId = context.activityID
        let appGroupId = "group.com.selcom.go"
        let ud = UserDefaults(suiteName: appGroupId)
        
        func cacheKey(_ key: String) -> String { "tracking_\(activityId)_\(key)" }

        let rawStatus          = state.status ?? ud?.string(forKey: cacheKey("status")) ?? "finding_driver"
        let normalizedStatus   = rawStatus.lowercased()
        let etaSeconds         = state.eta_seconds ?? ud?.double(forKey: cacheKey("eta_seconds")) ?? 0
        
        switch normalizedStatus {
            case "ride_completed", "completed":
                self.status = "You have arrived!"
            case "near_destination":
                self.status = "Almost There"
            case "ride_in_progress":
                self.status = "On Your Way"
            case "ride_started":
                self.status = "Ride Started"
            case "driver_arrived":
                self.status = "Driver Arrived"
            case "driver_arriving":
                self.status = "Driver En Route"
            case "searching", "finding driver", "finding_driver":
                self.status = "Finding Driver"
            case "driver_assigned", "assigned":
                self.status = "Driver Assigned"
            default:
                self.status = rawStatus.replacingOccurrences(of: "_", with: " ").capitalized
        }
        
        self.driverName        = state.driver_name ?? ud?.string(forKey: cacheKey("driver_name")) ?? ""
        self.driverAvatarUrl   = state.driver_avatar_url ?? ud?.string(forKey: cacheKey("driver_avatar_url")) ?? ""
        self.vehicleName       = state.vehicle_name ?? ud?.string(forKey: cacheKey("vehicle_name")) ?? ""
        self.plateNumber       = state.plate_number ?? ud?.string(forKey: cacheKey("plate_number")) ?? ""
        
        let isCompleted        = state.is_completed ?? ud?.bool(forKey: cacheKey("is_completed")) ?? false
        
        // 📏 Inferring state from status
        self.isRiderDelivering = normalizedStatus.contains("ride_started") || 
                                normalizedStatus.contains("progress") || 
                                normalizedStatus.contains("near") || 
                                normalizedStatus.contains("destination")

        // 🕰️ ETA Logic from eta_seconds
        if isCompleted || normalizedStatus.contains("completed") {
            self.eta = "Arrived"
            self.progressRatio = 1.0
        } else if etaSeconds > 0 {
            let mins = Int(ceil(etaSeconds / 60.0))
            self.eta = mins <= 1 ? "1 min" : "\(mins) mins"
            
            // Artificial progress mapping for the capsule bar
            if isRiderDelivering {
                // Mapping Arrival (drop-off) from 60% to 100%
                self.progressRatio = 0.6 + (0.4 * (1.0 - min(etaSeconds / 1200.0, 1.0)))
            } else {
                // Mapping Pickup from 0% to 50%
                self.progressRatio = 0.1 + (0.4 * (1.0 - min(etaSeconds / 1200.0, 1.0)))
            }
        } else {
            self.eta = "Soon"
            self.progressRatio = isRiderDelivering ? 0.8 : 0.2
        }
        
        // Cache updates
        if let ud = ud {
            if let s = state.status { ud.set(s, forKey: cacheKey("status")) }
            if let dn = state.driver_name { ud.set(dn, forKey: cacheKey("driver_name")) }
            if let dau = state.driver_avatar_url { ud.set(dau, forKey: cacheKey("driver_avatar_url")) }
            if let vn = state.vehicle_name { ud.set(vn, forKey: cacheKey("vehicle_name")) }
            if let pn = state.plate_number { ud.set(pn, forKey: cacheKey("plate_number")) }
            if let es = state.eta_seconds { ud.set(es, forKey: cacheKey("eta_seconds")) }
            if let ic = state.is_completed { ud.set(ic, forKey: cacheKey("is_completed")) }
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
                        let term = vm.isRiderDelivering ? "Arrival" : "Pickup"
                        let prefix = isSoon ? term : "\(term) in"
                        let displayEta = isSoon ? "soon" : vm.eta.lowercased()

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(prefix).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            Text(displayEta).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                        }
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        
                        if !vm.plateNumber.isEmpty || !vm.vehicleName.isEmpty {
                            HStack(spacing: 6) {
                                if !vm.plateNumber.isEmpty {
                                    Text(vm.plateNumber.uppercased())
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(3)
                                }
                                Text(vm.vehicleName)
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
                        Group {
                            if !vm.driverAvatarUrl.isEmpty, let img = UIImage(contentsOfFile: vm.driverAvatarUrl) {
                                Image(uiImage: img).resizable().scaledToFill().clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40)
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
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
