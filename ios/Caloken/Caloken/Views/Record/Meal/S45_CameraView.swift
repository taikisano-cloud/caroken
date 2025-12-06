import SwiftUI
import AVFoundation
import Combine

struct S45_CameraView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var showHelpSheet = false
    @State private var selectedImage: UIImage?
    @State private var scanMode: ScanMode = .food
    @State private var isFlashOn = false
    @State private var cameraPermissionGranted = false
    
    @StateObject private var cameraManager = CameraManager()
    
    enum ScanMode {
        case food
        case label
    }
    
    var body: some View {
        ZStack {
            // カメラプレビュー
            if cameraPermissionGranted {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("カメラへのアクセスを許可してください")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Button("設定を開く") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
            
            // オーバーレイUI
            VStack(spacing: 0) {
                // 上部バー
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: { showHelpSheet = true }) {
                        Image(systemName: "questionmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer()
                
                // スキャンフレーム
                if cameraPermissionGranted {
                    VStack(spacing: 16) {
                        Text("ラベルスキャナー")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(scanMode == .label ? 1 : 0)
                        
                        ZStack {
                            FoodScanFrameView()
                                .opacity(scanMode == .food ? 1 : 0)
                            LabelScanFrameView()
                                .opacity(scanMode == .label ? 1 : 0)
                        }
                        .frame(width: 320, height: 380)
                        .animation(.easeInOut(duration: 0.25), value: scanMode)
                    }
                }
                
                Spacer()
                
                // 下部コントロール
                VStack(spacing: 20) {
                    // モード選択タブ
                    HStack(spacing: 8) {
                        ModeTabButton(
                            title: "食事をスキャン",
                            icon: "arrow.triangle.2.circlepath",
                            isSelected: scanMode == .food
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scanMode = .food
                            }
                        }
                        
                        ModeTabButton(
                            title: "栄養成分表示",
                            icon: "tag.fill",
                            isSelected: scanMode == .label
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scanMode = .label
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 撮影ボタン
                    HStack {
                        // フラッシュ（トーチモード）
                        Button(action: {
                            isFlashOn.toggle()
                            cameraManager.setTorch(isFlashOn)
                        }) {
                            Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 22))
                                .foregroundColor(isFlashOn ? .yellow : .white)
                                .frame(width: 56, height: 56)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // 撮影
                        Button(action: {
                            cameraManager.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 66, height: 66)
                            }
                        }
                        
                        Spacer()
                        
                        // ライブラリ
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            checkCameraPermission()
            cameraManager.onPhotoCaptured = { image in
                selectedImage = image
            }
        }
        .onDisappear {
            if isFlashOn {
                cameraManager.setTorch(false)
            }
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showImagePicker) {
            CameraImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showHelpSheet) {
            if scanMode == .label {
                LabelHelpSheet()
            } else {
                FoodHelpSheet()
            }
        }
        .onChange(of: selectedImage) { _, newValue in
            if let image = newValue {
                // フラッシュをオフ
                if isFlashOn {
                    cameraManager.setTorch(false)
                }
                // ホーム画面のログに追加して分析開始
                AnalyzingManager.shared.startMealAnalyzing(image: image, for: Date())
                // ホームに戻る
                dismiss()
            }
        }
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                }
            }
        case .denied, .restricted:
            cameraPermissionGranted = false
        @unknown default:
            cameraPermissionGranted = false
        }
    }
}

// MARK: - CameraManager
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var currentDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var onPhotoCaptured: ((UIImage) -> Void)?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        currentDevice = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            }
        } catch {
            print("カメラ設定エラー: \(error)")
        }
    }
    
    func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput,
              let session = captureSession,
              session.isRunning else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func setTorch(_ isOn: Bool) {
        guard let device = currentDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("トーチ設定エラー: \(error)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("撮影エラー: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("画像データ変換エラー")
            return
        }
        
        DispatchQueue.main.async {
            self.onPhotoCaptured?(image)
        }
    }
}

// MARK: - CameraPreviewView
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        
        if let session = cameraManager.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            view.previewLayer = previewLayer
            view.layer.addSublayer(previewLayer)
            cameraManager.previewLayer = previewLayer
        }
        
        cameraManager.startSession()
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        DispatchQueue.main.async {
            uiView.previewLayer?.frame = uiView.bounds
        }
    }
}

class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

// MARK: - 食事用スキャンフレーム
struct FoodScanFrameView: View {
    var body: some View {
        GeometryReader { geometry in
            let cornerLength: CGFloat = 50
            let lineWidth: CGFloat = 4
            let cornerRadius: CGFloat = 20
            
            ZStack {
                // 左上
                Path { path in
                    path.move(to: CGPoint(x: 0, y: cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: cornerRadius))
                    path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0), control: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // 右上
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width - cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width - cornerRadius, y: 0))
                    path.addQuadCurve(to: CGPoint(x: geometry.size.width, y: cornerRadius), control: CGPoint(x: geometry.size.width, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: cornerLength))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // 左下
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height - cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height - cornerRadius))
                    path.addQuadCurve(to: CGPoint(x: cornerRadius, y: geometry.size.height), control: CGPoint(x: 0, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: cornerLength, y: geometry.size.height))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // 右下
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width - cornerLength, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: geometry.size.width - cornerRadius, y: geometry.size.height))
                    path.addQuadCurve(to: CGPoint(x: geometry.size.width, y: geometry.size.height - cornerRadius), control: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height - cornerLength))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
    }
}

// MARK: - ラベル用スキャンフレーム
struct LabelScanFrameView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white, lineWidth: 4)
    }
}

// MARK: - モードタブボタン
struct ModeTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .black.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.white : Color.white.opacity(0.85))
            .cornerRadius(30)
        }
    }
}

// MARK: - 食事撮影ヘルプシート
struct FoodHelpSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("最適なスキャン方法")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)
            
            HStack(spacing: 16) {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.1, green: 0.25, blue: 0.15))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    .frame(width: 60, height: 4)
                            }
                        )
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        Text("するべきこと")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.3, green: 0.1, blue: 0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(35))
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    .frame(width: 60, height: 4)
                            }
                        )
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                        Text("してはいけないこと")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("一般的なヒント")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    HintRow(text: "皿を真上から撮影してください")
                    HintRow(text: "すべての食材が映るようにしてください")
                    HintRow(text: "影が少なく明るい照明を確保してください")
                    HintRow(text: "皿全体がフレームに収まるようにしてください")
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.08))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("閉じる")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - ラベルスキャンヘルプシート
struct LabelHelpSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("原材料のスキャン方法")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.18, blue: 0.15))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                        Text("栄養成分表示")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                )
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("最良の結果を得るために以下の手順に従ってください：")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 14) {
                    HintRow(text: "原材料リストがはっきりと見え、十分に明るいことを確認してください")
                    HintRow(text: "スマートフォンを安定して持ち、影や反射を避けてください")
                    HintRow(text: "原材料リスト全体を1枚の写真に収めてください")
                    HintRow(text: "テキストを水平に保ち、パッケージを傾けないでください")
                    HintRow(text: "写真を撮る前に原材料のテキストにタップしてフォーカスしてください")
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.08))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("閉じる")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - ヒント行
struct HintRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - ImagePicker
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
