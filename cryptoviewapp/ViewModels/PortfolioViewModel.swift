import Foundation
import Combine

class PortfolioViewModel: ObservableObject {
    @Published var positions: [PortfolioPosition] = []
    @Published var totalPortfolioValue: Double = 0.0
    @Published var isLoading: Bool = false
    
    private let cryptoViewModel: CryptoViewModel
    private let userDefaults = UserDefaults.standard
    private let positionsKey = "portfolio_positions"
    
    init(cryptoViewModel: CryptoViewModel) {
        self.cryptoViewModel = cryptoViewModel
        loadPositions()
    }
    
    // MARK: - Persistencia
    private func savePositions() {
        do {
            let data = try JSONEncoder().encode(positions)
            userDefaults.set(data, forKey: positionsKey)
        } catch {
            print("Error guardando posiciones: \(error)")
        }
    }
    
    private func loadPositions() {
        guard let data = userDefaults.data(forKey: positionsKey) else { return }
        do {
            positions = try JSONDecoder().decode([PortfolioPosition].self, from: data)
            calculateTotalValue()
        } catch {
            print("Error cargando posiciones: \(error)")
        }
    }
    
    // MARK: - Operaciones CRUD
    func addPosition(_ position: PortfolioPosition) {
        // Verificar si ya existe una posición para esta crypto
        if let existingIndex = positions.firstIndex(where: { $0.cryptoId == position.cryptoId }) {
            // Actualizar cantidad (promedio de precios)
            let existingPosition = positions[existingIndex]
            let totalAmount = existingPosition.amount + position.amount
            let totalValue = (existingPosition.amount * existingPosition.purchasePrice) + (position.amount * position.purchasePrice)
            let averagePrice = totalValue / totalAmount
            
            let updatedPosition = PortfolioPosition(
                cryptoId: position.cryptoId,
                cryptoName: position.cryptoName,
                cryptoSymbol: position.cryptoSymbol,
                amount: totalAmount,
                purchasePrice: averagePrice,
                purchaseDate: existingPosition.purchaseDate
            )
            positions[existingIndex] = updatedPosition
        } else {
            positions.append(position)
        }
        savePositions()
        calculateTotalValue()
    }
    
    func updatePosition(_ position: PortfolioPosition) {
        if let index = positions.firstIndex(where: { $0.id == position.id }) {
            positions[index] = position
            savePositions()
            calculateTotalValue()
        }
    }
    
    func deletePosition(_ position: PortfolioPosition) {
        positions.removeAll { $0.id == position.id }
        savePositions()
        calculateTotalValue()
    }
    
    // MARK: - Cálculos
    func calculateTotalValue() {
        totalPortfolioValue = 0.0
        
        for position in positions {
            if let crypto = cryptoViewModel.getCrypto(by: position.cryptoId),
               let currentPrice = crypto.quote?.USD?.price {
                totalPortfolioValue += position.currentValue(currentPrice: currentPrice)
            }
        }
    }
    
    func getCurrentPrice(for cryptoId: String) -> Double? {
        return cryptoViewModel.getCrypto(by: cryptoId)?.quote?.USD?.price
    }
    
    func getTotalGainLoss() -> Double {
        var totalGainLoss = 0.0
        
        for position in positions {
            if let currentPrice = getCurrentPrice(for: position.cryptoId) {
                totalGainLoss += position.totalGainLoss(currentPrice: currentPrice)
            }
        }
        
        return totalGainLoss
    }
    
    func getTotalGainLossPercentage() -> Double {
        let totalInvested = positions.reduce(0) { $0 + ($1.amount * $1.purchasePrice) }
        guard totalInvested > 0 else { return 0 }
        return (getTotalGainLoss() / totalInvested) * 100
    }
    
    // MARK: - Actualización de precios
    func refreshPrices() {
        isLoading = true
        cryptoViewModel.fetchCryptos()
        
        // Simular un pequeño delay para mostrar loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.calculateTotalValue()
            self.isLoading = false
        }
    }
} 