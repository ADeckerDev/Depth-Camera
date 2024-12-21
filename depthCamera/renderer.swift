import UIKit

func CVPixelRender(from pixelBuffer: CVPixelBuffer, palette: Palette, scale: Float, offset: Float) -> UIImage? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    
    // Get the base address and row bytes of the buffer
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
    let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    // Create a Core Graphics image context
    UIGraphicsBeginImageContextWithOptions(CGSize(width: height, height: width), false, 1.0)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    // Rotate the context 90 degrees clockwise
    context.translateBy(x: CGFloat(height) / 2, y: CGFloat(width) / 2)
    context.rotate(by: .pi / 2)
    context.translateBy(x: -CGFloat(width) / 2, y: -CGFloat(height) / 2)
    
    for y in 0..<height {
        let row = baseAddress.advanced(by: y * rowBytes)
        let pixelPointer = row.assumingMemoryBound(to: Float32.self) // Assuming the buffer holds Float32 depth values
        
        for x in 0..<width {
            let distance = pixelPointer[x]
            let adjustedValue = (distance + offset) * scale
            let color = palette.getColor(n: adjustedValue) // Get color from palette based on distance
            
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
    }
    
    // Extract the image from the context
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}



func lidarRender(palette: Palette, scale: Float, offset: Float) -> UIImage? {
    return nil
}

func testRender(palette: Palette, scale: Float, offset: Float) -> UIImage? {
    let width = 480
    let height = 640
    
    // Create a Core Graphics image context
    UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    for y in 0..<height {
        let color = palette.getColor(n: (Float(y) + offset) * scale) // Get color based on y-coordinate
        context.setFillColor(color.cgColor)

        // Draw a horizontal line (row) of the specified color
        context.fill(CGRect(x: 0, y: y, width: width, height: 1))
    }
    
    // Extract the image from the context
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}
