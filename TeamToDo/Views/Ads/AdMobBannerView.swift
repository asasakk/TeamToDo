import SwiftUI
import GoogleMobileAds

struct AdMobBannerView: View {
    let adUnitID: String
    
    var body: some View {
        HStack {
            Spacer()
            AdMobBannerRepresentable(adSize: AdSizeBanner, adUnitID: adUnitID)
                .frame(width: 320, height: 50)
            Spacer()
        }
    }
}

#Preview {
    AdMobBannerView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
}
