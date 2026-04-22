import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34))
                .foregroundColor(Color.bilibiliPink)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(Color.bilibiliPink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.tv")
                .font(.system(size: 34))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

struct InlineErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Button("重试", action: retry)
                .font(.footnote.weight(.medium))
                .foregroundColor(Color.bilibiliPink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct HomeSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 140)
                    .shimmer()
                    .padding(.horizontal, 16)
                
                ForEach(0..<5, id: \.self) { _ in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 170, height: 100)
                            .shimmer()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 16)
                                .shimmer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 16)
                                .padding(.trailing, 30)
                                .shimmer()
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 120, height: 12)
                                .shimmer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 100, height: 12)
                                .shimmer()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 90)
        }
    }
}
