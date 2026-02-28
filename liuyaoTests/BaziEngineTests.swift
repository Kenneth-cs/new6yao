import XCTest
@testable import liuyao

class BaziEngineTests: XCTestCase {
    
    // 测试集：50个已知八字的名人案例
    let testCases: [(name: String, birthDate: String, expectedDayMaster: String)] = [
        ("马云", "1964-09-10", "壬"), // 壬戌日
        ("李嘉诚", "1928-07-29", "庚"), // 庚午日
        ("任正非", "1944-10-25", "壬"), // 壬戌日
        // ... 更多案例
    ]
    
    func testBaziCalculationAccuracy() {
        let engine = BaziEngine.shared
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for testCase in testCases {
            guard let date = formatter.date(from: testCase.birthDate) else {
                XCTFail("Invalid date format for \(testCase.name)")
                continue
            }
            
            // 假设午时
            let dayMaster = engine.getDayMaster(date: date, hour: .wu)
            
            // 验证日主天干是否包含预期字符 (例如 "甲木" 包含 "甲")
            XCTAssertTrue(dayMaster.contains(testCase.expectedDayMaster),
                          "《\(testCase.name)》的日干计算错误，预期 \(testCase.expectedDayMaster)，实际 \(dayMaster)")
        }
    }
    
    func testWuxingDistribution() {
        let engine = BaziEngine.shared
        let date = Date() // 当前时间
        let result = engine.calculateEnergy(date: date, hour: .wu)
        
        // 验证五行分值范围（0-1之间）
        XCTAssertGreaterThanOrEqual(result[.wood] ?? 0, 0.0)
        XCTAssertLessThanOrEqual(result[.wood] ?? 0, 1.0)
        
        // 验证总分为1
        let total = result.values.reduce(0, +)
        XCTAssertEqual(total, 1.0, accuracy: 0.001, "五行分值总和必须为1.0")
    }
}
