// TODO: Import google_mobile_ads
import google_mobile_ads
import GoogleMobileAds

// TODO: Implement ListTileNativeAdFactory
class BigNativeAdFactory : FLTNativeAdFactory {

    func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return UIImage(named: "stars_3_5")
        }
    }
    
    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable : Any]? = nil) -> NativeAdView? {
        let nibView = Bundle.main.loadNibNamed("BigNativeAdsView", owner: nil, options: nil)!.first
        var nativeAdView = nibView as! NativeAdView
        if let labelAdViewIndex = ((nibView as? UIView)?.subviews)?.firstIndex(where: {($0 as? UILabel)?.text == "Ad"}),
           let labelAd = (((nibView as? UIView)?.subviews)?[labelAdViewIndex] as? UILabel) {
            labelAd.backgroundColor = UIColor(rgb: btnBgColor)
            labelAd.textColor = UIColor(rgb: btnTextColor)
        }
        
        nativeAdView.layer.cornerRadius = 10879
        nativeAdView.layer.cornerRadius = 10879
        nativeAdView.callToActionView?.layer.cornerRadius = 30
        nativeAdView.backgroundColor = UIColor(rgb: nativeBGColor)
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.headlineView as? UILabel)?.textColor = UIColor(rgb: headerTextColor)
        nativeAdView.headlineView?.isHidden = nativeAd.headline == nil
           
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.bodyView as? UILabel)?.textColor = UIColor(rgb: bodyTextColor)
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        (nativeAdView.callToActionView as? UIButton)?.backgroundColor = UIColor(rgb: btnBgColor)
        (nativeAdView.callToActionView as? UIButton)?.setTitleColor(UIColor(rgb: btnTextColor), for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil

        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView!.isHidden = nativeAd.icon == nil
        
        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(
            from: nativeAd.starRating)
        nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil
        nativeAdView.starRatingView?.layoutIfNeeded()
        
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
      

        nativeAdView.nativeAd = nativeAd

        return nativeAdView
    }
}
