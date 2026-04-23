import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Required by live_activities plugin
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    public struct ContentState: Codable, Hashable {
        public var status: String?
        public var driver_name: String?
        public var vehicle_name: String?
        public var plate_number: String?
        public var driver_avatar_url: String?
        public var eta_seconds: String?
        public var is_completed: String?
        public var driver_latitude: String?
        public var driver_longitude: String?
    }

    // This ID must be present and will be automatically populated by the plugin
    var id: UUID
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String { 
        return "\(id)_\(key)" 
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
    let isRiderInRide: Bool
    let isArrived: Bool
    let debugStatus: String 
    
    init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
        let attrs = context.attributes
        let ud = UserDefaults(suiteName: "group.com.selcom.go")
        
        // 🛠️ Hybrid Reader: UserDefaults (Local Sync) -> ContentState (APNs Sync)
        func read(_ key: String) -> String? {
            // Priority 1: Check Local Cache (used while app is open)
            if let cachedValue = ud?.string(forKey: attrs.prefixedKey(key)), !cachedValue.isEmpty {
                return cachedValue
            }
            
            // Priority 2: Check Native State (updated by backend APNs via ActivityKit)
            let st = context.state
            switch key {
                case "status":            return st.status
                case "driver_name":       return st.driver_name
                case "vehicle_name":      return st.vehicle_name
                case "plate_number":      return st.plate_number
                case "driver_avatar_url": return st.driver_avatar_url
                case "eta_seconds":       return st.eta_seconds
                case "is_completed":      return st.is_completed
                default:                  return nil
            }
        }

        let rawStatus          = read("status") ?? "finding_driver"
        self.debugStatus       = rawStatus
        let normalizedStatus   = rawStatus.lowercased()
        
        let etaSecondsStr      = read("eta_seconds") ?? "0"
        let etaSeconds         = Double(etaSecondsStr) ?? 0
        
        let isCompletedStr     = read("is_completed") ?? "false"
        self.isArrived         = isCompletedStr.lowercased() == "true" || normalizedStatus.contains("completed")

        // Phase Detection
        let tripPhaseStatus = ["ride_started", "ridestarted", "ride_in_progress", "rideinprogress", "near_destination", "neardestination"]
        self.isRiderInRide = tripPhaseStatus.contains(normalizedStatus)

        switch normalizedStatus {
            case "ride_completed", "completed":
                self.status = "You have arrived!"
            case "near_destination", "neardestination":
                self.status = "Almost There"
            case "ride_in_progress", "rideinprogress":
                self.status = "On Your Way"
            case "ride_started", "ridestarted":
                self.status = "Ride Started"
            case "driver_arrived", "driverarrived":
                self.status = "Driver Arrived"
            case "driver_arriving", "driverarriving":
                self.status = "Driver En Route"
            case "searching", "finding driver", "finding_driver":
                self.status = "Finding Driver"
            case "driver_assigned", "driverassigned", "assigned":
                self.status = "Driver Assigned"
            case "driver_assigning", "driverassigning":
                self.status = "Driver Assigned"
            default:
                self.status = rawStatus.replacingOccurrences(of: "_", with: " ").capitalized
        }
        self.driverName        = read("driver_name") ?? ""
        self.driverAvatarUrl   = read("driver_avatar_url") ?? ""
        self.plateNumber       = read("plate_number") ?? ""
        
        // 🚗 Vehicle Cleaning: Remove plate from name if duplicated (Hardened)
        let rawVehicleName     = read("vehicle_name") ?? ""
        let cleanPlateProp     = self.plateNumber.replacingOccurrences(of: " ", with: "").lowercased()
        let cleanVehicleName   = rawVehicleName.replacingOccurrences(of: " ", with: "").lowercased()

        if !cleanPlateProp.isEmpty && cleanVehicleName.contains(cleanPlateProp) {
            var vName = rawVehicleName
            let separators = [" - ", "-", "  ", " "]
            
            // Generate permutations of the plate to try and remove
            let p = self.plateNumber
            let pNoSpaces = p.replacingOccurrences(of: " ", with: "")
            let pWithSpaces = pNoSpaces.enumerated().map { (index, char) in
                return index > 0 ? " \(char)" : "\(char)"
            }.joined() // Simple spaced version like "T 1 0 0 A A A" - maybe too much
            
            // More realistic spaced version: T 100 AAA
            let pFormatted = pNoSpaces.count >= 4 ? 
                "\(pNoSpaces.prefix(1)) \(pNoSpaces.dropFirst().prefix(3)) \(pNoSpaces.dropFirst(4))" : pNoSpaces

            let variations = [p, pNoSpaces, pFormatted]
            
            for target in variations {
                if target.count > 3 { // Avoid stripping short fragments
                    for sep in separators {
                        vName = vName.replacingOccurrences(of: "\(sep)\(target)", with: "")
                    }
                    vName = vName.replacingOccurrences(of: target, with: "")
                }
            }
            self.vehicleName = vName.trimmingCharacters(in: .whitespaces)
                                    .replacingOccurrences(of: "  ", with: " ")
        } else {
            self.vehicleName = rawVehicleName
        }
        
        // 🕰️ ETA & Progress Logic
        if isArrived {
            self.eta = "Arrived"
            self.progressRatio = 1.0
        } else if etaSeconds > 0 {
            let mins = Int(ceil(etaSeconds / 60.0))
            self.eta = mins <= 1 ? "1 min" : "\(mins) mins"
            
            if isRiderInRide {
                // Trip Phase: 50% -> 100%
                self.progressRatio = 0.5 + (0.5 * (1.0 - min(etaSeconds / 1800.0, 1.0)))
            } else {
                // Pickup Phase: 0% -> 50%
                self.progressRatio = 0.1 + (0.4 * (1.0 - min(etaSeconds / 1200.0, 1.0)))
            }
        } else {
            self.eta = "Soon"
            self.progressRatio = isArrived ? 1.0 : (isRiderInRide ? 0.75 : 0.25)
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

                if vm.isArrived {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thank you for your ride!").font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        HStack {
                            Text("Ride arrived").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                            Text("✅").font(.system(size: 24))
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center, spacing: 4) {
                            Text(vm.status).font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.8))
                            Text("[\(vm.debugStatus)]").font(.system(size: 8)).foregroundColor(.white.opacity(0.3))
                        }
                        
                        let isSoon = vm.eta.lowercased().contains("soon") || vm.eta.isEmpty
                        let term = vm.isRiderInRide ? "Drop-off" : "Pickup"
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
            
            // 🏷️ Logo Area (Using bundled asset)
            VStack {
                Image("selcom_go_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
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

                    Text(vm.isArrived ? "Done" : vm.eta.lowercased())
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
