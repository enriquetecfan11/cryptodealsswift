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
        ZStack {
            VStack(alignment: .leading, spacing: 24) {
                // Balance y estadísticas
                portfolioHeaderView
                
                // Botones de acción
                actionButtonsView
                
                // Lista de posiciones
                positionsListView
                
                Spacer()
            }
            .padding()
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
    
    private var portfolioHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Balance total
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance Total")
                    .font(.headline)
                    .foregroundColor(.secondaryText)
                
                Text(portfolioViewModel.totalPortfolioValue.toCurrency())
                    .font(.largeTitle.bold())
                    .foregroundColor(.primaryText)
            }
            
            // Ganancia/Pérdida total
            if !portfolioViewModel.positions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    let totalGainLoss = portfolioViewModel.getTotalGainLoss()
                    let totalGainLossPercentage = portfolioViewModel.getTotalGainLossPercentage()
                    
                    Text("Ganancia/Pérdida Total")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 12) {
                        Text(totalGainLoss.toCurrency())
                            .font(.title2.bold())
                            .foregroundColor(totalGainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                        
                        HStack(spacing: 4) {
                            Image(systemName: totalGainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .foregroundColor(totalGainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                                .font(.caption)
                            
                            Text(totalGainLossPercentage.toPercentage())
                                .font(.headline)
                                .foregroundColor(totalGainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            Button(action: {
                showingAddPosition = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Agregar Posición")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            
            Button(action: {
                portfolioViewModel.refreshPrices()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Actualizar")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 2)
            }
        }
    }
    
    private var positionsListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mis Posiciones")
                .font(.headline)
                .foregroundColor(.secondaryText)
            
            if portfolioViewModel.positions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
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
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(.placeholderText)
            
            Text("No tienes posiciones")
                .font(.headline)
                .foregroundColor(.secondaryText)
            
            Text("Comienza agregando tu primera criptomoneda")
                .font(.subheadline)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddPosition = true
            }) {
                Text("Agregar Primera Posición")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cryptoBlue)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 40)
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
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Logo
                if let url = logoURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle()
                            .fill(Color.surfaceBackground)
                            .overlay(
                                Text(position.cryptoSymbol.prefix(1))
                                    .font(.title2.bold())
                                    .foregroundColor(.secondaryText)
                            )
                    }
                    .frame(width: 45, height: 45)
                } else {
                    Circle()
                        .fill(Color.surfaceBackground)
                        .frame(width: 45, height: 45)
                        .overlay(
                            Text(position.cryptoSymbol.prefix(1))
                                .font(.title2.bold())
                                .foregroundColor(.secondaryText)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(position.cryptoName)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text(position.cryptoSymbol)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Text("Invertido: " + position.totalInvested.toCurrency())
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let price = currentPrice {
                        Text(position.currentValue(currentPrice: price).toCurrency())
                            .font(.headline.bold())
                            .foregroundColor(.primaryText)
                        
                        let gainLoss = position.totalGainLoss(currentPrice: price)
                        let gainLossPercentage = position.gainLossPercentage(currentPrice: price)
                        
                        HStack(spacing: 4) {
                            Image(systemName: gainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .foregroundColor(gainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                                .font(.caption)
                            
                            Text(gainLossPercentage.toPercentage())
                                .font(.caption.bold())
                                .foregroundColor(gainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                        }
                        
                        Text(gainLoss.toCurrency())
                            .font(.caption)
                            .foregroundColor(gainLoss >= 0 ? .cryptoGreen : .cryptoRed)
                    } else {
                        Text("Cargando...")
                            .font(.caption)
                            .foregroundColor(.placeholderText)
                    }
                }
            }
            
            // Información adicional
            if let price = currentPrice {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Precio Actual")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        Text(price.toCurrency())
                            .font(.caption.bold())
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Precio Compra")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        Text(position.purchasePrice.toCurrency())
                            .font(.caption.bold())
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Fecha Compra")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        Text(position.purchaseDate.toShortString())
                            .font(.caption.bold())
                            .foregroundColor(.primaryText)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
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