// tipcalc v2.0.0 — split bill evenly among 4 diners.
const BILL = 80.00;
const TIP_RATE = 0.18;
const DINERS = 4;
const tip = BILL * TIP_RATE;
const total = BILL + tip;
const perPerson = total / DINERS;
console.log(`Bill: $${BILL.toFixed(2)}  Tip: $${tip.toFixed(2)}  Total: $${total.toFixed(2)}`);
console.log(`Split evenly among ${DINERS}: $${perPerson.toFixed(2)} each`);
