import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    let destacados = ["BTC", "ETH", "XRP", "SOL", "BNB", "DOGE"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Criptomonedas Destacadas")
                .font(.title2).bold()
                .padding([.top, .horizontal])
            if viewModel.cryptos.isEmpty {
                HStack { Spacer() }
                ProgressView("Cargando...")
                    .padding(.vertical, 40)
                HStack { Spacer() }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(destacados, id: \.self) { symbol in
                        if let crypto = viewModel.cryptos.first(where: { $0.symbol == symbol }) {
                            NavigationLink(destination: CryptoDetailView(cryptoId: String(crypto.id))) {
                                CryptoFeaturedCardPro(crypto: crypto)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            CryptoFeaturedCardPlaceholderPro(symbol: symbol)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            Spacer()
        }
        .background(Color.mainBackground.ignoresSafeArea())
        .environmentObject(viewModel) // <-- Inyectar el ViewModel
        .onAppear {
            viewModel.fetchCryptos()
        }
        .navigationTitle("Inicio")
    }
}

struct CryptoFeaturedCardPro: View {
    let crypto: Cryptocurrency
    var logoURL: URL? {
        URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
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
                    .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .frame(width: 36, height: 36)
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
            }
            Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                .font(.title2.bold())
                .foregroundColor(.primaryText)
            HStack(spacing: 6) {
                let change = crypto.quote?.USD?.percent_change_24h ?? 0
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                    .font(.caption)
                Text(String(format: "%+.2f%% (24h)", change))
                    .font(.caption.bold())
                    .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
            }
            .padding(.top, 2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .scaleEffectOnTap()
        .animation(.spring(), value: crypto.id)
    }
}

struct CryptoFeaturedCardPlaceholderPro: View {
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.surfaceBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(symbol.prefix(1))
                            .font(.title2.bold())
                            .foregroundColor(.placeholderText)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(symbol)
                        .font(.headline)
                        .foregroundColor(.placeholderText)
                    Text("-")
                        .font(.caption)
                        .foregroundColor(.placeholderText)
                }
            }
            Text("-")
                .font(.title2.bold())
                .foregroundColor(.placeholderText)
            Text("-")
                .font(.caption.bold())
                .foregroundColor(.placeholderText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// Extensión movida a Extensions.swift 