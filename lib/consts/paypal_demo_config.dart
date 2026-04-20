class PayPalDemoConfig {
  const PayPalDemoConfig._();

  // Sandbox credentials only. This client-side setup is for demo/testing,
  // not for production.
  static const String clientId = 'AdA-tH0966GNvgonAtR1hJVozrjrW9WZKiiVMRae4zZAGiqmi_alqTHLkdwBe8B-GNB7AZHL2dpXYerG';
  static const String secretKey = 'EEHL-PnXXsnCod-Fueo2SPbKPN4VC-yeA-PVwmtgNnPTiDKRJAz6OncinTvZawa-SwO1xiS6AJJHDvK7';

  // PayPal REST payments do not support RSD, so the demo checkout is sent in EUR.
  // Adjust this manually if you want a different demo exchange rate.
  static const String currencyCode = 'EUR';
  static const double rsdPerEuro = 117.0;

  static const String returnUrl = 'https://uninotes.demo/paypal-success';
  static const String cancelUrl = 'https://uninotes.demo/paypal-cancel';

  static bool get isConfigured {
    return !clientId.contains('PASTE_YOUR') && !secretKey.contains('PASTE_YOUR');
  }
}
