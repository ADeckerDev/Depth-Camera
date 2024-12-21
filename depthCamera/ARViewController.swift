import ARKit

final class ARViewController: NSObject, ARSessionDelegate {
    
    // Singleton instance
    static let shared = ARViewController()
    
    private let session = ARSession()
    private var currentSessionType: SessionType = .none
    private var frameCaptured = false
    private var capturedPixelBuffer: CVPixelBuffer?
    
    private enum SessionType {
        case none
        case ir
        case lidar
        case faceTracking
    }
    
    private override init() {
        super.init()
        session.delegate = self
    }
    
    // Public method to get the raw IR depth frame
    func getFrameIR() -> CVPixelBuffer? {
        switchSessionIfNeeded(to: .ir)
        return waitForFrame { frame in
            frame.sceneDepth?.depthMap // IR uses sceneDepth (raw IR depth data)
        }
    }
    
    // Public method to get the smoothed LiDAR depth frame
    func getFrameIRSmooth() -> CVPixelBuffer? {
        switchSessionIfNeeded(to: .lidar)
        return waitForFrame { frame in
            frame.smoothedSceneDepth?.depthMap // LiDAR uses smoothedSceneDepth (processed LiDAR depth data)
        }
    }
    
    func getFrameIRSelfie() -> CVPixelBuffer? {
        switchSessionIfNeeded(to: .faceTracking)
        return waitForFrame { frame in
            if let depthMap = frame.sceneDepth?.depthMap {
                return depthMap
            } else {
                print("Fallback to captured image buffer.")
                return frame.capturedImage
            }
        }
    }
    
    // Starts the ARSession with necessary configuration
    private func startSession(for type: SessionType) {
        switch type {
        case .ir:
            let configuration = ARWorldTrackingConfiguration()
            configuration.frameSemantics = [.sceneDepth]
            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        case .lidar:
            let configuration = ARWorldTrackingConfiguration()
            configuration.frameSemantics = [.smoothedSceneDepth]
            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        case .faceTracking:
            guard ARFaceTrackingConfiguration.isSupported else {
                print("ARFaceTrackingConfiguration is not supported on this device.")
                return
            }
            let faceConfiguration = ARFaceTrackingConfiguration()
            print("Face Tracking was just used")
            faceConfiguration.isLightEstimationEnabled = true
            session.run(faceConfiguration, options: [.resetTracking, .removeExistingAnchors])
            print("Started ARFaceTrackingConfiguration.")
        case .none:
            stopSession()
        }
        currentSessionType = type
    }

    
    // Pauses the ARSession
    private func stopSession() {
        session.pause()
        currentSessionType = .none
    }
    
    // Switch session if the current one doesn't match the requested type
    private func switchSessionIfNeeded(to newType: SessionType) {
        guard currentSessionType != newType else { return }
        stopSession()
        startSession(for: newType)
    }
    
    // Wait for the first frame of the session and return the processed result
    private func waitForFrame(process: (ARFrame) -> CVPixelBuffer?) -> CVPixelBuffer? {
        frameCaptured = false
        capturedPixelBuffer = nil
        
        // Wait until a frame is captured
        while !frameCaptured {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
        
        return capturedPixelBuffer
    }
    
    // ARSessionDelegate method to handle frame updates
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if !frameCaptured {
            capturedPixelBuffer = frame.sceneDepth?.depthMap ?? frame.smoothedSceneDepth?.depthMap
            frameCaptured = true
        }
    }
}

