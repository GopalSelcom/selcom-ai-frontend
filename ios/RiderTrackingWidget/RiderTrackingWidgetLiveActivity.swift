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
        public var eta_seconds: Double?
        public var is_completed: Bool?
        public var driver_latitude: Double?
        public var driver_longitude: Double?

        enum CodingKeys: String, CodingKey {
            case status, driver_name = "driver_name", vehicle_name = "vehicle_name", plate_number = "plate_number"
            case driver_avatar_url = "driver_avatar_url", eta_seconds = "eta_seconds"
            case is_completed = "is_completed", driver_latitude = "driver_latitude", driver_longitude = "driver_longitude"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            func decodeAsString(_ key: CodingKeys) -> String? {
                if let val = try? container.decode(String.self, forKey: key) { return val }
                if let val = try? container.decode(Int.self, forKey: key) { return String(val) }
                if let val = try? container.decode(Double.self, forKey: key) { return String(val) }
                if let val = try? container.decode(Bool.self, forKey: key) { return String(val) }
                return nil
            }
            func decodeAsDouble(_ key: CodingKeys) -> Double? {
                if let val = try? container.decode(Double.self, forKey: key) { return val }
                if let val = try? container.decode(Int.self, forKey: key) { return Double(val) }
                if let str = try? container.decode(String.self, forKey: key), let val = Double(str) { return val }
                return nil
            }
            func decodeAsBool(_ key: CodingKeys) -> Bool? {
                if let val = try? container.decode(Bool.self, forKey: key) { return val }
                if let val = try? container.decode(Int.self, forKey: key) { return val == 1 }
                if let str = try? container.decode(String.self, forKey: key) {
                    let s = str.lowercased()
                    return s == "true" || s == "1" || s == "yes"
                }
                return nil
            }

            status = decodeAsString(.status)
            driver_name = decodeAsString(.driver_name)
            vehicle_name = decodeAsString(.vehicle_name)
            plate_number = decodeAsString(.plate_number)
            driver_avatar_url = decodeAsString(.driver_avatar_url)
            eta_seconds = decodeAsDouble(.eta_seconds)
            is_completed = decodeAsBool(.is_completed)
            driver_latitude = decodeAsDouble(.driver_latitude)
            driver_longitude = decodeAsDouble(.driver_longitude)
        }
    }
    // This ID must be present and will be automatically populated by the plugin
    var id: UUID
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

// MARK: - Optimized View Model
struct TrackingViewModel {
    let status: String
    let driverName: String
    let driverAvatarUrl: String
    let vehicleName: String
    let plateNumber: String
    let eta: String
    let shortEta: String
    let progressRatio: Double
    let isRiderInRide: Bool
    let isArrived: Bool
    let debugStatus: String 
    let targetDate: Date? 
    let dataSource: String // DEBUG: "Server" or "Local"
    
    init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
        let attrs = context.attributes
        let ud = UserDefaults(suiteName: "group.com.selcom.go")
        var currentDataSource = "Local"
        
        func read(_ key: String) -> String? {
            let st = context.state
            var nativeValue: String? = nil
            switch key {
                case "status":            nativeValue = st.status
                case "driver_name":       nativeValue = st.driver_name
                case "vehicle_name":      nativeValue = st.vehicle_name
                case "plate_number":      nativeValue = st.plate_number
                case "driver_avatar_url": nativeValue = st.driver_avatar_url
                case "eta_seconds":       nativeValue = st.eta_seconds != nil ? String(st.eta_seconds!) : nil
                case "is_completed":      nativeValue = st.is_completed != nil ? String(st.is_completed!) : nil
                default:                  nativeValue = nil
            }

            if let val = nativeValue, !val.isEmpty {
                currentDataSource = "Server"
                return val
            }

            if let cachedValue = ud?.string(forKey: attrs.prefixedKey(key)), !cachedValue.isEmpty {
                currentDataSource = "Local"
                return cachedValue
            }
            return nil
        }

        let rawStatus          = read("status") ?? "finding_driver"
        self.dataSource        = currentDataSource
        self.debugStatus       = rawStatus
        let normalizedStatus   = rawStatus.lowercased()
        
        let rawEtaSecondsStr   = read("eta_seconds") ?? "0"
        var etaSeconds         = Double(rawEtaSecondsStr) ?? 0
        
        let isCompletedStr     = read("is_completed") ?? "false"
        self.isArrived         = isCompletedStr.lowercased() == "true" || normalizedStatus.contains("completed")

        // 🕰️ Robust ETA: If server sends 0 but we aren't arrived, try to use cached value.
        // We also check if the "Server" value was actually 0 to ensure we don't overwrite a deliberate 0.
        if (etaSeconds <= 0) && !self.isArrived {
            if let cachedEtaStr = ud?.string(forKey: attrs.prefixedKey("eta_seconds")),
               let cachedEta = Double(cachedEtaStr), cachedEta > 0 {
                etaSeconds = cachedEta
                currentDataSource = "Local (Recovered)"
            }
        }

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
        
        func formatDuration(_ seconds: Double, short: Bool = false) -> String {
            let totalSeconds = Int(max(0, seconds))
            if totalSeconds < 60 {
                return "\(totalSeconds)s"
            }
            
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            
            if hours > 0 {
                if short {
                    return "\(hours)h \(minutes)m"
                } else {
                    let hPart = "\(hours) \(hours == 1 ? "hr" : "hrs")"
                    if minutes > 0 {
                        let mPart = "\(minutes) \(minutes == 1 ? "min" : "mins")"
                        return "\(hPart) \(mPart)"
                    } else {
                        return hPart
                    }
                }
            } else {
                if short {
                    return "\(minutes)m"
                } else {
                    return "\(minutes) \(minutes == 1 ? "min" : "mins")"
                }
            }
        }

        // 🕰️ ETA & Progress Logic
        if isArrived {
            self.eta = "Arrived"
            self.shortEta = "Done"
            self.targetDate = nil
            self.progressRatio = 1.0
        } else if etaSeconds > 0 {
            self.eta = formatDuration(etaSeconds)
            self.shortEta = formatDuration(etaSeconds, short: true)
            
            self.targetDate = Date().addingTimeInterval(etaSeconds)
            
            if isRiderInRide {
                // Trip Phase: 50% -> 100%
                self.progressRatio = 0.5 + (0.5 * (1.0 - min(etaSeconds / 1800.0, 1.0)))
            } else {
                // Pickup Phase: 0% -> 50%
                self.progressRatio = 0.1 + (0.4 * (1.0 - min(etaSeconds / 1200.0, 1.0)))
            }
        } else {
            if normalizedStatus == "searching" || normalizedStatus == "finding_driver" || normalizedStatus == "finding driver" {
                self.eta = "Soon"
                self.shortEta = "Soon"
            } else {
                self.eta = self.isArrived ? "Done" : "Soon"
                self.shortEta = self.isArrived ? "Done" : "Soon"
            }
            self.targetDate = nil
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
                    Text("Selcom Go").font(.system(size: 16, weight: .black)).foregroundColor(.white)
                }
                .padding(.bottom, 6)

                if vm.isArrived {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Hope you had a great ride!").font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.8))
                            Text(vm.dataSource == "Server" ? "📡" : "💾").font(.system(size: 8)) // Debug sync indicator
                        }
                        HStack {
                            Text("Arrived at Destination").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                            Text("✅").font(.system(size: 24))
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center, spacing: 4) {
                            Text(vm.status).font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        }
                        
                        let isSoon = vm.eta.lowercased().contains("soon") || vm.eta.isEmpty
                        let term = vm.isRiderInRide ? "Drop-off" : "Pickup"
                        let prefix = isSoon ? term : "\(term) in"
                        let displayEta = isSoon ? "soon" : vm.eta.lowercased()

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(prefix).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            if let target = vm.targetDate {
                                Text(target, style: .relative)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(displayEta).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                            }
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
                    Image("selcom_go_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                ZStack {
                    Capsule()
                        .stroke(selcomRed.opacity(0.5), lineWidth: 2)
                        .frame(width: 54, height: 22)

                    if vm.isArrived {
                        Text("Done")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                    } else if let target = vm.targetDate {
                        Text(target, style: .relative)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                    } else {
                        Text(vm.shortEta.lowercased())
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.leading, 6)
            } minimal: {
                Circle().fill(selcomRed).frame(width: 22, height: 22)
            }
            .keylineTint(selcomRed)
        }
    }
}
