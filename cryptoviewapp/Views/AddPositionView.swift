import SwiftUI

struct AddPositionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    @ObservedObject var cryptoViewModel: CryptoViewModel
    
    @State private var selectedCrypto: Cryptocurrency?
    @State private var investmentAmount: String = ""
    @State private var purchasePrice: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var showingCryptoSelection = false
    @FocusState private var focusedField: Field?
    
    let editingPosition: PortfolioPosition?
    var preselectedCrypto: Cryptocurrency? = nil

    enum Field: Hashable {
        case investment, price
    }
    
    init(portfolioViewModel: PortfolioViewModel, cryptoViewModel: CryptoViewModel, editingPosition: PortfolioPosition? = nil, preselectedCrypto: Cryptocurrency? = nil) {
        self.portfolioViewModel = portfolioViewModel
        self.cryptoViewModel = cryptoViewModel
        self.editingPosition = editingPosition
        self.preselectedCrypto = preselectedCrypto
        
        // Inicialización de estado
        if let position = editingPosition {
            _selectedCrypto = State(initialValue: cryptoViewModel.getCrypto(by: position.cryptoId))
            _investmentAmount = State(initialValue: String(format: "%.2f", position.totalInvested))
            _purchasePrice = State(initialValue: String(format: "%.6f", position.purchasePrice))
            _purchaseDate = State(initialValue: position.purchaseDate)
        } else if let crypto = preselectedCrypto {
            _selectedCrypto = State(initialValue: crypto)
            if let price = crypto.quote?.USD?.price {
                _purchasePrice = State(initialValue: String(format: "%.6f", price))
            } else {
                _purchasePrice = State(initialValue: "")
            }
            _investmentAmount = State(initialValue: "")
            _purchaseDate = State(initialValue: Date())
        } else {
            _selectedCrypto = State(initialValue: nil)
            _investmentAmount = State(initialValue: "")
            _purchasePrice = State(initialValue: "")
            _purchaseDate = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: adaptiveSpacing) {
                        // Selección de criptomoneda
                        VStack(alignment: .leading, spacing: adaptiveSpacing * 0.4) {
                            Text("Criptomoneda")
                                .font(adaptiveHeaderFont)
                                .foregroundColor(.secondaryText)
                            
                            Button(action: {
                                showingCryptoSelection = true
                            }) {
                            HStack {
                                if let crypto = selectedCrypto {
                                    AsyncImage(url: URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.surfaceBackground)
                                            .overlay(
                                                Text(crypto.symbol.prefix(1))
                                                    .font(.caption.bold())
                                                    .foregroundColor(.secondaryText)
                                            )
                                    }
                                    .frame(width: 30, height: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(crypto.name)
                                            .font(.headline)
                                            .foregroundColor(.primaryText)
                                        Text(crypto.symbol)
                                            .font(.caption)
                                            .foregroundColor(.secondaryText)
                                    }
                                } else {
                                    Text("Seleccionar criptomoneda")
                                        .foregroundColor(.placeholderText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.tertiaryText)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.surfaceBackground)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(editingPosition != nil)
                    }
                    
                    // Cantidad a invertir
                    VStack(alignment: .leading, spacing: adaptiveSpacing * 0.4) {
                        Text("Cantidad a invertir (USD)")
                            .font(adaptiveHeaderFont)
                            .foregroundColor(.secondaryText)
                        
                        TextField("0.00", text: $investmentAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .investment)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Hecho") {
                                        focusedField = nil
                                    }
                                }
                            }
                        
                        // Mostrar aproximación de unidades que se comprarán
                        if let investmentValue = Double(investmentAmount.replacingOccurrences(of: ",", with: ".")),
                           let priceValue = Double(purchasePrice.replacingOccurrences(of: ",", with: ".")),
                           investmentValue > 0, priceValue > 0 {
                            let estimatedUnits = investmentValue / priceValue
                            HStack {
                                Image(systemName: "calculator")
                                    .foregroundColor(.cryptoBlue)
                                    .font(adaptiveCaptionFont)
                                Text("Unidades estimadas: \(estimatedUnits.cleanAmountString())")
                                    .font(adaptiveCaptionFont)
                                    .foregroundColor(.cryptoBlue)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // Precio de compra
                    VStack(alignment: .leading, spacing: adaptiveSpacing * 0.4) {
                        Text("Precio de compra (USD)")
                            .font(adaptiveHeaderFont)
                            .foregroundColor(.secondaryText)
                        
                        TextField("0.0", text: $purchasePrice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .price)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Hecho") {
                                        focusedField = nil
                                    }
                                }
                            }
                    }
                    
                    // Fecha de compra
                    VStack(alignment: .leading, spacing: adaptiveSpacing * 0.4) {
                        Text("Fecha de compra")
                            .font(adaptiveHeaderFont)
                            .foregroundColor(.secondaryText)
                        
                        adaptiveDatePicker
                    }
                }
                .padding(adaptivePadding)
                .adaptiveFrame()
            }
                .navigationTitle(editingPosition != nil ? "Editar Posición" : "Agregar Posición")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancelar") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(editingPosition != nil ? "Actualizar" : "Agregar") {
                            savePosition()
                        }
                        .disabled(!isValidForm)
                    }
                }
                .sheet(isPresented: $showingCryptoSelection) {
                    CryptoSelectionView(
                        cryptoViewModel: cryptoViewModel,
                        selectedCrypto: Binding(
                            get: { selectedCrypto },
                            set: { newValue in
                                selectedCrypto = newValue
                                // Autocompletar precio de compra con el precio actual
                                if let price = newValue?.quote?.USD?.price {
                                    purchasePrice = String(format: "%.6f", price)
                                }
                            }
                        ),
                        isPresented: $showingCryptoSelection
                    )
                }
            }
            .onAppear {
                if let position = editingPosition {
                    // El estado ya se inicializa en el init
                } else if preselectedCrypto == nil {
                    // Forzar selección si no hay preselección
                    showingCryptoSelection = true
                }
            }
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isIPad ? 24 : (DeviceInfo.isLargeScreen ? 20 : 16)
    }
    
    private var adaptivePadding: CGFloat {
        DeviceInfo.isIPad ? 32 : (DeviceInfo.isLargeScreen ? 24 : 20)
    }
    
    private var adaptiveHeaderFont: Font {
        DeviceInfo.isIPad ? .title3.bold() : .headline
    }
    
    private var adaptiveCaptionFont: Font {
        DeviceInfo.isIPad ? .footnote : .caption
    }
    
    @ViewBuilder
    private var adaptiveDatePicker: some View {
        if DeviceInfo.isIPad {
            DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
        } else {
            DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
        }
    }
    
    private var isValidForm: Bool {
        guard selectedCrypto != nil,
              let investmentValue = Double(investmentAmount.replacingOccurrences(of: ",", with: ".")), investmentValue > 0,
              let priceValue = Double(purchasePrice.replacingOccurrences(of: ",", with: ".")), priceValue > 0 else {
            return false
        }
        return true
    }
    
    private func savePosition() {
        guard let crypto = selectedCrypto,
              let investmentValue = Double(investmentAmount.replacingOccurrences(of: ",", with: ".")),
              let priceValue = Double(purchasePrice.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        
        // Calcular la cantidad de unidades basándose en el monto invertido
        // Ejemplo: Si invierte $50 en Bitcoin a $25,000 por unidad
        // calculatedAmount = $50 / $25,000 = 0.002 unidades de Bitcoin
        let calculatedAmount = investmentValue / priceValue
        
        let position = PortfolioPosition(
            cryptoId: crypto.id,
            cryptoName: crypto.name,
            cryptoSymbol: crypto.symbol,
            amount: calculatedAmount,
            purchasePrice: priceValue,
            purchaseDate: purchaseDate
        )
        
        if editingPosition != nil {
            portfolioViewModel.updatePosition(position)
        } else {
            portfolioViewModel.addPosition(position)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct CryptoSelectionView: View {
    @ObservedObject var cryptoViewModel: CryptoViewModel
    @Binding var selectedCrypto: Cryptocurrency?
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredCryptos: [Cryptocurrency] {
        if searchText.isEmpty {
            return cryptoViewModel.cryptos
        } else {
            return cryptoViewModel.cryptos.filter { crypto in
                crypto.name.localizedCaseInsensitiveContains(searchText) ||
                crypto.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                List(filteredCryptos) { crypto in
                    Button(action: {
                        selectedCrypto = crypto
                        isPresented = false
                    }) {
                        HStack {
                            AsyncImage(url: URL(string: "https://s2.coinmarketcap.com/static/img/coins/64x64/\(crypto.id).png")) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Circle()
                                    .fill(Color.surfaceBackground)
                                    .overlay(
                                        Text(crypto.symbol.prefix(1))
                                            .font(.caption.bold())
                                            .foregroundColor(.secondaryText)
                                    )
                            }
                            .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading) {
                                Text(crypto.name)
                                    .font(.headline)
                                    .foregroundColor(.primaryText)
                                Text(crypto.symbol)
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                            
                            Spacer()
                            
                            if let price = crypto.quote?.USD?.price {
                                Text(price.formatted(.currency(code: "USD")))
                                    .font(.caption)
                                    .foregroundColor(.tertiaryText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Seleccionar Crypto")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                }
            )
        }
        .onAppear {
            if cryptoViewModel.cryptos.isEmpty {
                cryptoViewModel.fetchCryptos()
            }
        }
    }
} 