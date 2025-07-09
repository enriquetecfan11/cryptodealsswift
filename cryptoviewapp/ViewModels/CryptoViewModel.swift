
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
    
    private let service = CryptoService()
    
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
}

struct CryptoListResponse: Codable {
    let data: [Cryptocurrency]
}
