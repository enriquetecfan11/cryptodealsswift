struct Cryptocurrency: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let symbol: String
    let quote: Quote?
    let cmc_rank: Int?
    let date_added: String?
    let tags: [String]?
    let circulating_supply: Double?
    let total_supply: Double?
    let max_supply: Double?
    let platform: Platform?
    var sparkline: [Double]? = nil // Para el gráfico miniatura

    struct Platform: Codable, Hashable {
        let name: String?
        // Inicializador público
        init(name: String?) {
            self.name = name
        }
    }

    struct Quote: Codable, Hashable {
        let USD: USD?
        // Inicializador público
        init(USD: USD?) {
            self.USD = USD
        }

        struct USD: Codable, Hashable {
            let price: Double?
            let percent_change_1h: Double?
            let percent_change_24h: Double?
            let percent_change_7d: Double?
            let market_cap: Double?
            let volume_24h: Double?
            // Inicializador público
            init(price: Double?, percent_change_1h: Double?, percent_change_24h: Double?, percent_change_7d: Double?, market_cap: Double?, volume_24h: Double?) {
                self.price = price
                self.percent_change_1h = percent_change_1h
                self.percent_change_24h = percent_change_24h
                self.percent_change_7d = percent_change_7d
                self.market_cap = market_cap
                self.volume_24h = volume_24h
            }
        }
    }

    // Inicializador público para uso manual
    init(id: String, name: String, symbol: String, quote: Quote?, cmc_rank: Int?, date_added: String?, tags: [String]?, circulating_supply: Double?, total_supply: Double?, max_supply: Double?, platform: Platform?) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.quote = quote
        self.cmc_rank = cmc_rank
        self.date_added = date_added
        self.tags = tags
        self.circulating_supply = circulating_supply
        self.total_supply = total_supply
        self.max_supply = max_supply
        self.platform = platform
    }

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, quote, cmc_rank, date_added, tags, circulating_supply, total_supply, max_supply, platform
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decodifica id como String o Int
        if let stringId = try? container.decode(String.self, forKey: .id) {
            id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: [CodingKeys.id], debugDescription: "id no es String ni Int convertible"))
        }
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        symbol = (try? container.decode(String.self, forKey: .symbol)) ?? ""
        quote = try? container.decode(Quote.self, forKey: .quote)
        cmc_rank = try? container.decode(Int.self, forKey: .cmc_rank)
        date_added = try? container.decode(String.self, forKey: .date_added)
        tags = try? container.decode([String].self, forKey: .tags)
        circulating_supply = try? container.decode(Double.self, forKey: .circulating_supply)
        total_supply = try? container.decode(Double.self, forKey: .total_supply)
        max_supply = try? container.decode(Double.self, forKey: .max_supply)
        platform = try? container.decode(Platform.self, forKey: .platform)
    }
}