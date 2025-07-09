# 📱 CryptoView - Aplicación de Seguimiento de Criptomonedas

Una aplicación iOS nativa desarrollada en SwiftUI para el seguimiento de criptomonedas y gestión de portafolios de inversión.

## 🎯 Descripción General

**CryptoView** es una aplicación móvil que permite a los usuarios:
- Consultar información en tiempo real de las principales criptomonedas
- Gestionar un portafolio personal de inversiones
- Seguir el rendimiento de sus inversiones con cálculos automáticos de ganancias/pérdidas
- Acceder a información detallada de cada criptomoneda

La aplicación está diseñada con un enfoque en la experiencia de usuario, ofreciendo una interfaz intuitiva y responsiva que se adapta tanto a iPhone como iPad, con soporte completo para modo oscuro.

## ✨ Características Principales

### 🏠 Pantalla de Inicio
- **Criptomonedas Destacadas**: Vista rápida de 6 criptomonedas principales (BTC, ETH, XRP, SOL, BNB, DOGE)
- **Cards Interactivas**: Cada card muestra precio actual y cambio en 24h
- **Navegación Directa**: Toque para acceder a detalles completos

### 📊 Lista de Criptomonedas
- **Catálogo Completo**: Lista de todas las criptomonedas disponibles
- **Diseño Adaptativo**: Grid de 2 columnas en iPad, lista en iPhone
- **Búsqueda y Filtrado**: Localización rápida de criptomonedas específicas
- **Carga Inteligente**: Sistema de loading con skeleton screens

### 🔍 Detalles de Criptomoneda
- **Información Completa**: Precio actual, capitalización de mercado, volumen 24h
- **Estadísticas Avanzadas**: Oferta circulante, máxima, total supply
- **Cambios de Precio**: Visualización de cambios en 1h, 24h y 7d
- **Metadatos**: Fecha de incorporación, ranking CMC, plataforma, etiquetas

### 💼 Portafolio Personal
- **Gestión de Inversiones**: Agregar, editar y eliminar posiciones
- **Cálculos Automáticos**: Ganancias/pérdidas en tiempo real
- **Resumen Financiero**: Valor total del portafolio y rendimiento general
- **Historial de Inversiones**: Fecha y precio de compra para cada posición

### ➕ Agregar Posición
- **Flujo Simplificado**: Selección de crypto, monto a invertir, precio y fecha
- **Cálculo Automático**: Las unidades se calculan automáticamente (inversión ÷ precio)
- **Autocompletado**: El precio se autocompleta con el valor actual de mercado
- **Previsualización**: Muestra estimado de unidades en tiempo real

## 🗺️ Flujo de Navegación

```
TabView Principal
├── 🏠 Inicio
│   ├── Cards Destacadas → Detalles de Crypto
│   └── Pull to Refresh
├── 📊 Lista
│   ├── Lista/Grid de Cryptos → Detalles de Crypto
│   ├── Búsqueda y Filtrado
│   └── Pull to Refresh
└── 💼 Portafolio
    ├── Resumen Financiero
    ├── Lista de Posiciones → Editar Posición
    ├── Botón Agregar → Agregar Posición
    └── Pull to Refresh
```

## 🌐 Fuentes de Datos

La aplicación utiliza la **CoinMarketCap API** con los siguientes endpoints:

### Endpoints Principales
- **`/v1/cryptocurrency/listings/latest`**
  - Obtiene lista de criptomonedas con precios actuales
  - Utilizado en: HomeView, CryptoListView, búsqueda de cryptos

- **`/v1/cryptocurrency/quotes/latest`**
  - Obtiene información detallada de una criptomoneda específica
  - Utilizado en: CryptoDetailView, actualización de datos específicos

### Configuración de API
```swift
// Headers requeridos
X-CMC_PRO_API_KEY: [API_KEY]
Accept: application/json

// Timeout configurado: 15 segundos
// Manejo de errores: HTTP status codes, timeouts, parsing errors
```

## 💰 Lógica de Inversión en el Portafolio

### Flujo de Creación de Posición
1. **Selección de Criptomoneda**: El usuario escoge de la lista completa
2. **Monto de Inversión**: Introduce cantidad en USD que desea invertir
3. **Precio de Compra**: Se autocompleta con precio actual (editable)
4. **Cálculo Automático**: `unidades = monto_invertido ÷ precio_unitario`
5. **Fecha de Compra**: Selección de fecha (default: hoy)
6. **Persistencia**: Guardado en UserDefaults con codificación JSON

### Cálculos Financieros
```swift
// Valor actual de la posición
valor_actual = unidades × precio_actual

// Ganancia/Pérdida
ganancia_perdida = valor_actual - monto_invertido

// Porcentaje de rendimiento
porcentaje = (ganancia_perdida ÷ monto_invertido) × 100
```

### Ejemplo Práctico
```
Usuario invierte: $500 USD
Precio Bitcoin: $50,000
Unidades calculadas: 0.01 BTC
Precio actual: $55,000
Valor actual: $550
Ganancia: $50 (+10%)
```

## 🏗️ Modelos de Datos

### Cryptocurrency
```swift
struct Cryptocurrency: Codable, Identifiable {
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
}
```

### PortfolioPosition
```swift
struct PortfolioPosition: Identifiable, Codable {
    let id: UUID
    let cryptoId: String
    let cryptoName: String
    let cryptoSymbol: String
    let amount: Double          // Unidades de la crypto
    let purchasePrice: Double   // Precio de compra por unidad
    let purchaseDate: Date      // Fecha de compra
}
```

### Quote (Cotización)
```swift
struct Quote: Codable {
    let USD: USD?
    
    struct USD: Codable {
        let price: Double?
        let percent_change_1h: Double?
        let percent_change_24h: Double?
        let percent_change_7d: Double?
        let market_cap: Double?
        let volume_24h: Double?
    }
}
```

## 🎨 Mejoras de Experiencia de Usuario

### 📱 Diseño Responsivo
- **iPhone**: Diseño optimizado para pantallas pequeñas y medianas
- **iPad**: Layouts expandidos con grids multi-columna
- **Adaptación Automática**: Fuentes, espaciados y componentes se ajustan según el dispositivo

### 🌙 Soporte de Temas
- **Dark Mode**: Soporte completo para modo oscuro
- **Colores Semánticos**: Uso de colores del sistema para mejor integración
- **Contraste Optimizado**: Colores específicos para crypto (verde/rojo) que respetan accesibilidad

### ⚡ Estados de Carga Inteligentes
- **Skeleton Screens**: Animaciones shimmer mientras cargan datos
- **Loading Overlays**: Indicadores elegantes con blur de fondo
- **Error States**: Manejo visual de errores con botones de retry
- **Pull to Refresh**: Actualización manual en todas las pantallas

### 🔄 Gestión de Estados
```swift
enum LoadingState {
    case idle
    case loading
    case success
    case failure(String)
}
```

### 🎯 Funcionalidades Avanzadas
- **Autocompletado**: Precio se autocompleta al seleccionar crypto
- **Cálculo en Tiempo Real**: Muestra unidades estimadas mientras se escribe
- **Navegación Inteligente**: Precarga de datos antes de navegar
- **Persistencia**: Portafolio guardado localmente con UserDefaults
- **Validación**: Formularios con validación en tiempo real
- **Feedback Táctil**: Animaciones y efectos visuales en interacciones

### 🛡️ Manejo de Errores
- **Timeouts**: 15 segundos para requests HTTP
- **Validación de Respuestas**: Verificación de status codes
- **Mensajes Contextuales**: Errores específicos según la situación
- **Retry Automático**: Botones para reintentar cargas fallidas

## 🚀 Instrucciones para Ejecutar el Proyecto

### Prerrequisitos
- Xcode 15.0 o superior
- iOS 16.0 o superior
- Cuenta de CoinMarketCap API

### Configuración
1. **Clonar el repositorio**
   ```bash
   git clone [URL_DEL_REPOSITORIO]
   cd cryptoviewapp
   ```

2. **Configurar API Key**
   - Abrir `CryptoViewModel.swift`
   - Reemplazar `API_KEY` con tu clave de CoinMarketCap
   ```swift
   let apiKey = "TU_API_KEY_AQUI"
   ```

3. **Ejecutar el proyecto**
   - Abrir `cryptoviewapp.xcodeproj` en Xcode
   - Seleccionar dispositivo/simulador
   - Presionar ⌘+R para ejecutar

### Estructura del Proyecto
```
cryptoviewapp/
├── Models/
│   ├── Cryptocurrency.swift
│   └── PortfolioPosition.swift
├── Views/
│   ├── HomeView.swift
│   ├── CryptoListView.swift
│   ├── CryptoDetailView.swift
│   ├── PortfolioView.swift
│   ├── AddPositionView.swift
│   └── Extensions.swift
├── ViewModels/
│   ├── CryptoViewModel.swift
│   └── PortfolioViewModel.swift
├── Services/
│   └── CryptoService.swift
└── CryptoAppApp.swift
```

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📞 Contacto

Para preguntas o sugerencias sobre el proyecto, puedes contactar a través de GitHub Issues.

---

**Desarrollado con ❤️ usando SwiftUI**
