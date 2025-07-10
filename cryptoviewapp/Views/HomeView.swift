import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    @StateObject private var portfolioViewModel = PortfolioViewModel(cryptoViewModel: CryptoViewModel())
    
    let destacados = ["BTC", "ETH", "XRP", "SOL", "BNB", "DOGE", "LINK", "XMR"]
    let categorias = ["Destacadas", "Top ganadoras", "Mayor Actividad"]
    @State private var categoriaSeleccionada = 0
    @State private var mostrarAddPosition = false
    @State private var cryptoSeleccionada: Cryptocurrency? = nil
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Carrusel de categorías
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categorias.indices, id: \.self) { idx in
                            Button(action: {
                                categoriaSeleccionada = idx
                            }) {
                                Text(categorias[idx])
                                    .font(.callout.bold())
                                    .foregroundColor(categoriaSeleccionada == idx ? Color(.systemBackground) : .primaryText)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                    .background(
                                        categoriaSeleccionada == idx ? Color.primary : Color.cardBackground
                                    )
                                    .cornerRadius(18)
                                    .shadow(color: .clear, radius: 0)
                            }
                        }
                    }
                    .padding(.horizontal, adaptivePadding)
                    .padding(.top, adaptivePadding)
                    .padding(.bottom, 8)
                }
                
                // Título
                Text("\(categorias[categoriaSeleccionada])")
                    .font(DeviceInfo.isIPad ? .title.bold() : .title2.bold())
                    .padding(.horizontal, adaptivePadding)
                    .padding(.bottom, 4)
                
                // Contenido principal
                Group {
                    if viewModel.loadingState == .loading && viewModel.cryptos.isEmpty {
                        LazyVGrid(columns: adaptiveColumns, spacing: adaptiveSpacing) {
                            ForEach(destacados, id: \.self) { symbol in
                                CryptoFeaturedCardPlaceholderPro(symbol: symbol)
                            }
                        }
                        .padding(.horizontal, adaptivePadding)
                    } else if case .failure(_) = viewModel.loadingState, viewModel.cryptos.isEmpty {
                        // Error state con retry
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(.cryptoRed)
                            
                            Text("Error de conexión")
                                .font(.title3.bold())
                                .foregroundColor(.primaryText)
                            
                            Text(viewModel.errorMessage ?? "No se pudieron cargar las criptomonedas")
                                .font(.body)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                viewModel.retryCryptos()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reintentar")
                                }
                                .font(.callout.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.cryptoBlue)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 40)
                    } else if viewModel.cryptos.isEmpty {
                        // Estado sin datos
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.placeholderText)
                            
                            Text("No hay datos disponibles")
                                .font(.title3.bold())
                                .foregroundColor(.primaryText)
                            
                            Text("Intenta cargar los datos nuevamente")
                                .font(.body)
                                .foregroundColor(.secondaryText)
                            
                            Button(action: {
                                viewModel.fetchCryptos()
                            }) {
                                Text("Cargar datos")
                                    .font(.callout.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.cryptoBlue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Selección de criptos según categoría
                        let cryptosToShow: [Cryptocurrency] = {
                            switch categoriaSeleccionada {
                            case 1: // Top ganadoras
                                return viewModel.cryptos.sorted { ($0.quote?.USD?.percent_change_24h ?? 0) > ($1.quote?.USD?.percent_change_24h ?? 0) }.prefix(6).map { $0 }
                            case 2: // Más negociadas
                                return viewModel.cryptos.sorted { ($0.quote?.USD?.volume_24h ?? 0) > ($1.quote?.USD?.volume_24h ?? 0) }.prefix(6).map { $0 }
                            default: // Destacadas
                                return destacados.compactMap { symbol in viewModel.cryptos.first(where: { $0.symbol == symbol }) }
                            }
                        }()
                        LazyVGrid(columns: adaptiveColumns, spacing: adaptiveSpacing) {
                            ForEach(cryptosToShow, id: \.id) { crypto in
                                CryptoFeaturedCardPro(
                                    crypto: crypto,
                                    onTap: {
                                        cryptoSeleccionada = crypto
                                        mostrarAddPosition = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, adaptivePadding)
                        .padding(.bottom, 8)
                    }
                }
                
                // Indicador de actualización cuando ya hay datos
                if viewModel.loadingState == .loading && !viewModel.cryptos.isEmpty {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Actualizando...")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.cardBackground)
                        .cornerRadius(20)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .adaptiveFrame()
            .background(Color.mainBackground.ignoresSafeArea())
            .environmentObject(viewModel)
            .sheet(isPresented: $mostrarAddPosition) {
                if let crypto = cryptoSeleccionada {
                    AddPositionView(
                        portfolioViewModel: portfolioViewModel,
                        cryptoViewModel: viewModel,
                        editingPosition: nil
                    )
                    .onAppear {
                        // Preseleccionar la cripto
                        // Esto requiere modificar AddPositionView para aceptar una cripto preseleccionada si se desea UX óptima
                    }
                }
            }
            .onAppear {
                // Solo cargar si no hay datos
                if viewModel.cryptos.isEmpty {
                    viewModel.fetchCryptos()
                }
            }
            .refreshable {
                viewModel.fetchCryptos()
            }
        }
    }
    
    private var adaptiveColumns: [GridItem] {
        if DeviceInfo.isIPad {
            return Array(repeating: GridItem(.flexible()), count: 3)
        } else {
            return Array(repeating: GridItem(.flexible()), count: 2)
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 20 : (DeviceInfo.isLargeScreen ? 16 : 12)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 24 : (DeviceInfo.isLargeScreen ? 20 : 16)
    }
}

// Componente para mostrar placeholder de card destacada
struct CryptoFeaturedCardPlaceholderPro: View {
    let symbol: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Logo placeholder
            Circle()
                .fill(Color.surfaceBackground)
                .frame(width: 40, height: 40)
                .shimmer()
            
            // Texto placeholder
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.surfaceBackground)
                    .frame(height: 16)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.surfaceBackground)
                    .frame(height: 14)
                    .frame(maxWidth: 60)
                    .shimmer()
            }
            
            // Precio placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.surfaceBackground)
                .frame(height: 20)
                .shimmer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// Componente para mostrar card destacada real
struct CryptoFeaturedCardPro: View {
    let crypto: Cryptocurrency
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 12) {
                // Icono grande y centrado
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
                    .frame(width: 48, height: 48)
                } else {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(crypto.symbol.prefix(1))
                                .font(.title2.bold())
                                .foregroundColor(.secondaryText)
                        )
                }
                // Nombre y símbolo centrados
                VStack(spacing: 2) {
                    Text(crypto.name)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    Text(crypto.symbol)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                // Precio y cambio porcentual alineados
                HStack(spacing: 6) {
                    Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                        .font(.subheadline.bold())
                        .foregroundColor(.primaryText)
                    if let change = crypto.quote?.USD?.percent_change_24h {
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                                .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                                .rotationEffect(.degrees(change >= 0 ? 0 : 180))
                            Text(change.toPercentage())
                                .font(.caption2.bold())
                                .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(0.18), lineWidth: 1.2)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            )
            .scaleEffectOnTap()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var logoURL: URL? {
        URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 12 : 8
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 16 : 12
    }
    
    private var adaptiveLogoSize: CGFloat {
        DeviceInfo.isIPad ? 36 : 28
    }
    
    private var adaptiveNameFont: Font {
        DeviceInfo.isIPad ? .callout.bold() : .caption.bold()
    }
    
    private var adaptivePriceFont: Font {
        DeviceInfo.isIPad ? .headline.bold() : .subheadline.bold()
    }
    
    private var adaptiveSymbolFont: Font {
        DeviceInfo.isIPad ? .caption.bold() : .caption2.bold()
    }
    
    private var adaptiveCaptionFont: Font {
        DeviceInfo.isIPad ? .caption : .caption2
    }
} 