import SwiftUI

struct CryptoDetailView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    let cryptoId: String
    @State private var hasAppeared = false
    
    private var crypto: Cryptocurrency? {
        viewModel.getCrypto(by: cryptoId)
    }
    
    var body: some View {
        Group {
            if let crypto = crypto {
                // Contenido principal cuando hay datos
                cryptoDetailContent(crypto: crypto)
            } else {
                // Estados de carga y error
                ZStack {
                    Color.mainBackground.ignoresSafeArea()
                    
                    VStack {
                        if viewModel.detailLoadingState == .loading {
                            // Skeleton loading con nombre si está disponible
                            DetailLoadingView(cryptoName: getCryptoName())
                        } else if case .failure(_) = viewModel.detailLoadingState {
                            // Error state con retry
                            ErrorStateView(
                                title: "Error cargando detalles",
                                message: viewModel.errorMessage ?? "No se pudieron cargar los detalles de esta criptomoneda",
                                retryAction: {
                                    viewModel.retryDetailLoad(id: cryptoId) { _ in }
                                }
                            )
                            .padding()
                        } else {
                            // Estado inicial - intentar cargar
                            VStack(spacing: 16) {
                                Image(systemName: "bitcoinsign.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.cryptoBlue)
                                
                                Text("Cargando información")
                                    .font(.title3.bold())
                                    .foregroundColor(.primaryText)
                                
                                Text("Obteniendo los detalles de la criptomoneda")
                                    .font(.body)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    viewModel.fetchCryptoDetail(id: cryptoId) { _ in }
                                }) {
                                    Text("Cargar detalles")
                                        .font(.callout.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.cryptoBlue)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                        
                        Spacer()
                    }
                }
                .navigationTitle(getCryptoName())
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                // Solo intentar cargar si no hay datos y no se está cargando
                if crypto == nil && viewModel.detailLoadingState != .loading {
                    viewModel.fetchCryptoDetail(id: cryptoId) { _ in }
                }
            }
        }
    }
    
    private func getCryptoName() -> String {
        // Intentar obtener el nombre de los datos existentes
        if let crypto = crypto {
            return crypto.name
        }
        
        // Buscar en la lista general
        if let crypto = viewModel.cryptos.first(where: { $0.id == cryptoId }) {
            return crypto.name
        }
        
        return "Criptomoneda"
    }
    
    @ViewBuilder
    private func cryptoDetailContent(crypto: Cryptocurrency) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: adaptiveSpacing) {
                    // Header principal
                    HStack(alignment: .center, spacing: adaptiveSpacing) {
                        AsyncImage(url: URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")) { image in
                            image
                                .resizable()
                                .scaledToFit()
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
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(crypto.name)
                                .font(adaptiveNameFont)
                                .foregroundColor(.primaryText)
                                .lineLimit(DeviceInfo.isIPad ? 2 : 1)
                            Text(crypto.symbol)
                                .font(adaptiveCaptionFont)
                                .foregroundColor(.secondaryText)
                        }
                        Spacer()
                    }
                    
                    // Precio principal
                    VStack(alignment: .leading, spacing: adaptiveSpacing * 0.5) {
                        Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "No disponible")
                            .font(adaptivePriceFont)
                            .foregroundColor(.primaryText)
                        
                        // Cambios de precio
                        HStack(spacing: adaptiveSpacing) {
                            if let change1h = crypto.quote?.USD?.percent_change_1h {
                                ChangeLabel(title: "1h", change: change1h)
                            }
                            if let change24h = crypto.quote?.USD?.percent_change_24h {
                                ChangeLabel(title: "24h", change: change24h)
                            }
                            if let change7d = crypto.quote?.USD?.percent_change_7d {
                                ChangeLabel(title: "7d", change: change7d)
                            }
                            Spacer()
                        }
                    }
                    .padding(.vertical, adaptiveSpacing)
                    .padding(.horizontal, adaptiveSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius)
                            .fill(Color.cardBackground)
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                    )
                    
                    // Información detallada
                    VStack(spacing: adaptiveInfoSpacing) {
                        InfoRowPro(label: "Capitalización de mercado", value: crypto.quote?.USD?.market_cap?.formatted(.currency(code: "USD")), icon: "chart.bar.fill")
                        InfoRowPro(label: "Volumen (24h)", value: crypto.quote?.USD?.volume_24h?.formatted(.currency(code: "USD")), icon: "waveform.path.ecg")
                        InfoRowPro(label: "Oferta circulante", value: crypto.circulating_supply?.formatted(), icon: "arrow.2.circlepath.circle")
                        InfoRowPro(label: "Oferta total", value: crypto.total_supply?.formatted(), icon: "circle.grid.cross")
                        InfoRowPro(label: "Oferta máxima", value: crypto.max_supply?.formatted(), icon: "lock.circle")
                        InfoRowPro(label: "Ranking CMC", value: crypto.cmc_rank != nil ? "#\(crypto.cmc_rank!)" : "-", icon: "number.circle")
                        InfoRowPro(label: "Fecha de incorporación", value: crypto.date_added, icon: "calendar")
                        InfoRowPro(label: "Plataforma", value: crypto.platform?.name, icon: "cube")
                        if let tags = crypto.tags, !tags.isEmpty {
                            InfoRowPro(label: "Etiquetas", value: tags.joined(separator: ", "), icon: "tag")
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(adaptivePadding)
                .adaptiveFrame()
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle(crypto.name)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.fetchCryptoDetail(id: cryptoId) { _ in }
            }
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 20 : (DeviceInfo.isLargeScreen ? 16 : 12)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 32 : (DeviceInfo.isLargeScreen ? 24 : 20)
    }
    
    private var adaptiveLogoSize: CGFloat {
        DeviceInfo.isIPad ? 80 : (DeviceInfo.isLargeScreen ? 60 : 50)
    }
    
    private var adaptiveCornerRadius: CGFloat {
        DeviceInfo.isIPad ? 16 : 12
    }
    
    private var adaptiveNameFont: Font {
        DeviceInfo.isIPad ? .title.bold() : .title2.bold()
    }
    
    private var adaptivePriceFont: Font {
        DeviceInfo.isIPad ? .largeTitle.bold() : .title.bold()
    }
    
    private var adaptiveSymbolFont: Font {
        DeviceInfo.isIPad ? .title2.bold() : .headline.bold()
    }
    
    private var adaptiveCaptionFont: Font {
        DeviceInfo.isIPad ? .callout : .caption
    }
    
    private var adaptiveInfoSpacing: CGFloat {
        DeviceInfo.isIPad ? 14 : 12
    }
}

// Componente para mostrar cambios de precio
struct ChangeLabel: View {
    let title: String
    let change: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondaryText)
            
            Text(change.toPercentage())
                .font(.caption2.bold())
                .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.surfaceBackground)
        )
    }
}

// Componente para mostrar información en filas
struct InfoRowPro: View {
    let label: String
    let value: String?
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.cryptoBlue)
                .frame(width: 16)
            
            Text(label)
                .font(DeviceInfo.isIPad ? .callout : .caption)
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            Text(value ?? "No disponible")
                .font(DeviceInfo.isIPad ? .callout : .caption)
                .foregroundColor(.primaryText)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
    }
}
