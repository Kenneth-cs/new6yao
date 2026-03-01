//
//  NotificationSettingsView.swift
//  人生教练
//
//  通知设置视图
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showTimePicker = false
    @State private var nextReminderTime: Date?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部图标
                    headerSection
                    
                    // 主开关
                    mainToggleSection
                    
                    // 时间设置
                    if notificationManager.dailyReminderEnabled {
                        timeSettingSection
                    }
                    
                    // 通知预览
                    if notificationManager.dailyReminderEnabled {
                        previewSection
                    }
                    
                    // 权限状态
                    permissionStatusSection
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("每日提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                notificationManager.checkAuthorizationStatus()
                loadNextReminderTime()
            }
        }
    }
    
    // MARK: - 顶部图标
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 45))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("每日提醒")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("每天定时提醒你摇一摇，看看今日顺势")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - 主开关
    
    private var mainToggleSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("开启每日提醒")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(notificationManager.dailyReminderEnabled ? "已开启" : "已关闭")
                        .font(.caption)
                        .foregroundColor(notificationManager.dailyReminderEnabled ? .green : .secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $notificationManager.dailyReminderEnabled)
                    .labelsHidden()
                    .tint(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - 时间设置
    
    private var timeSettingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("提醒时间")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Button(action: {
                withAnimation {
                    showTimePicker.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    
                    Text("每天 \(notificationManager.formattedReminderTime())")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: showTimePicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if showTimePicker {
                DatePicker(
                    "选择时间",
                    selection: $notificationManager.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .frame(maxHeight: 150)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .onChange(of: notificationManager.reminderTime) { _ in
                    loadNextReminderTime()
                }
            }
            
            // 下次提醒时间
            if let nextTime = nextReminderTime {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                    
                    Text("下次提醒：\(formatNextTime(nextTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - 通知预览
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知预览")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // 模拟通知
                HStack(alignment: .top, spacing: 12) {
                    // App图标
                    Image("NotificationPreviewIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("人生教练")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("现在")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Text(DailyNotificationContentService.shared.cachedTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(DailyNotificationContentService.shared.cachedBody)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.tertiarySystemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - 权限状态
    
    private var permissionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !notificationManager.isAuthorized {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        
                        Text("通知权限未开启")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text("请在系统设置中开启通知权限，才能接收每日提醒")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        notificationManager.openSettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("前往设置")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange)
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("通知权限已开启")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func loadNextReminderTime() {
        notificationManager.getNextReminderTime { time in
            self.nextReminderTime = time
        }
    }
    
    private func formatNextTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "明天 HH:mm"
        } else {
            formatter.dateFormat = "MM月dd日 HH:mm"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}

