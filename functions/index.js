const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
const cors = require("cors")({ origin: true });

const PAYPAL_CLIENT_ID = "BAAMZ-ZEnLfWLO2yETYC2x8mYuj98XnK_YhMPHPyj96ZravvAVDNdR1g90n3vW3vhLaPKZ2SMm64KyPy_0";
const PAYPAL_SECRET_KEY = "EKU2S6WiD3m87eGxh63KYpz9s2F7uWvumlNZidthrZn8u78ACV5p_uddtLXV-XfiFsCEaovcb0vVVRGR";

exports.createPayPalOrder = onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
      const { amount, currency, description, returnUrl, cancelUrl } = req.body;

      if (!amount || !currency || !returnUrl || !cancelUrl) {
        return res.status(400).json({ error: 'Missing required parameters' });
      }

      // Generate OAuth token
      const auth = Buffer.from(`${PAYPAL_CLIENT_ID}:${PAYPAL_SECRET_KEY}`).toString('base64');
      
      const tokenResponse = await axios.post(
        'https://api-m.sandbox.paypal.com/v1/oauth2/token',
        'grant_type=client_credentials',
        {
          headers: {
            'Authorization': `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          }
        }
      );

      const accessToken = tokenResponse.data.access_token;

      // Create Order
      const orderData = {
        intent: 'CAPTURE',
        purchase_units: [
          {
            amount: {
              currency_code: currency,
              value: parseFloat(amount).toFixed(2),
            },
            description: description || 'Pago de reserva',
          }
        ],
        application_context: {
          return_url: returnUrl,
          cancel_url: cancelUrl,
        }
      };

      const orderResponse = await axios.post(
        'https://api-m.sandbox.paypal.com/v2/checkout/orders',
        orderData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          }
        }
      );

      const links = orderResponse.data.links || [];
      const approveLink = links.find(link => link.rel === 'approve');

      if (!approveLink) {
        return res.status(500).json({ error: 'Approve link not found in PayPal response' });
      }

      return res.status(200).json({ approveUrl: approveLink.href });

    } catch (error) {
      logger.error("Error creating PayPal order", error.response?.data || error.message);
      return res.status(500).json({ 
        error: 'Error creating PayPal order', 
        details: error.response?.data || error.message 
      });
    }
  });
});
