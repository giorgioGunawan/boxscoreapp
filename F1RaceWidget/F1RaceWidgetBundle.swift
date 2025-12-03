import WidgetKit
import SwiftUI

@main
struct F1RaceWidgetBundle: WidgetBundle {
    var body: some Widget {
        F1RaceWidget()
        F1CompleteLockScreenWidget()
        F1CompactLockScreenWidget()
        F1CountdownLockScreenWidget()
        F1DriverStandingWidget()
        F1DriverStandingLockScreenWidget()
        F1ConstructorStandingWidget()
        F1ConstructorStandingLockScreenWidget()
        F1TopDriversLockScreenWidget()
        F1TopConstructorsLockScreenWidget()
    }
} 