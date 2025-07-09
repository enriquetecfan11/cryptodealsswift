
import SwiftUI
import Charts

struct CryptoListView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    
    // Estado para navegación y carga
    @State private var detailId: String? = nil
    @State private var navigate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Todas las criptomonedas")
                        .font(.title2).bold()
                        .padding([.top, .horizontal])
                    if viewModel.cryptos.isEmpty {
                        HStack { Spacer() }
                        ProgressView("Cargando...")
                            .padding(.vertical, 40)
                        HStack { Spacer() }
                    } else {
                        List {
                            ForEach(viewModel.cryptos) { crypto in
                                Button(action: {
                                    viewModel.fetchCryptoDetail(id: crypto.id) { success in
                                        if success {
                                            self.detailId = crypto.id
                                            self.navigate = true
                                        }
                                    }
                                }) {
                                    CryptoRowPro(crypto: crypto)
                                        .listRowInsets(EdgeInsets())
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    Spacer()
                }
                .blur(radius: viewModel.isLoadingDetail ? 3 : 0)
                
                // Indicador de carga superpuesto
                if viewModel.isLoadingDetail {
                    VStack {
                        ProgressView("Cargando detalles...")
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                            .shadow(radius: 10)
                    }
                }
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .environmentObject(viewModel)
            .onAppear {
                viewModel.fetchCryptos()
            }
            .navigationTitle("Lista")
            .navigationDestination(isPresented: $navigate) {
                if let id = detailId {
                    CryptoDetailView(cryptoId: id)
                }
            }
        }
    }
    
    @ViewBuilder
    private var detailDestination: some View {
        if let id = detailId {
            CryptoDetailView(cryptoId: id)
        } else {
            EmptyView()
        }
    }
}

struct CryptoRowPro: View {
    let crypto: Cryptocurrency
    var logoURL: URL? {
        URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")
    }
    var body: some View {
        HStack(spacing: 14) {
            if let url = logoURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .overlay(
                            Text(crypto.symbol.prefix(1))
                                .font(.title2.bold())
                                .foregroundColor(.secondaryText)
                        )
                }
                .frame(width: 40, height: 40)
            } else {
                Circle()
                    .fill(Color.surfaceBackground)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(crypto.symbol.prefix(1))
                            .font(.title2.bold())
                            .foregroundColor(.secondaryText)
                    )
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(crypto.name)
                    .font(.headline)
                    .foregroundColor(.primaryText)
                Text(crypto.symbol)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                let change = crypto.quote?.USD?.percent_change_24h ?? 0
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                        .font(.caption)
                    Text(String(format: "%+.2f%%", change))
                        .font(.caption.bold())
                        .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .scaleEffectOnTap()
    }
}

struct CryptoFeaturedCard: View {
    let crypto: Cryptocurrency
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(crypto.name)
                .font(.headline)
                .foregroundColor(.black)
            Text(crypto.symbol)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                .font(.title2)
                .foregroundColor(.black)
            Text(String(format: "%+.2f%% (24h)", crypto.quote?.USD?.percent_change_24h ?? 0))
                .font(.caption)
                .foregroundColor((crypto.quote?.USD?.percent_change_24h ?? 0) >= 0 ? .green : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// BlurView para efecto de fondo en las tarjetas
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct CryptoListView_Previews: PreviewProvider {
    static var previews: some View {
        CryptoListView()
    }
}
