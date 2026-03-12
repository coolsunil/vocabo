require('dotenv').config();

const crypto = require('crypto');
const cors = require('cors');
const express = require('express');
const Razorpay = require('razorpay');

const app = express();
const port = Number(process.env.PORT || 4000);
const keyId = process.env.RAZORPAY_KEY_ID || '';
const keySecret = process.env.RAZORPAY_KEY_SECRET || '';
const premiumAmountPaise = Number(process.env.PREMIUM_AMOUNT_PAISE || 19900);
const premiumCurrency = process.env.PREMIUM_CURRENCY || 'INR';

if (!keyId || !keySecret) {
  console.error('Missing RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET in backend environment.');
  process.exit(1);
}

const razorpay = new Razorpay({
  key_id: keyId,
  key_secret: keySecret,
});

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'vocabo-backend' });
});

app.post('/api/payments/create-order', async (_req, res) => {
  try {
    const order = await razorpay.orders.create({
      amount: premiumAmountPaise,
      currency: premiumCurrency,
      receipt: `vocabo_${Date.now()}`,
      notes: {
        plan: 'premium_lifetime',
      },
    });

    res.json({
      keyId,
      amount: order.amount,
      currency: order.currency,
      orderId: order.id,
      name: 'Vocabo',
      description: 'Vocabo Premium Lifetime',
    });
  } catch (error) {
    console.error('Failed to create Razorpay order:', error);
    res.status(500).json({ message: 'Unable to create payment order.' });
  }
});

app.post('/api/payments/verify', (req, res) => {
  const { orderId, paymentId, signature } = req.body || {};

  if (!orderId || !paymentId || !signature) {
    return res.status(400).json({
      verified: false,
      message: 'orderId, paymentId and signature are required.',
    });
  }

  const expectedSignature = crypto
    .createHmac('sha256', keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');

  if (expectedSignature !== signature) {
    return res.status(400).json({
      verified: false,
      message: 'Payment signature verification failed.',
    });
  }

  return res.json({
    verified: true,
    plan: 'premium_lifetime',
    paymentId,
    orderId,
  });
});

app.listen(port, () => {
  console.log(`Vocabo backend listening on port ${port}`);
});
