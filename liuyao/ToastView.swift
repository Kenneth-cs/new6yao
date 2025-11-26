//
//  ToastView.swift
//  liuyao
//
//  轻量级Toast提示组件
//

import SwiftUI

// MARK: - Toast类型
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Toast配置
struct ToastConfig {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    init(message: String, type: ToastType, duration: TimeInterval = 2.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

// MARK: - Toast View
struct ToastView: View {
    let config: ToastConfig
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: config.type.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text(config.message)
                        .font(.body)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(config.type.color.opacity(0.95))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
        .padding(.bottom, 50)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isShowing)
    }
}

// MARK: - View扩展：简化Toast使用
extension View {
    func toast(config: ToastConfig?, isShowing: Binding<Bool>) -> some View {
        ZStack {
            self
            
            if let config = config {
                ToastView(config: config, isShowing: isShowing)
            }
        }
    }
}

// MARK: - Toast管理器（可选，用于全局Toast）
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toastConfig: ToastConfig?
    @Published var isShowing = false
    
    private init() {}
    
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 2.0) {
        toastConfig = ToastConfig(message: message, type: type, duration: duration)
        withAnimation {
            isShowing = true
        }
    }
    
    func showSuccess(_ message: String) {
        show(message, type: .success)
    }
    
    func showError(_ message: String) {
        show(message, type: .error, duration: 3.0)
    }
    
    func showWarning(_ message: String) {
        show(message, type: .warning)
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("Success Toast") {
            ToastManager.shared.showSuccess("操作成功！")
        }
        
        Button("Error Toast") {
            ToastManager.shared.showError("操作失败，请重试")
        }
        
        Button("Warning Toast") {
            ToastManager.shared.showWarning("请注意网络连接")
        }
    }
    .toast(
        config: ToastManager.shared.toastConfig,
        isShowing: .constant(ToastManager.shared.isShowing)
    )
}

