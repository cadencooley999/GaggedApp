import SwiftUI

//struct MyArrow: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        let width = rect.size.width
//        let height = rect.size.height
//        path.move(to: CGPoint(x: 0.73804*width, y: 0.72216*height))
//            path.addCurve(to: CGPoint(x: 0.73804*width, y: 0.78156*height), control1: CGPoint(x: 0.75444*width, y: 0.73856*height), control2: CGPoint(x: 0.75444*width, y: 0.76516*height))
//            path.addLine(to: CGPoint(x: 0.54264*width, y: 0.97696*height))
//            path.addCurve(to: CGPoint(x: 0.51016*width, y: 0.99656*height), control1: CGPoint(x: 0.53572*width, y: 0.988*height), control2: CGPoint(x: 0.52388*width, y: 0.99556*height))
//            path.addCurve(to: CGPoint(x: 0.50532*width, y: 0.99688*height), control1: CGPoint(x: 0.50856*width, y: 0.99676*height), control2: CGPoint(x: 0.50692*width, y: 0.99688*height))
//            path.addCurve(to: CGPoint(x: 0.50492*width, y: 0.99688*height), control1: CGPoint(x: 0.50516*width, y: 0.99688*height), control2: CGPoint(x: 0.50504*width, y: 0.99688*height))
//            path.addCurve(to: CGPoint(x: 0.50452*width, y: 0.99688*height), control1: CGPoint(x: 0.50476*width, y: 0.99688*height), control2: CGPoint(x: 0.50464*width, y: 0.99688*height))
//            path.addCurve(to: CGPoint(x: 0.47484*width, y: 0.98456*height), control1: CGPoint(x: 0.4938*width, y: 0.99688*height), control2: CGPoint(x: 0.48304*width, y: 0.99276*height))
//            path.addLine(to: CGPoint(x: 0.27184*width, y: 0.78156*height))
//            path.addCurve(to: CGPoint(x: 0.27184*width, y: 0.72216*height), control1: CGPoint(x: 0.25544*width, y: 0.76516*height), control2: CGPoint(x: 0.25544*width, y: 0.73856*height))
//            path.addCurve(to: CGPoint(x: 0.33124*width, y: 0.72216*height), control1: CGPoint(x: 0.28824*width, y: 0.70576*height), control2: CGPoint(x: 0.31484*width, y: 0.70576*height))
//            path.addLine(to: CGPoint(x: 0.46504*width, y: 0.85596*height))
//            path.addLine(to: CGPoint(x: 0.46504*width, y: 0.04272*height))
//            path.addCurve(to: CGPoint(x: 0.50704*width, y: 0.00072*height), control1: CGPoint(x: 0.46504*width, y: 0.01952*height), control2: CGPoint(x: 0.48384*width, y: 0.00072*height))
//            path.addCurve(to: CGPoint(x: 0.54904*width, y: 0.04272*height), control1: CGPoint(x: 0.53024*width, y: 0.00072*height), control2: CGPoint(x: 0.54904*width, y: 0.01952*height))
//            path.addLine(to: CGPoint(x: 0.54904*width, y: 0.85176*height))
//            path.addLine(to: CGPoint(x: 0.6786*width, y: 0.72216*height))
//            path.addCurve(to: CGPoint(x: 0.738*width, y: 0.72216*height), control1: CGPoint(x: 0.695*width, y: 0.70576*height), control2: CGPoint(x: 0.7216*width, y: 0.70576*height))
//            path.closeSubpath()
//            return path
//        }
//}
