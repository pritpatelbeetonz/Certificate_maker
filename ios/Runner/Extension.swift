//
//  Extension.swift
//  Runner
//
//  Created by beetonz on 18/06/24.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: (CGFloat(red) / 255.0), green: (CGFloat(green) / 255.0), blue: (CGFloat(blue) / 255.0), alpha: 1.0)
    }
    
    convenience init(rgb: String) {
        let hexString: String = rgb.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let scanner = Scanner(string: hexString)
        
        if #available(iOS 13.0, *) {
            if (hexString.hasPrefix("#")) {
                scanner.currentIndex = hexString.index(after: hexString.firstIndex(of: "#")!)
            }
        } else {
            if (hexString.hasPrefix("#")) {
                scanner.scanLocation = 1
            }
        }
        
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        self.init(red: Int(color >> 16) & 0xFF, green: Int(color >> 8) & 0xFF, blue: Int(color) & 0xFF, alpha: Int(1.0))
    }
    
    public func toHexString() -> String {
        let cgColorInRGB = cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)!
        let colorRef = cgColorInRGB.components
        let r = colorRef?[0] ?? 0
        let g = colorRef?[1] ?? 0
        let b = ((colorRef?.count ?? 0) > 2 ? colorRef?[2] : g) ?? 0
        
        let color = String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        
        return color
    }
}
