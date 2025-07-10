import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.tertiaryText)
            TextField("Buscar criptomoneda...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color.surfaceBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
} 