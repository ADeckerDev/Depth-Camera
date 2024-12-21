import SwiftUI
import Combine

@main
struct depthCameraApp: App {
    @State private var scale: Float = 1
    @State private var offset: Float = 0
    @State private var selectedPalette: SelfPalette = .cos
    @State private var currentFrame: UIImage? = nil // Image object for display
    @State private var timer: AnyCancellable? // Timer for 60 FPS rendering
    @State private var isRecording: Bool = false
    
    //Palettes
    @State private var coswaveOBJ: Palette = cosWave()
    @State private var singlerpOBJ: Palette = singLerp()
    @State private var polylerpOBJ: Palette = polyLerp()
    
    @State public var frameRate: Double = 24
    
    enum SelfPalette {
        case cos
        case sing
        case poly
    }
    
    enum Source {
        case InfaRed // resolution of 256x192
        case Lidar // Resolution of 640x480
        case Test // used to test the palettes
    }
    
    @State private var source: Source = Source.InfaRed

    var body: some Scene {
        WindowGroup {
            MainView(
                scale: $scale,
                offset: $offset,
                selectedPalette: $selectedPalette,
                currentFrame: $currentFrame,
                isRecording: $isRecording,
                source: $source
            )
            .onAppear {
                startRenderingLoop()
            }
            .onDisappear {
                stopRenderingLoop()
            }
        }
    }
        func startRenderingLoop() {
            timer = Timer.publish(every: 1.0 / frameRate, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    renderFrame()
                }
        }
        
        func stopRenderingLoop() {
            timer?.cancel()
        }
        
        // Rendering function, fixed time loop 60fps
    func renderFrame() {
        
        //Get the current palette
        var currentPalette = coswaveOBJ
        switch selectedPalette {
        case .sing:
            currentPalette = singlerpOBJ
        case .poly:
            currentPalette = polylerpOBJ
        case .cos:
            break
        }


        if source == depthCameraApp.Source.Test{
            currentFrame = testRender(palette: currentPalette, scale: scale, offset: offset)
            return
        }
        var depthMap: CVPixelBuffer
        if source == .InfaRed {
            guard let irDepthMap = ARViewController.shared.getFrameIR() else {
                // Handle nil case
                print("Failed to get IR depth map")
                return
            }
            depthMap = irDepthMap
        }
        else if source == .Lidar {
            guard let lidarDepthMap = ARViewController.shared.getFrameIRSelfie() else {
                // Handle nil case
                print("Failed to get LiDAR depth map")
                return
            }
            print("got lidar map supposedly")
            depthMap = lidarDepthMap
        } else{
            print("Invalid source type")
            return
        }
        
        
        currentFrame = CVPixelRender(from: depthMap, palette: currentPalette, scale: scale, offset: offset)
        
    }
}



struct MainView: View {
    @Binding var scale: Float
    @Binding var offset: Float
    @Binding var selectedPalette: depthCameraApp.SelfPalette
    @Binding var currentFrame: UIImage?
    @Binding var isRecording: Bool
    @Binding var source: depthCameraApp.Source

    var body: some View {
        ZStack() {
            let imageWidth: CGFloat = 480
            let imageHeight: CGFloat = 640
            let scaleFactor = min((UIScreen.main.bounds.width * 0.85) / imageWidth, (UIScreen.main.bounds.height * 0.85) / imageHeight)

            if let image = currentFrame {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth * scaleFactor, height: imageHeight * scaleFactor)
                    .background(Color.gray.opacity(0.2))
                    .offset(x: -20, y: -150)
            } else {
                Text("No Frame Rendered")
                    .frame(width: imageWidth * scaleFactor, height: imageHeight * scaleFactor)
                    .background(Color.gray.opacity(0.2))
                    .offset(x: -20, y: -150)
            }
            
            // Scale Slider
            SpecificSlider(value: $scale, sensitivity: 0.0001, orientation: .vertical)
                .frame(width: 50, height: 450)
                .background(Color.gray.opacity(0.2))
                .offset(x: 175, y: -150) // make taller
            
            // Offset Slider
            SpecificSlider(value: $offset, sensitivity: 0.001, orientation: .horizontal)
                .frame(width: 400, height: 45)
                .background(Color.gray.opacity(0.2))
                .offset(x: 0, y: 100)
            
            Picker("Select Palette", selection: $selectedPalette) {
                Text("Cosine").tag(depthCameraApp.SelfPalette.cos)
                Text("Singular").tag(depthCameraApp.SelfPalette.sing)
                Text("Poly").tag(depthCameraApp.SelfPalette.poly)
            }
            .offset(x: 140, y: 200)
            
            
            
            // Value Names
            Text("OFFSET:")
                .font(.subheadline)
                .position(x: 130, y: 475)
            
            Text("SCALE:")
                .font(.subheadline)
                .position(x: 360, y: -10)
            
            
            //capture button:
            Button(action: {
                print("Round Button Pressed!")
            }) {
                Image(systemName: "plus") // Replace with any SF Symbol or text
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.blue))
                    // Circular background
            }
            .offset(x:0, y:200)
            
            Toggle(isOn: $isRecording) {
                EmptyView()
            }
            .labelsHidden()
            .offset(x: 0, y: 280) // Adjust position if needed
            
            
            Button(action: {
                print("Config")
            }) {
                Text("Config")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .underline()
                    .padding()
            }
            .offset(x:133, y:270)
            
            
            Picker("Source", selection: $source) {
                Text("InfaRed").tag(depthCameraApp.Source.InfaRed)
                Text("Lidar").tag(depthCameraApp.Source.Lidar)
                Text("Test").tag(depthCameraApp.Source.Test)
            }
            .offset(x: 0, y: 350)
            
            //end
        }
        .padding()
    }
}

struct SpecificSlider: View {
    @Binding var value: Float
    let minValue: Float = 0
    let maxValue: Float = 1000
    let sensitivity: Float
    let orientation: Orientation

    enum Orientation {
        case vertical
        case horizontal
    }

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(10)
                .overlay(
                    Text("\(value, specifier: "%.2f")")
                        .foregroundColor(.white)
                        .bold()
                )
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let delta: Float
                            
                            switch orientation {
                            case .vertical:
                                // Normalize drag against geometry height and scale by sensitivity
                                delta = Float(-gesture.translation.height / geometry.size.height) * (maxValue - minValue) * sensitivity
                            case .horizontal:
                                // Normalize drag against geometry width and scale by sensitivity
                                delta = Float(gesture.translation.width / geometry.size.width) * (maxValue - minValue) * sensitivity
                            }

                            let newValue = value + delta
                            value = max(minValue, min(newValue, maxValue)) // Clamp value within range
                        }
                )
                .frame(
                    width: orientation == .horizontal ? geometry.size.width : 50,
                    height: orientation == .vertical ? geometry.size.height : 50
                )
        }
    }
}

// SwiftUI Preview
#Preview {
    MainView(
        scale: .constant(1.0),
        offset: .constant(0.0),
        selectedPalette: .constant(.cos),
        currentFrame: .constant(nil),
        isRecording: .constant(false),
        source: .constant(.InfaRed)
        
    )
}


