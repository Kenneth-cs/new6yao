import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String = "定位中..."
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var isLocating: Bool = false
    
    // 重试机制
    private var retryCount: Int = 0
    private let maxRetries: Int = 3
    private var retryTimer: Timer?
    private let retryDelay: TimeInterval = 2.0 // 重试间隔2秒
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000 // 1公里更新一次
    }
    
    func requestLocation() {
        // 取消之前的重试计时器
        retryTimer?.invalidate()
        retryTimer = nil
        
        // 重置重试计数
        retryCount = 0
        
        // 开始定位
        startLocationRequest()
    }
    
    // 手动重试（用户点击重试按钮）
    func retryLocation() {
        print("📍 用户手动重试定位")
        retryTimer?.invalidate()
        retryTimer = nil
        retryCount = 0
        locationError = nil
        currentCity = "重新定位中..."
        startLocationRequest()
    }
    
    private func startLocationRequest() {
        isLocating = true
        
        switch authorizationStatus {
        case .notDetermined:
            print("📍 请求定位权限")
            currentCity = "请求权限中..."
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 开始定位 (尝试 \(retryCount + 1)/\(maxRetries + 1))")
            if retryCount > 0 {
                currentCity = "重试定位中..."
            } else {
                currentCity = "定位中..."
            }
            locationManager.requestLocation()
        case .denied, .restricted:
            print("📍 定位权限被拒绝")
            locationError = "定位权限被拒绝"
            currentCity = "权限被拒"
            isLocating = false
        @unknown default:
            isLocating = false
            break
        }
    }
    
    // 自动重试
    private func scheduleRetry() {
        guard retryCount < maxRetries else {
            print("📍 已达最大重试次数，停止重试")
            currentCity = "定位失败"
            isLocating = false
            return
        }
        
        retryCount += 1
        print("📍 将在 \(retryDelay) 秒后进行第 \(retryCount + 1) 次尝试")
        
        retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
            self?.startLocationRequest()
        }
    }
    
    private func geocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if error != nil {
                    print("📍 地址解析失败: \(error?.localizedDescription ?? "未知错误")")
                    
                    // 地址解析失败，但已有位置信息，尝试重试
                    self.locationError = "地址解析失败"
                    
                    if self.retryCount < self.maxRetries {
                        print("📍 地址解析失败，准备重试")
                        self.scheduleRetry()
                    } else {
                        self.currentCity = "解析失败"
                        self.isLocating = false
                    }
                    return
                }
                
                if let placemark = placemarks?.first {
                    // 成功获取地址，停止重试
                    self.retryTimer?.invalidate()
                    self.retryTimer = nil
                    self.isLocating = false
                    
                    // 优先显示市级行政区
                    if let city = placemark.locality {
                        self.currentCity = city
                        print("📍 定位成功: \(city)")
                    } else if let administrativeArea = placemark.administrativeArea {
                        self.currentCity = administrativeArea
                        print("📍 定位成功: \(administrativeArea)")
                    } else if let country = placemark.country {
                        self.currentCity = country
                        print("📍 定位成功: \(country)")
                    } else {
                        self.currentCity = "未知地区"
                        print("📍 定位成功但地区未知")
                    }
                    self.locationError = nil
                    self.retryCount = 0
                } else {
                    print("📍 未获取到地标信息")
                    if self.retryCount < self.maxRetries {
                        self.scheduleRetry()
                    } else {
                        self.currentCity = "定位失败"
                        self.isLocating = false
                    }
                }
            }
        }
    }
    
    // 清理资源
    deinit {
        retryTimer?.invalidate()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 收到位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        geocodeLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            let clError = error as? CLError
            let errorCode = clError?.code.rawValue ?? -1
            
            print("📍 定位失败 (错误码: \(errorCode)): \(error.localizedDescription)")
            
            // 根据错误类型决定是否重试
            switch errorCode {
            case CLError.denied.rawValue:
                // 权限被拒绝，不重试
                self.locationError = "定位权限被拒绝"
                self.currentCity = "权限被拒"
                self.isLocating = false
                self.retryTimer?.invalidate()
                
            case CLError.network.rawValue:
                // 网络错误，可以重试
                self.locationError = "网络错误"
                if self.retryCount < self.maxRetries {
                    print("📍 网络错误，准备重试")
                    self.scheduleRetry()
                } else {
                    self.currentCity = "网络错误"
                    self.isLocating = false
                }
                
            case CLError.locationUnknown.rawValue:
                // 位置未知，可以重试
                self.locationError = "位置未知"
                if self.retryCount < self.maxRetries {
                    print("📍 位置未知，准备重试")
                    self.scheduleRetry()
                } else {
                    self.currentCity = "定位失败"
                    self.isLocating = false
                }
                
            default:
                // 其他错误，尝试重试
                self.locationError = "定位失败"
                if self.retryCount < self.maxRetries {
                    print("📍 定位失败，准备重试")
                    self.scheduleRetry()
                } else {
                    self.currentCity = "定位失败"
                    self.isLocating = false
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            print("📍 权限状态变化: \(status.rawValue)")
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("📍 获得定位权限，开始定位")
                self.startLocationRequest()
            case .denied, .restricted:
                print("📍 定位权限被拒绝")
                self.locationError = "定位权限被拒绝"
                self.currentCity = "权限被拒"
                self.isLocating = false
                self.retryTimer?.invalidate()
            case .notDetermined:
                self.currentCity = "等待授权..."
                self.isLocating = false
            @unknown default:
                self.isLocating = false
                break
            }
        }
    }
    
    // 清理资源
    deinit {
        retryTimer?.invalidate()
    }
}