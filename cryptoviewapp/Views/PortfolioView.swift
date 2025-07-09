import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var cryptoViewModel: CryptoViewModel
    @StateObject private var portfolioViewModel: PortfolioViewModel
    
    @State private var showingAddPosition = false
    @State private var editingPosition: PortfolioPosition?
    @State private var showingEditPosition = false
    
    init(cryptoViewModel: CryptoViewModel? = nil) {
        if let cryptoViewModel = cryptoViewModel {
            _portfolioViewModel = StateObject(wrappedValue: PortfolioViewModel(cryptoViewModel: cryptoViewModel))
        } else {
            _portfolioViewModel = StateObject(wrappedValue: PortfolioViewModel(cryptoViewModel: CryptoViewModel()))
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(alignment: .leading, spacing: adaptiveSpacing) {
                    // Balance y estadísticas
                    portfolioHeaderView
                    
                    // Botones de acción
                    actionButtonsView
                    
                    // Lista de posiciones
                    positionsListView
                    
                    Spacer()
                }
                .padding(.horizontal, adaptivePadding)
                .padding(.vertical, adaptivePadding * 0.75)
                .adaptiveFrame()
                .background(Color.mainBackground.ignoresSafeArea())
                .navigationTitle("Mi Portafolio")
                .onAppear {
                    cryptoViewModel.fetchCryptos()
                    portfolioViewModel.refreshPrices()
                }
                .sheet(isPresented: $showingAddPosition) {
                    AddPositionView(
                        portfolioViewModel: portfolioViewModel,
                        cryptoViewModel: cryptoViewModel
                    )
                }
                .sheet(item: $editingPosition) { position in
                    AddPositionView(
                        portfolioViewModel: portfolioViewModel,
                        cryptoViewModel: cryptoViewModel,
                        editingPosition: position
                    )
                }
                
                // Indicador de carga
                if portfolioViewModel.isLoading {
                    VStack {
                        ProgressView("Actualizando precios...")
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
                            .shadow(radius: 10)
                    }
                }
            }
            .blur(radius: portfolioViewModel.isLoading ? 3 : 0)
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 24 : (DeviceInfo.isLargeScreen ? 18 : 16)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 32 : (DeviceInfo.isLargeScreen ? 20 : 16)
    }
    
    private var adaptiveColumns: [GridItem] {
        if DeviceInfo.isIPad {
            return Array(repeating: GridItem(.flexible()), count: 2)
        } else {
            return [GridItem(.flexible())]
        }
    }
    
    private var portfolioHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Balance total
            VStack(alignment: .leading, spacing: 3) {
                Text("Balance Total")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                
                Text(portfolioViewModel.totalPortfolioValue.toCurrency())
                    .font(.title.bold())
                    .foregroundColor(.primaryText)
            }
            
            // Ganancia/Pérdida total
            if !portfolioViewModel.positions.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    let totalGainLoss = portfolioViewModel.getTotalGainLoss()
                    let totalGainLossPercentage = portfolioViewModel.getTotalGainLossPercentage()
                    
                    Text("Ganancia/Pérdida Total")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 8) {
                        Text(totalGainLoss.toCurrency())
                            .font(.headline.bold())
                            .foregroundColor(totalGainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                        
                        HStack(spacing: 3) {
                            Image(systemName: totalGainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .foregroundColor(totalGainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                                .font(.caption2)
                            
                            Text(totalGainLossPercentage.toPercentage())
                                .font(.subheadline.bold())
                                .foregroundColor(totalGainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingAddPosition = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text("Agregar")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.cryptoBlue.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.cryptoBlue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            Button(action: {
                portfolioViewModel.refreshPrices()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                    Text("Actualizar")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.cryptoGreen.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.cryptoGreen.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var positionsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mis Posiciones")
                .font(.subheadline.bold())
                .foregroundColor(.secondaryText)
            
            if portfolioViewModel.positions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    if DeviceInfo.isIPad {
                        // Layout de grid para iPad
                        LazyVGrid(columns: adaptiveColumns, spacing: adaptiveSpacing) {
                            ForEach(portfolioViewModel.positions) { position in
                                PortfolioPositionCard(
                                    position: position,
                                    currentPrice: portfolioViewModel.getCurrentPrice(for: position.cryptoId),
                                    onEdit: {
                                        editingPosition = position
                                    },
                                    onDelete: {
                                        portfolioViewModel.deletePosition(position)
                                    }
                                )
                                .contextMenu {
                                    Button("Editar", systemImage: "pencil") {
                                        editingPosition = position
                                    }
                                    Button("Eliminar", systemImage: "trash", role: .destructive) {
                                        portfolioViewModel.deletePosition(position)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    } else {
                        // Layout de lista para iPhone
                        LazyVStack(spacing: 8) {
                            ForEach(portfolioViewModel.positions) { position in
                                PortfolioPositionCard(
                                    position: position,
                                    currentPrice: portfolioViewModel.getCurrentPrice(for: position.cryptoId),
                                    onEdit: {
                                        editingPosition = position
                                    },
                                    onDelete: {
                                        portfolioViewModel.deletePosition(position)
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        portfolioViewModel.deletePosition(position)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.placeholderText)
            
            Text("No tienes posiciones")
                .font(.subheadline.bold())
                .foregroundColor(.secondaryText)
            
            Text("Comienza agregando tu primera criptomoneda")
                .font(.caption)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddPosition = true
            }) {
                Text("Agregar Primera Posición")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.cryptoBlue)
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 24)
    }
}

struct PortfolioPositionCard: View {
    let position: PortfolioPosition
    let currentPrice: Double?
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    
    var logoURL: URL? {
        URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(position.cryptoId).png")
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Header principal más compacto
            HStack(spacing: 12) {
                // Logo más pequeño
                if let url = logoURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle()
                            .fill(Color.surfaceBackground)
                            .overlay(
                                Text(position.cryptoSymbol.prefix(1))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondaryText)
                            )
                    }
                    .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(position.cryptoSymbol.prefix(1))
                                .font(.subheadline.bold())
                                .foregroundColor(.secondaryText)
                        )
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(position.cryptoName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    
                    Text(position.cryptoSymbol)
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Valor actual y ganancia/pérdida
                VStack(alignment: .trailing, spacing: 1) {
                    if let price = currentPrice {
                        Text(position.currentValue(currentPrice: price).toCurrency())
                            .font(.subheadline.bold())
                            .foregroundColor(.primaryText)
                        
                        let gainLoss = position.totalGainLoss(currentPrice: price)
                        let gainLossPercentage = position.gainLossPercentage(currentPrice: price)
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            HStack(spacing: 3) {
                                Image(systemName: gainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundColor(gainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                                    .font(.caption2)
                                
                                Text(gainLossPercentage.toPercentage())
                                    .font(.caption2.bold())
                                    .foregroundColor(gainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                            }
                            
                            Text(gainLoss.toCurrency())
                                .font(.caption2)
                                .foregroundColor(gainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                        }
                    } else {
                        Text("Cargando...")
                            .font(.caption2)
                            .foregroundColor(.placeholderText)
                    }
                }
            }
            
            // Información compacta
            if let price = currentPrice {
                Divider()
                    .padding(.vertical, 2)
                
                VStack(spacing: 6) {
                    // Información esencial en formato compacto
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Precio")
                                .font(.caption2)
                                .foregroundColor(.secondaryText)
                            Text(price.toCurrency())
                                .font(.caption.bold())
                                .foregroundColor(.primaryText)
                        }
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text("Compra")
                                .font(.caption2)
                                .foregroundColor(.secondaryText)
                            Text(position.purchasePrice.toCurrency())
                                .font(.caption.bold())
                                .foregroundColor(.primaryText)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Unidades")
                                .font(.caption2)
                                .foregroundColor(.secondaryText)
                            Text(position.amount.cleanAmountString())
                                .font(.caption.bold())
                                .foregroundColor(.primaryText)
                        }
                    }
                    
                    // Información adicional en una línea
                    HStack {
                        Text("Invertido: " + position.totalInvested.toCurrency())
                            .font(.caption2)
                            .foregroundColor(.tertiaryText)
                        
                        Spacer()
                        
                        Text(position.purchaseDate.toShortString())
                            .font(.caption2)
                            .foregroundColor(.tertiaryText)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .onLongPressGesture {
            showingActionSheet = true
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(position.cryptoName),
                message: Text("¿Qué deseas hacer con esta posición?"),
                buttons: [
                    .default(Text("Editar")) {
                        onEdit()
                    },
                    .destructive(Text("Eliminar")) {
                        onDelete()
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
} 