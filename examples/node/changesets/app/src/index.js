// tipcalc v1.0.0 — compute tip and total for a single restaurant bill.
const BILL = 80.00;
const TIP_RATE = 0.18;
const tip = BILL * TIP_RATE;
const total = BILL + tip;
console.log(`Bill: $${BILL.toFixed(2)}  Tip (${(TIP_RATE*100).toFixed(0)}%): $${tip.toFixed(2)}  Total: $${total.toFixed(2)}`);
