
import SwiftUI
import Charts

struct CryptoListView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    
    @State private var detailId: String? = nil
    @State private var navigate = false
    @State private var showingAddToPortfolio: Cryptocurrency? = nil
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    headerView
                    
                    if viewModel.updatingPrices {
                        updatingPricesIndicator
                    }
                    
                    Text("Todas las criptomonedas")
                        .font(DeviceInfo.isIPad ? .title.bold() : .title2.bold())
                        .padding(.horizontal, DeviceInfo.isIPad ? 24 : 8)
                        .padding(.top, 4)
                    
                    mainContent
                    
                    Spacer()
                }
                .adaptiveFrame()
                .blur(radius: viewModel.isLoadingDetail ? 2 : 0)
                
                loadingAndErrorOverlays
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .environmentObject(viewModel)
            .onAppear {
                if viewModel.cryptos.isEmpty {
                    viewModel.fetchCryptos()
                }
            }
            .navigationDestination(isPresented: $navigate) {
                if let id = detailId {
                    CryptoDetailView(cryptoId: id)
                }
            }
            .sheet(item: $showingAddToPortfolio) { crypto in
                AddPositionView(
                    portfolioViewModel: PortfolioViewModel(cryptoViewModel: viewModel),
                    cryptoViewModel: viewModel,
                    preselectedCrypto: crypto
                )
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        let toggleIcon = viewModel.isGridView ? "list.bullet" : "square.grid.2x2"
        let toggleLabel = viewModel.isGridView ? "Vista de lista" : "Vista de cuadrícula"
        
        HStack(alignment: .center) {
            SearchBar(text: $viewModel.searchText)
                .frame(maxWidth: .infinity)
            Button(action: {
                withAnimation(.easeInOut) {
                    viewModel.isGridView.toggle()
                }
            }) {
                Image(systemName: toggleIcon)
                    .font(.title2)
                    .foregroundColor(.cryptoBlue)
                    .padding(.trailing, 8)
                    .accessibilityLabel(toggleLabel)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, DeviceInfo.isIPad ? 24 : 8)
    }
    
    @ViewBuilder
    private var updatingPricesIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Actualizando precios...")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.loadingState == .loading && viewModel.cryptos.isEmpty {
            SkeletonLoadingView()
                .transition(.opacity)
        } else if case .failure(_) = viewModel.loadingState, viewModel.cryptos.isEmpty {
            LoadingStateView(state: viewModel.loadingState) {
                viewModel.retryCryptos()
            }
        } else if viewModel.filteredCryptos.isEmpty && !viewModel.searchText.isEmpty {
            noResultsView
        } else if viewModel.filteredCryptos.isEmpty {
            noDataView
        } else {
            if viewModel.isGridView {
                gridView
            } else {
                listView
            }
        }
    }
    
    @ViewBuilder
    private var loadingAndErrorOverlays: some View {
        LoadingOverlay(
            message: "Cargando detalles...\nPor favor espera",
            isLoading: viewModel.isLoadingDetail
        )
        
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
    
    @ViewBuilder
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.placeholderText)
            Text("No se encontraron criptomonedas")
                .font(.title3.bold())
                .foregroundColor(.primaryText)
            Text("Prueba con otro nombre o ticker.")
                .font(.body)
                .foregroundColor(.secondaryText)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var noDataView: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: adaptiveColumns, spacing: adaptiveSpacing) {
                ForEach(viewModel.filteredCryptos) { crypto in
                    CryptoRowPro(
                        crypto: crypto,
                        isFavorite: viewModel.isFavorite(id: crypto.id),
                        showSparkline: true,
                        onFavorite: { viewModel.toggleFavorite(id: crypto.id) },
                        onAddToPortfolio: { showingAddToPortfolio = crypto },
                        onShowDetail: { navigateToDetail(crypto: crypto) }
                    )
                    .matchedGeometryEffect(id: crypto.id, in: animation)
                    .contextMenu {
                        Button(action: { viewModel.toggleFavorite(id: crypto.id) }) {
                            Label(viewModel.isFavorite(id: crypto.id) ? "Quitar de favoritos" : "Marcar como favorito", systemImage: "star")
                        }
                        Button(action: { showingAddToPortfolio = crypto }) {
                            Label("Añadir al portafolio", systemImage: "plus")
                        }
                        Button(action: { navigateToDetail(crypto: crypto) }) {
                            Label("Ver detalles", systemImage: "info.circle")
                        }
                    }
                    .padding(.vertical, 2)
                    .animation(.easeInOut, value: viewModel.filteredCryptos)
                }
            }
            .padding(.horizontal, DeviceInfo.isIPad ? 24 : 8)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var listView: some View {
        List {
            ForEach(viewModel.filteredCryptos) { crypto in
                CryptoRowPro(
                    crypto: crypto,
                    isFavorite: viewModel.isFavorite(id: crypto.id),
                    showSparkline: true,
                    onFavorite: { viewModel.toggleFavorite(id: crypto.id) },
                    onAddToPortfolio: { showingAddToPortfolio = crypto },
                    onShowDetail: { navigateToDetail(crypto: crypto) }
                )
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 2)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(action: { viewModel.toggleFavorite(id: crypto.id) }) {
                        Label("Favorito", systemImage: viewModel.isFavorite(id: crypto.id) ? "star.fill" : "star")
                    }.tint(.yellow)
                    Button(action: { showingAddToPortfolio = crypto }) {
                        Label("Añadir", systemImage: "plus")
                    }.tint(.cryptoBlue)
                    Button(action: { navigateToDetail(crypto: crypto) }) {
                        Label("Detalles", systemImage: "info.circle")
                    }.tint(.gray)
                }
                .animation(.easeInOut, value: viewModel.filteredCryptos)
            }
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
            withAnimation { viewModel.updatingPrices = true }
            viewModel.fetchCryptos()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { viewModel.updatingPrices = false }
            }
        }
        .transition(.opacity)
    }
    
    private func navigateToDetail(crypto: Cryptocurrency) {
        detailId = crypto.id
        viewModel.fetchCryptoDetail(id: crypto.id) { success in
            if success {
                self.navigate = true
            }
        }
    }
    
    private var adaptiveColumns: [GridItem] {
        DeviceInfo.isIPad ? Array(repeating: GridItem(.flexible()), count: 2) : [GridItem(.flexible())]
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 16 : 8
    }
}

struct CryptoRowPro: View {
    let crypto: Cryptocurrency
    let isFavorite: Bool
    let showSparkline: Bool
    let onFavorite: () -> Void
    let onAddToPortfolio: () -> Void
    let onShowDetail: () -> Void
    @State private var sparklineData: [Double]? = nil
    @State private var loadingSparkline = false
    @EnvironmentObject var viewModel: CryptoViewModel
    
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
                HStack(spacing: 4) {
                    Text(crypto.name)
                        .font(adaptiveNameFont)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .transition(.scale)
                    }
                }
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
                // Sparkline
                if showSparkline {
                    if let data = sparklineData, data.count > 1 {
                        Chart {
                            ForEach(Array(data.enumerated()), id: \ .offset) { idx, value in
                                LineMark(
                                    x: .value("Hora", idx),
                                    y: .value("Precio", value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    (data.last ?? 0) >= (data.first ?? 0) ? Color.cryptoGreen : Color.cryptoRed
                                )
                            }
                        }
                        .frame(height: 28)
                        .transition(.opacity)
                        .animation(.easeInOut, value: data)
                    } else if loadingSparkline {
                        ProgressView().frame(height: 28)
                    } else {
                        Color.clear.frame(height: 28)
                    }
                }
            }
        }
        .padding(.horizontal, DeviceInfo.isIPad ? 16 : 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: adaptiveShadowRadius, x: 0, y: 2)
        )
        .scaleEffectOnTap()
        .onAppear {
            if showSparkline && sparklineData == nil && !loadingSparkline {
                loadingSparkline = true
                viewModel.fetchHistoricalPrices(for: crypto.id) { data in
                    self.sparklineData = data
                    self.loadingSparkline = false
                }
            }
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 18 : (DeviceInfo.isLargeScreen ? 16 : 10)
    }
    private var adaptiveLogoSize: CGFloat {
        DeviceInfo.isIPad ? 50 : (DeviceInfo.isLargeScreen ? 44 : 36)
    }
    private var adaptiveCornerRadius: CGFloat {
        DeviceInfo.isIPad ? 16 : 12
    }
    private var adaptiveShadowRadius: CGFloat {
        DeviceInfo.isIPad ? 8 : 4
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
