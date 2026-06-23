module.exports = async (req, res) => {
  // Configurar CORS para permitir que la web de Flutter se comunique
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  // Si es una petición de verificación (preflight) de CORS, responder OK
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Credenciales de PayPal
  const PAYPAL_CLIENT_ID = "BAAMZ-ZEnLfWLO2yETYC2x8mYuj98XnK_YhMPHPyj96ZravvAVDNdR1g90n3vW3vhLaPKZ2SMm64KyPy_0";
  const PAYPAL_SECRET_KEY = "EKU2S6WiD3m87eGxh63KYpz9s2F7uWvumlNZidthrZn8u78ACV5p_uddtLXV-XfiFsCEaovcb0vVVRGR";

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const { amount, currency, description, returnUrl, cancelUrl } = body;

    const auth = Buffer.from(`${PAYPAL_CLIENT_ID}:${PAYPAL_SECRET_KEY}`).toString('base64');
    
    // Paso 1: Obtener Token de Acceso
    const tokenRes = await fetch('https://api-m.sandbox.paypal.com/v1/oauth2/token', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials'
    });
    
    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;

    if (!accessToken) {
       return res.status(500).json({ error: 'Failed to get PayPal token' });
    }

    // Paso 2: Crear Orden
    const orderData = {
      intent: 'CAPTURE',
      purchase_units: [{
        amount: { currency_code: currency, value: parseFloat(amount).toFixed(2) },
        description: description || 'Pago de reserva'
      }],
      application_context: { return_url: returnUrl, cancel_url: cancelUrl }
    };

    const orderRes = await fetch('https://api-m.sandbox.paypal.com/v2/checkout/orders', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(orderData)
    });

    const orderJson = await orderRes.json();
    const approveLink = orderJson.links?.find(link => link.rel === 'approve');

    if (!approveLink) {
        return res.status(500).json({ error: 'Approve link not found' });
    }
    
    // Paso 3: Retornar el link a Flutter
    return res.status(200).json({ approveUrl: approveLink.href });
  } catch (error) {
    console.error("Error backend:", error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};
