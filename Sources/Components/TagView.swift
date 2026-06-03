import SwiftUI

struct TagView: View {
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(text: String, backgroundColor: Color = .secondary.opacity(0.2), foregroundColor: Color = .secondary) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .cornerRadius(4)
    }
}
