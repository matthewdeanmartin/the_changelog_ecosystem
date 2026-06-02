// tipcalc v3.0.0 — split bill unevenly by per-person weights.
const BILL = 80.00;
const TIP_RATE = 0.18;
const total = BILL * (1 + TIP_RATE);
const weights = { Ada: 3, Linus: 2, Grace: 3, Dennis: 2 };
const totalWeight = Object.values(weights).reduce((a, b) => a + b, 0);
console.log(`Bill: $${BILL.toFixed(2)}  Total with tip: $${total.toFixed(2)}`);
Object.entries(weights).forEach(([name, w]) => {
  console.log(`  ${name}: $${(total * w / totalWeight).toFixed(2)} (weight ${w})`);
});
