
import Foundation

private let apiKey = "b80ea0fe-203f-4203-b0cc-f4cb3c28e040"
private let url = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest"

class CryptoService {
    func fetchCryptocurrencies(completion: @escaping (Result<[Cryptocurrency], Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Sin datos"])))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(CoinMarketCapResponse.self, from: data)
                completion(.success(decoded.data))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// Estructura para decodificar la respuesta de CoinMarketCap
struct CoinMarketCapResponse: Codable {
    let data: [Cryptocurrency]
}

// Modelo para el historial de precios
struct HistoricalPriceResponse: Codable {
    let data: HistoricalPriceData
}

struct HistoricalPriceData: Codable {
    let quotes: [HistoricalQuote]
}

struct HistoricalQuote: Codable {
    let timestamp: String
    let quote: Quote
    
    struct Quote: Codable {
        let USD: USD
        struct USD: Codable {
            let price: Double
        }
    }
}

extension CryptoService {
    func fetchHistoricalPrices(for id: String, interval: String = "1h", timeStart: String? = nil, timeEnd: String? = nil, completion: @escaping (Result<[HistoricalQuote], Error>) -> Void) {
        var urlString = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/historical?id=\(id)&interval=\(interval)"
        if let timeStart = timeStart {
            urlString += "&time_start=\(timeStart)"
        }
        if let timeEnd = timeEnd {
            urlString += "&time_end=\(timeEnd)"
        }
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Sin datos"])))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(HistoricalPriceResponse.self, from: data)
                completion(.success(decoded.data.quotes))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Detalle de una criptomoneda
extension CryptoService {
    func fetchCryptoDetail(id: String, completion: @escaping (Result<Cryptocurrency, Error>) -> Void) {
        let endpoint = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?id=\(id)"
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Sin datos"])))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(CryptoDetailResponse.self, from: data)
                if let crypto = decoded.data.values.first {
                    completion(.success(crypto))
                } else {
                    completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Datos no encontrados"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// Estructura para decodificar respuesta de quotes/latest
struct CryptoDetailResponse: Codable {
    let data: [String: Cryptocurrency]
}
