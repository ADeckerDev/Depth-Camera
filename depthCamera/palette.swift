//
//  palette.swift
//  depthCamera
//
//  Created by Andrew Decker on 12/12/24.

import Foundation
import CoreGraphics

struct RGBA {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8 = 255

    var cgColor: CGColor {
        return CGColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: CGFloat(1)//CGFloat(alpha) / 255.0
        )
    }
}

//SuperClass
//Scale will be handled in the ui side
public class Palette {
    let waveLength: Float
    init(waveLength: Float) {
        guard type(of: self) != Palette.self else {
            fatalError("Palette is an abstract class and must be subclassed.")
        }
        self.waveLength = waveLength
    }

    func getColor(n: Float = 0) -> RGBA {
        fatalError("Subclasses of Palette must override getColor(at:).")
    }

    func triangleWave(x: Float) -> Float {
        // Calculate the phase within one period
        let phase = x.truncatingRemainder(dividingBy: waveLength)
        let normalizedPhase = (phase >= 0 ? phase : phase + waveLength) / waveLength

        // Compute triangle wave value (bound between 0 and 1)
        if normalizedPhase < 0.5 {
            // Ascending part of the triangle wave
            return 2 * normalizedPhase
        } else {
            // Descending part of the triangle wave
            return 2 * (1 - normalizedPhase)
        }
    }
    
    //render self function
}

let white = RGBA(red: 255, green: 255, blue: 255)
let black = RGBA(red:0, green:0, blue:0)

class singLerp: Palette {
    let startColor: RGBA
    let endColor: RGBA
    init(startColor: RGBA = white, endColor: RGBA = black, waveLength: Float = 256.0) {
        self.startColor = startColor
        self.endColor = endColor
        super.init(waveLength: waveLength)
    }

    override func getColor(n: Float) -> RGBA {
        
        let t = self.triangleWave(x: n)

        // Linear interpolation between startColor and endColor
        let red = UInt8(max(0, min(255, Float(startColor.red) * (1 - t) + Float(endColor.red) * t)))
        let green = UInt8(max(0, min(255, Float(startColor.green) * (1 - t) + Float(endColor.green) * t)))
        let blue = UInt8(max(0, min(255, Float(startColor.blue) * (1 - t) + Float(endColor.blue) * t)))


        return RGBA(red: red, green: green, blue: blue)
    }
}

let red = RGBA(red: 255, green: 0, blue: 0)
let orange = RGBA(red: 255, green: 127, blue: 0)
let yellow = RGBA(red: 255, green: 255, blue: 0)
let green = RGBA(red: 0, green: 255, blue: 0)
let cyan = RGBA(red: 0, green: 255, blue: 255)
let blue = RGBA(red: 0, green: 0, blue: 255)
let violet = RGBA(red: 139, green: 0, blue: 255)

let defaultColors = [red, orange, yellow, green, cyan, blue, violet]

class polyLerp: Palette {
    let colors: [RGBA]
    init(colors: [RGBA] = defaultColors){
        self.colors = colors
        let dynamicWaveLength = Float(colors.count) * 256.0
        super.init(waveLength: dynamicWaveLength)
    }
    
    override func getColor(n: Float) -> RGBA {
        // Scale phase to the number of colors
        let scaledPhase = self.triangleWave(x: n) * Float(colors.count)
        
        // Determine the current and next indices
        let index = Int(scaledPhase) % colors.count
        let nextIndex = (index + 1) % colors.count

        // Compute the fractional part for interpolation
        let t = scaledPhase - Float(index)

        // Linear interpolation between colors
        let red = UInt8(max(0, min(255, Float(colors[index].red) * (1 - t) + Float(colors[nextIndex].red) * t)))
        let green = UInt8(max(0, min(255, Float(colors[index].green) * (1 - t) + Float(colors[nextIndex].green) * t)))
        let blue = UInt8(max(0, min(255, Float(colors[index].blue) * (1 - t) + Float(colors[nextIndex].blue) * t)))

        return RGBA(red: red, green: green, blue: blue)
    }

}

class cosWave: Palette{
    let rTerm: Float
    let gTerm: Float
    let bTerm: Float

    init(rTerm: Float = 11, gTerm: Float = 17, bTerm: Float = 13) {
        self.rTerm = rTerm
        self.gTerm = gTerm
        self.bTerm = bTerm
        super.init(waveLength: Float.infinity)
    }
    
    override func getColor(n: Float = 0) -> RGBA {
        
        let tau = 2 * Float(Double.pi)
        
        let red = UInt8(max(0, min(255, 128 * cos((tau / rTerm) * n) + 128)))
        let green = UInt8(max(0, min(255, 128 * cos((tau / gTerm) * n) + 128)))
        let blue = UInt8(max(0, min(255, 128 * cos((tau / bTerm) * n) + 128)))
        
        return RGBA(red: red, green: green, blue: blue)
    }
}


