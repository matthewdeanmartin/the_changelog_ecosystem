// tipcalc v1.0.0 — compute tip and total for a single restaurant bill.
const BILL: f64 = 80.00;
const TIP_RATE: f64 = 0.18;

fn main() {
    let tip = BILL * TIP_RATE;
    let total = BILL + tip;
    println!("Bill: ${:.2}  Tip ({:.0}%): ${:.2}  Total: ${:.2}",
        BILL, TIP_RATE * 100.0, tip, total);
}
