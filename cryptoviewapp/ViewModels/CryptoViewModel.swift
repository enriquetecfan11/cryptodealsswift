
import Foundation

class CryptoViewModel: ObservableObject {
    @Published var cryptos: [Cryptocurrency] = []
    @Published var isLoadingDetail: Bool = false
    
    private let service = CryptoService()
    
    func fetchCryptos() {
        // --- CONEXIÓN REAL A LA API DE COINMARKETCAP ---
        // PON AQUÍ TU API KEY REAL:
        let apiKey = "b80ea0fe-203f-4203-b0cc-f4cb3c28e040"
        guard let url = URL(string: "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let decoded = try JSONDecoder().decode(CryptoListResponse.self, from: data)
                DispatchQueue.main.async {
                    self.cryptos = decoded.data
                }
            } catch {
                print("Error decodificando: \(error)")
            }
        }.resume()
    }

    func getCrypto(by id: String) -> Cryptocurrency? {
        return cryptos.first { String($0.id) == id }
    }
    
    func fetchCryptoDetail(id: String, completion: @escaping (Bool) -> Void) {
        isLoadingDetail = true
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
                    completion(true)
                case .failure(let error):
                    print("Error obteniendo detalle: \(error)")
                    completion(false)
                }
            }
        }
    }
}

struct CryptoListResponse: Codable {
    let data: [Cryptocurrency]
}
