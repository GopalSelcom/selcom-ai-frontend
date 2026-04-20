import WidgetKit
import SwiftUI

@main
struct RiderTrackingWidgetBundle: WidgetBundle {
    var body: some Widget {
        RiderTrackingWidget()
        RiderTrackingWidgetLiveActivity()
    }
}
