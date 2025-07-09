
import SwiftUI
import Charts

struct CryptoListView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    
    // Estado para navegación y carga
    @State private var detailId: String? = nil
    @State private var navigate = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Todas las criptomonedas")
                            .font(DeviceInfo.isIPad ? .title.bold() : .title2.bold())
                            .padding([.top, .horizontal], adaptivePadding)
                        
                        // Contenido principal
                        if viewModel.loadingState == .loading && viewModel.cryptos.isEmpty {
                            SkeletonLoadingView()
                        } else if case .failure(_) = viewModel.loadingState, viewModel.cryptos.isEmpty {
                            LoadingStateView(state: viewModel.loadingState) {
                                viewModel.retryCryptos()
                            }
                        } else if viewModel.cryptos.isEmpty {
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
                            if DeviceInfo.isIPad {
                                // Layout de grid para iPad
                                ScrollView {
                                    LazyVGrid(columns: adaptiveColumns, spacing: adaptiveSpacing) {
                                        ForEach(viewModel.cryptos) { crypto in
                                            Button(action: {
                                                navigateToDetail(crypto: crypto)
                                            }) {
                                                CryptoRowPro(crypto: crypto)
                                                    .padding(.vertical, 4)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, adaptivePadding)
                                }
                            } else {
                                // Layout de lista para iPhone
                                List {
                                    ForEach(viewModel.cryptos) { crypto in
                                        Button(action: {
                                            navigateToDetail(crypto: crypto)
                                        }) {
                                            CryptoRowPro(crypto: crypto)
                                                .listRowInsets(EdgeInsets())
                                                .padding(.vertical, 4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .listRowBackground(Color.clear)
                                    }
                                    
                                    // Indicador de error si hay problema con la carga
                                    if case .failure(_) = viewModel.loadingState {
                                        VStack(spacing: 8) {
                                            Text("Error cargando más datos")
                                                .font(.caption)
                                                .foregroundColor(.cryptoRed)
                                            
                                            Button("Reintentar") {
                                                viewModel.retryCryptos()
                                            }
                                            .font(.caption.bold())
                                            .foregroundColor(.cryptoBlue)
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .listRowBackground(Color.clear)
                                    }
                                }
                                .listStyle(PlainListStyle())
                                .refreshable {
                                    viewModel.fetchCryptos()
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .adaptiveFrame()
                    .blur(radius: viewModel.isLoadingDetail ? 2 : 0)
                    
                    // Overlay de carga de detalles mejorado
                    LoadingOverlay(
                        message: "Cargando detalles...\nPor favor espera",
                        isLoading: viewModel.isLoadingDetail
                    )
                    
                    // Overlay de error de detalles
                    if case .failure(_) = viewModel.detailLoadingState {
                        ZStack {
                            Color.black.opacity(0.2)
                                .ignoresSafeArea()
                            
                            ErrorStateView(
                                title: "Error cargando detalles",
                                message: viewModel.errorMessage ?? "Ha ocurrido un error inesperado",
                                retryAction: {
                                    if let id = detailId {
                                        viewModel.retryDetailLoad(id: id) { success in
                                            if success {
                                                self.navigate = true
                                            }
                                        }
                                    }
                                }
                            )
                            .frame(maxWidth: 320)
                        }
                    }
                }
                .background(Color.mainBackground.ignoresSafeArea())
                .environmentObject(viewModel)
                .onAppear {
                    if viewModel.cryptos.isEmpty {
                        viewModel.fetchCryptos()
                    }
                }
                .navigationTitle("Lista")
                .navigationDestination(isPresented: $navigate) {
                    if let id = detailId {
                        CryptoDetailView(cryptoId: id)
                    }
                }
            }
        }
    }
    
    private func navigateToDetail(crypto: Cryptocurrency) {
        detailId = crypto.id
        viewModel.fetchCryptoDetail(id: crypto.id) { success in
            if success {
                self.navigate = true
            }
            // Si falla, el error se mostrará automáticamente
        }
    }
    
    private var adaptiveColumns: [GridItem] {
        if DeviceInfo.isIPad {
            return Array(repeating: GridItem(.flexible()), count: 2)
        } else {
            return [GridItem(.flexible())]
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 16 : 12
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 24 : (DeviceInfo.isLargeScreen ? 20 : 16)
    }
}

struct CryptoRowPro: View {
    let crypto: Cryptocurrency
    var logoURL: URL? {
        URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")
    }
    
    var body: some View {
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
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                    .font(adaptivePriceFont)
                    .foregroundColor(.primaryText)
                let change = crypto.quote?.USD?.percent_change_24h ?? 0
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                        .font(adaptiveCaptionFont)
                    Text(String(format: "%+.2f%%", change))
                        .font(adaptiveCaptionFont.bold())
                        .foregroundColor(change >= 0 ? .cryptoGreen : .cryptoRed)
                }
            }
        }
        .padding(adaptivePadding)
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: adaptiveShadowRadius, x: 0, y: 2)
        )
        .scaleEffectOnTap()
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 18 : (DeviceInfo.isLargeScreen ? 16 : 14)
    }
    
    private var adaptiveLogoSize: CGFloat {
        DeviceInfo.isIPad ? 50 : (DeviceInfo.isLargeScreen ? 44 : 40)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 20 : (DeviceInfo.isLargeScreen ? 16 : 12)
    }
    
    private var adaptiveCornerRadius: CGFloat {
        DeviceInfo.isIPad ? 16 : 14
    }
    
    private var adaptiveShadowRadius: CGFloat {
        DeviceInfo.isIPad ? 8 : 6
    }
    
    private var adaptiveNameFont: Font {
        DeviceInfo.isIPad ? .title3.bold() : .headline
    }
    
    private var adaptivePriceFont: Font {
        DeviceInfo.isIPad ? .title3.bold() : .headline
    }
    
    private var adaptiveCaptionFont: Font {
        DeviceInfo.isIPad ? .footnote : .caption
    }
    
    private var adaptiveSymbolFont: Font {
        DeviceInfo.isIPad ? .title3.bold() : .headline
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
