import SwiftUI

/// 阳爻与阴爻共用同一总宽。结果页、海报共用这一套宽度，避免左右错位。
struct YaoStrokeView: View {
    let isYang: Bool
    var segment: CGFloat = 52
    var gap: CGFloat = 14
    var thickness: CGFloat = 7
    var gradient: LinearGradient = ResultTheme.yao

    private var total: CGFloat { segment * 2 + gap }

    var body: some View {
        Group {
            if isYang {
                Capsule()
                    .fill(gradient)
                    .frame(width: total, height: thickness)
            } else {
                HStack(spacing: gap) {
                    Capsule()
                        .fill(gradient)
                        .frame(width: segment, height: thickness)
                    Capsule()
                        .fill(gradient)
                        .frame(width: segment, height: thickness)
                }
            }
        }
        .frame(width: total, height: thickness, alignment: .center)
    }
}
