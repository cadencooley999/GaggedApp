//
//  CapsulePlusShape.swift
//  GaggedApp
//
//  Created by Caden Cooley on 1/11/26.
//
import SwiftUI

struct CapsuleCircleBridgeShape: Shape {
    var bridgeWidth: CGFloat = 16   // distance between shapes
    var bridgeHeightRatio: CGFloat = 0.45 // thickness of bridge

    func path(in rect: CGRect) -> Path {
        let height = rect.height
        let radius = height / 2
        let circleDiameter = height

        let bridgeHeight = height * bridgeHeightRatio
        let bridgeY = (height - bridgeHeight) / 2

        var path = Path()

        // Circle (left)
        let circleRect = CGRect(
            x: 0,
            y: 0,
            width: circleDiameter,
            height: circleDiameter
        )
        path.addEllipse(in: circleRect)

        // Capsule (right)
        let capsuleRect = CGRect(
            x: circleDiameter + bridgeWidth,
            y: 0,
            width: rect.width - circleDiameter - bridgeWidth,
            height: height
        )
        path.addRoundedRect(
            in: capsuleRect,
            cornerSize: CGSize(width: radius, height: radius)
        )

        // Bridge
        let bridgeRect = CGRect(
            x: circleDiameter,
            y: bridgeY,
            width: bridgeWidth,
            height: bridgeHeight
        )
        path.addRoundedRect(
            in: bridgeRect,
            cornerSize: CGSize(
                width: bridgeHeight / 2,
                height: bridgeHeight / 2
            )
        )

        return path
    }
}

