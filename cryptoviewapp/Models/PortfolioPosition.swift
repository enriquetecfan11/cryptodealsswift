import Foundation

struct PortfolioPosition: Identifiable, Codable {
    let id: UUID
    let cryptoId: String
    let cryptoName: String
    let cryptoSymbol: String
    var amount: Double
    let purchasePrice: Double
    let purchaseDate: Date
    
    init(id: UUID = UUID(), cryptoId: String, cryptoName: String, cryptoSymbol: String, amount: Double, purchasePrice: Double, purchaseDate: Date) {
        self.id = id
        self.cryptoId = cryptoId
        self.cryptoName = cryptoName
        self.cryptoSymbol = cryptoSymbol
        self.amount = amount
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
    }
}

extension PortfolioPosition {
    var totalInvested: Double {
        return amount * purchasePrice
    }
    
    func currentValue(currentPrice: Double) -> Double {
        return amount * currentPrice
    }
    
    func totalGainLoss(currentPrice: Double) -> Double {
        return currentValue(currentPrice: currentPrice) - totalInvested
    }
    
    func gainLossPercentage(currentPrice: Double) -> Double {
        guard totalInvested > 0 else { return 0 }
        return (totalGainLoss(currentPrice: currentPrice) / totalInvested) * 100
    }
} 