import WidgetKit
import SwiftUI

@main
struct FoodMomentWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieRingWidget()
        QuickScanWidget()

        // iOS 16.1+ Live Activity
        if #available(iOS 16.1, *) {
            MealRecordingLiveActivity()
        }
    }
}
