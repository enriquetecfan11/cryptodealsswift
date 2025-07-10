
import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
}

class CryptoViewModel: ObservableObject {
    @Published var cryptos: [Cryptocurrency] = []
    @Published var isLoadingDetail: Bool = false
    @Published var loadingState: LoadingState = .idle
    @Published var detailLoadingState: LoadingState = .idle
    @Published var errorMessage: String?
    @Published var favoriteIds: Set<String> = []
    @Published var searchText: String = ""
    @Published var isGridView: Bool = false
    @Published var updatingPrices: Bool = false
    
    private let service = CryptoService()
    private let favoritesKey = "favorite_cryptos"
    
    var filteredCryptos: [Cryptocurrency] {
        if searchText.isEmpty {
            return cryptos
        } else {
            return cryptos.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.symbol.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init() {
        loadFavorites()
    }
    
    func toggleFavorite(id: String) {
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
        saveFavorites()
    }
    
    func isFavorite(id: String) -> Bool {
        favoriteIds.contains(id)
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoriteIds = Set(saved)
        }
    }
    
    func fetchCryptos() {
        // Evitar múltiples cargas simultáneas
        guard loadingState != .loading else { return }
        
        loadingState = .loading
        errorMessage = nil
        
        // --- CONEXIÓN REAL A LA API DE COINMARKETCAP ---
        let apiKey = "b80ea0fe-203f-4203-b0cc-f4cb3c28e040"
        guard let url = URL(string: "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest") else { 
            loadingState = .failure("Error de configuración")
            return 
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.timeoutInterval = 15.0 // Timeout de 15 segundos
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.loadingState = .failure("Error de conexión: \(error.localizedDescription)")
                    self.errorMessage = "Error de conexión. Verifica tu internet e intenta nuevamente."
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.loadingState = .failure("Respuesta inválida del servidor")
                    self.errorMessage = "Error del servidor. Intenta nuevamente."
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    self.loadingState = .failure("Error HTTP: \(httpResponse.statusCode)")
                    self.errorMessage = "Error del servidor (\(httpResponse.statusCode)). Intenta nuevamente."
                    return
                }
                
                guard let data = data else {
                    self.loadingState = .failure("No se recibieron datos")
                    self.errorMessage = "No se recibieron datos. Intenta nuevamente."
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(CryptoListResponse.self, from: data)
                    self.cryptos = decoded.data
                    self.loadingState = .success
                    self.errorMessage = nil
                } catch {
                    self.loadingState = .failure("Error decodificando datos: \(error.localizedDescription)")
                    self.errorMessage = "Error procesando datos. Intenta nuevamente."
                }
            }
        }.resume()
    }
    
    func retryCryptos() {
        fetchCryptos()
    }

    func getCrypto(by id: String) -> Cryptocurrency? {
        return cryptos.first { String($0.id) == id }
    }
    
    func fetchCryptoDetail(id: String, completion: @escaping (Bool) -> Void) {
        // Evitar múltiples cargas simultáneas
        guard !isLoadingDetail else { 
            completion(false)
            return 
        }
        
        isLoadingDetail = true
        detailLoadingState = .loading
        errorMessage = nil
        
        service.fetchCryptoDetail(id: id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingDetail = false
                
                switch result {
                case .success(let crypto):
                    if let index = self.cryptos.firstIndex(where: { $0.id == id }) {
                        self.cryptos[index] = crypto
                    } else {
                        self.cryptos.append(crypto)
                    }
                    self.detailLoadingState = .success
                    self.errorMessage = nil
                    completion(true)
                case .failure(let error):
                    self.detailLoadingState = .failure(error.localizedDescription)
                    self.errorMessage = "Error cargando detalles: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    func retryDetailLoad(id: String, completion: @escaping (Bool) -> Void) {
        fetchCryptoDetail(id: id, completion: completion)
    }
    
    func clearErrors() {
        errorMessage = nil
        if case .failure(_) = loadingState {
            loadingState = .idle
        }
        if case .failure(_) = detailLoadingState {
            detailLoadingState = .idle
        }
    }
    
    func fetchHistoricalPrices(for id: String, completion: @escaping ([Double]?) -> Void) {
        // Últimas 24h, intervalo 1h
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
        let formatter = ISO8601DateFormatter()
        let timeStart = formatter.string(from: start)
        service.fetchHistoricalPrices(for: id, interval: "1h", timeStart: timeStart, timeEnd: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let quotes):
                    let prices = quotes.map { $0.quote.USD.price }
                    completion(prices)
                case .failure(_):
                    completion(nil)
                }
            }
        }
    }
}

struct CryptoListResponse: Codable {
    let data: [Cryptocurrency]
}
