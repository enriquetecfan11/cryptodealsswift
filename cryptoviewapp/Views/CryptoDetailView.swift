import SwiftUI

struct CryptoDetailView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    let cryptoId: String
    
    private var crypto: Cryptocurrency? {
        viewModel.getCrypto(by: cryptoId)
    }
    
    var body: some View {
        if let crypto = crypto {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .center, spacing: 14) {
                        Circle()
                            .fill(Color.surfaceBackground)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(crypto.symbol.prefix(1))
                                    .font(.title.bold())
                                    .foregroundColor(.secondaryText)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(crypto.name)
                                .font(.title.bold())
                                .foregroundColor(.primaryText)
                            Text(crypto.symbol)
                                .font(.headline)
                                .foregroundColor(.secondaryText)
                        }
                        Spacer()
                        Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                            .font(.title2.bold())
                            .foregroundColor(.primaryText)
                    }
                    .padding(.bottom, 4)
                    Divider()
                        .background(Color.separatorColor)
                    HStack(spacing: 16) {
                        StatBox(title: "1h", value: crypto.quote?.USD?.percent_change_1h)
                        StatBox(title: "24h", value: crypto.quote?.USD?.percent_change_24h)
                        StatBox(title: "7d", value: crypto.quote?.USD?.percent_change_7d)
                    }
                    Divider()
                        .background(Color.separatorColor)
                    VStack(spacing: 16) {
                        InfoRowPro(label: "Capitalización de mercado", value: crypto.quote?.USD?.market_cap?.formatted(.currency(code: "USD")), icon: "chart.bar.fill")
                        InfoRowPro(label: "Volumen (24h)", value: crypto.quote?.USD?.volume_24h?.formatted(.currency(code: "USD")), icon: "waveform.path.ecg")
                        InfoRowPro(label: "Oferta circulante", value: crypto.circulating_supply?.formatted(), icon: "arrow.2.circlepath.circle")
                        InfoRowPro(label: "Oferta total", value: crypto.total_supply?.formatted(), icon: "circle.grid.cross")
                        InfoRowPro(label: "Oferta máxima", value: crypto.max_supply?.formatted(), icon: "lock.circle")
                        InfoRowPro(label: "Ranking CMC", value: crypto.cmc_rank != nil ? "#\(crypto.cmc_rank!)" : "-", icon: "number.circle")
                        InfoRowPro(label: "Fecha de incorporación", value: crypto.date_added, icon: "calendar")
                        InfoRowPro(label: "Plataforma", value: crypto.platform?.name, icon: "cube")
                        if let tags = crypto.tags, !tags.isEmpty {
                            InfoRowPro(label: "Etiquetas", value: tags.joined(separator: ", "), icon: "tag")
                        }
                    }
                    .padding(.top, 8)
                    Spacer()
                }
                .padding()
            }
            .background(Color.mainBackground.ignoresSafeArea())
            .navigationTitle(crypto.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ProgressView("Cargando detalles...")
                .navigationTitle("")
        }
    }
}

struct StatBox: View {
    let title: String
    let value: Double?
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryText)
            Text(value != nil ? String(format: "%+.2f%%", value!) : "-")
                .font(.headline)
                .foregroundColor((value ?? 0) >= 0 ? .cryptoGreen : .cryptoRed)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.surfaceBackground)
        .cornerRadius(8)
    }
}

struct InfoRowPro: View {
    let label: String
    let value: String?
    let icon: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.cryptoBlue)
                .frame(width: 22)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            Spacer()
            Text(value ?? "-")
                .font(.subheadline.bold())
                .foregroundColor(.primaryText)
        }
    }
}
