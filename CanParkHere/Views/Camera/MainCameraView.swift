//
//  MainCameraView.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI
import AVFoundation

struct MainCameraView: View {
    @StateObject private var cameraModel = CameraModel()
    @StateObject private var viewModel: CameraViewModel
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var showImagePicker = false
    @State private var showHistory = false
    @State private var showSettings = false
    
    init() {
        // This is a workaround to inject userPreferences into StateObject
        _viewModel = StateObject(wrappedValue: CameraViewModel(userPreferences: UserPreferences()))
    }
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(cameraModel: cameraModel)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    if viewModel.isProcessing {
                        ProgressView("Analyzing...")
                            .padding()
                            .background(Capsule().fill(Color.black.opacity(0.7)))
                            .foregroundColor(.white)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .padding()
                            .background(Capsule().fill(Color.red.opacity(0.8)))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 50) {
                        // Gallery button
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        // Capture button
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                            }
                        }
                        .disabled(viewModel.isProcessing)
                        
                        // Flash toggle
                        Button(action: { cameraModel.toggleFlash() }) {
                            Image(systemName: cameraModel.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: Binding(
                get: { nil },
                set: { image in
                    if let image = image {
                        Task {
                            await viewModel.processImage(image)
                        }
                    }
                }
            ))
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $viewModel.showResult) {
            if let decision = viewModel.parkingDecision {
                ParkingResultView(
                    decision: decision,
                    image: viewModel.capturedImage,
                    onDismiss: {
                        viewModel.showResult = false
                        viewModel.parkingDecision = nil
                        viewModel.capturedImage = nil
                    }
                )
            }
        }
        .onAppear {
            cameraModel.checkPermissions()
        }
    }
    
    func capturePhoto() {
        cameraModel.capturePhoto { image in
            if let image = image {
                Task {
                    await viewModel.processImage(image)
                }
            }
        }
    }
}

class CameraModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    private var photoOutput = AVCapturePhotoOutput()
    private var photoCompletion: ((UIImage?) -> Void)?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }
    
    func setupCamera() {
        session.beginConfiguration()
        
        // Add input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Add output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        
        // Start session
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCompletion?(nil)
            return
        }
        
        photoCompletion?(image)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraModel: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraModel.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        cameraModel.preview = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
