import SwiftUI

struct MatrixPlaceholderView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("五行决策矩阵")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("功能正在开发中")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("即将上线，敬请期待...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    MatrixPlaceholderView()
}
