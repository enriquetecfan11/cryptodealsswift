import SwiftUI

struct CryptoDetailView: View {
    @EnvironmentObject var viewModel: CryptoViewModel
    let cryptoId: String
    
    private var crypto: Cryptocurrency? {
        viewModel.getCrypto(by: cryptoId)
    }
    
    var body: some View {
        if let crypto = crypto {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: adaptiveSpacing) {
                        // Header principal
                        HStack(alignment: .center, spacing: adaptiveSpacing) {
                            Circle()
                                .fill(Color.surfaceBackground)
                                .frame(width: adaptiveLogoSize, height: adaptiveLogoSize)
                                .overlay(
                                    Text(crypto.symbol.prefix(1))
                                        .font(adaptiveSymbolFont)
                                        .foregroundColor(.secondaryText)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(crypto.name)
                                    .font(adaptiveNameFont)
                                    .foregroundColor(.primaryText)
                                    .lineLimit(DeviceInfo.isIPad ? 2 : 1)
                                Text(crypto.symbol)
                                    .font(adaptiveCaptionFont)
                                    .foregroundColor(.secondaryText)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(crypto.quote?.USD?.price?.formatted(.currency(code: "USD")) ?? "-")
                                    .font(adaptivePriceFont)
                                    .foregroundColor(.primaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .padding(.bottom, 4)
                        
                        Divider()
                            .background(Color.separatorColor)
                        
                        // Estadísticas de cambio
                        HStack(spacing: adaptiveSpacing) {
                            StatBox(title: "1h", value: crypto.quote?.USD?.percent_change_1h)
                            StatBox(title: "24h", value: crypto.quote?.USD?.percent_change_24h)
                            StatBox(title: "7d", value: crypto.quote?.USD?.percent_change_7d)
                        }
                        
                        Divider()
                            .background(Color.separatorColor)
                        
                        // Información detallada
                        VStack(spacing: adaptiveInfoSpacing) {
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
                    .padding(adaptivePadding)
                    .adaptiveFrame()
                }
                .background(Color.mainBackground.ignoresSafeArea())
                .navigationTitle(crypto.name)
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            ProgressView("Cargando detalles...")
                .navigationTitle("")
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 32 : (DeviceInfo.isLargeScreen ? 24 : 20)
    }
    
    private var adaptiveInfoSpacing: CGFloat {
        DeviceInfo.isIPad ? 20 : 16
    }
    
    private var adaptiveLogoSize: CGFloat {
        DeviceInfo.isIPad ? 64 : (DeviceInfo.isLargeScreen ? 52 : 48)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 32 : (DeviceInfo.isLargeScreen ? 24 : 20)
    }
    
    private var adaptiveNameFont: Font {
        DeviceInfo.isIPad ? .largeTitle.bold() : .title.bold()
    }
    
    private var adaptivePriceFont: Font {
        DeviceInfo.isIPad ? .title.bold() : .title2.bold()
    }
    
    private var adaptiveCaptionFont: Font {
        DeviceInfo.isIPad ? .title3 : .headline
    }
    
    private var adaptiveSymbolFont: Font {
        DeviceInfo.isIPad ? .largeTitle.bold() : .title.bold()
    }
}

struct StatBox: View {
    let title: String
    let value: Double?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(adaptiveTitleFont)
                .foregroundColor(.secondaryText)
            Text(value != nil ? String(format: "%+.2f%%", value!) : "-")
                .font(adaptiveValueFont)
                .foregroundColor((value ?? 0) >= 0 ? .cryptoGreen : .cryptoRed)
        }
        .frame(maxWidth: .infinity)
        .padding(adaptivePadding)
        .background(Color.surfaceBackground)
        .cornerRadius(adaptiveCornerRadius)
    }
    
    private var adaptiveTitleFont: Font {
        DeviceInfo.isIPad ? .footnote : .caption
    }
    
    private var adaptiveValueFont: Font {
        DeviceInfo.isIPad ? .title3.bold() : .headline
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 12 : 8
    }
    
    private var adaptiveCornerRadius: CGFloat {
        DeviceInfo.isIPad ? 12 : 8
    }
}

struct InfoRowPro: View {
    let label: String
    let value: String?
    let icon: String
    
    var body: some View {
        HStack(spacing: adaptiveSpacing) {
            Image(systemName: icon)
                .foregroundColor(.cryptoBlue)
                .frame(width: adaptiveIconSize)
                .font(adaptiveIconFont)
            Text(label)
                .font(adaptiveLabelFont)
                .foregroundColor(.secondaryText)
            Spacer()
            Text(value ?? "-")
                .font(adaptiveValueFont)
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 16 : 10
    }
    
    private var adaptiveIconSize: CGFloat {
        DeviceInfo.isIPad ? 28 : 22
    }
    
    private var adaptiveIconFont: Font {
        DeviceInfo.isIPad ? .title3 : .body
    }
    
    private var adaptiveLabelFont: Font {
        DeviceInfo.isIPad ? .body : .subheadline
    }
    
    private var adaptiveValueFont: Font {
        DeviceInfo.isIPad ? .body.bold() : .subheadline.bold()
    }
}
