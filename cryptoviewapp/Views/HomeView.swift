import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    let destacados = ["BTC", "ETH", "XRP", "SOL", "BNB", "DOGE"]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Text("Criptomonedas Destacadas")
                    .font(DeviceInfo.isIPad ? .title.bold() : .title2.bold())
                    .padding([.top, .horizontal], adaptivePadding)
                    
                if viewModel.cryptos.isEmpty {
                    HStack { Spacer() }
                    ProgressView("Cargando...")
                        .padding(.vertical, 40)
                    HStack { Spacer() }
                } else {
                    LazyVGrid(columns: adaptiveColumns, spacing: adaptiveSpacing) {
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
                    .padding(.horizontal, adaptivePadding)
                    .padding(.bottom, 8)
                }
                Spacer()
            }
            .adaptiveFrame()
            .background(Color.mainBackground.ignoresSafeArea())
            .environmentObject(viewModel)
            .onAppear {
                viewModel.fetchCryptos()
            }
            .navigationTitle("Inicio")
        }
    }
    
    private var adaptiveColumns: [GridItem] {
        if DeviceInfo.isIPad {
            return Array(repeating: GridItem(.flexible()), count: 3)
        } else if DeviceInfo.isLargeScreen {
            return Array(repeating: GridItem(.flexible()), count: 2)
        } else {
            return Array(repeating: GridItem(.flexible()), count: 2)
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 24 : (DeviceInfo.isLargeScreen ? 18 : 16)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 24 : (DeviceInfo.isLargeScreen ? 20 : 16)
    }
}

struct CryptoFeaturedCardPro: View {
    let crypto: Cryptocurrency
    var logoURL: URL? {
        URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing) {
            HStack(spacing: adaptiveSpacing) {
                if let url = logoURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle()
                            .fill(Color.surfaceBackground)
                            .overlay(
                                Text(crypto.symbol.prefix(1))
                                    .font(adaptiveSymbolFont)
                                    .foregroundColor(.secondaryText)
                            )
                    }
                    .frame(width: adaptiveLogoSize, height: adaptiveLogoSize)
                } else {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .frame(width: adaptiveLogoSize, height: adaptiveLogoSize)
                        .overlay(
                            Text(crypto.symbol.prefix(1))
                                .font(adaptiveSymbolFont)
                                .foregroundColor(.secondaryText)
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(crypto.name)
                        .font(adaptiveNameFont)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    Text(crypto.symbol)
                        .font(adaptiveCaptionFont)
                        .foregroundColor(.secondaryText)
                }
            }
            Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                .font(adaptivePriceFont)
                .foregroundColor(.primaryText)
            HStack(spacing: adaptiveSpacing) {
                let change = crypto.quote?.USD?.percent_change_24h ?? 0
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                    .font(adaptiveCaptionFont)
                Text(String(format: "%+.2f%% (24h)", change))
                    .font(adaptiveCaptionFont.bold())
                    .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
            }
            .padding(.top, 2)
        }
        .padding(adaptivePadding)
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: adaptiveShadowRadius, x: 0, y: 4)
        )
        .scaleEffectOnTap()
        .animation(.spring(), value: crypto.id)
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 12 : (DeviceInfo.isLargeScreen ? 8 : 6)
    }
    
    private var adaptiveLogoSize: CGFloat {
        DeviceInfo.isIPad ? 48 : (DeviceInfo.isLargeScreen ? 40 : 36)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 20 : (DeviceInfo.isLargeScreen ? 16 : 12)
    }
    
    private var adaptiveCornerRadius: CGFloat {
        DeviceInfo.isIPad ? 20 : 16
    }
    
    private var adaptiveShadowRadius: CGFloat {
        DeviceInfo.isIPad ? 12 : 8
    }
    
    private var adaptiveNameFont: Font {
        DeviceInfo.isIPad ? .title3.bold() : .headline
    }
    
    private var adaptivePriceFont: Font {
        DeviceInfo.isIPad ? .title2.bold() : .title3.bold()
    }
    
    private var adaptiveCaptionFont: Font {
        DeviceInfo.isIPad ? .footnote : .caption
    }
    
    private var adaptiveSymbolFont: Font {
        DeviceInfo.isIPad ? .title2.bold() : .title3.bold()
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