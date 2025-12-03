import SwiftUI
import WidgetKit

struct PremiumWidgetView: View {
    let widgetFamily: WidgetFamily
    
    var body: some View {
        ZStack {
            VStack(spacing: 5) {
                Image(systemName: "crown.fill")
                    .font(.system(size: widgetFamily == .systemSmall ? 24 : 32))
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text("Upgrade to Pro")
                    .font(.system(size: widgetFamily == .systemSmall ? 14 : 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Tap to upgrade")
                    .font(.system(size: widgetFamily == .systemSmall ? 11 : 13))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.top, widgetFamily == .systemSmall ? 4 : 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(SubscriptionHelper.upgradeURL())
    }
}

#Preview {
    PremiumWidgetView(widgetFamily: .systemSmall)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
} 