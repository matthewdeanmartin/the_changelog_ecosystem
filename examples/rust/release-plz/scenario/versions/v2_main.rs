// tipcalc v2.0.0 — split the bill EVENLY among a constant number of diners.
const BILL: f64 = 80.00;
const TIP_RATE: f64 = 0.18;
const DINERS: u32 = 4;

fn main() {
    let tip = BILL * TIP_RATE;
    let total = BILL + tip;
    let per_person = total / DINERS as f64;
    println!("Bill: ${:.2}  Tip ({:.0}%): ${:.2}  Total: ${:.2}  Split evenly {} ways: ${:.2} each",
        BILL, TIP_RATE * 100.0, tip, total, DINERS, per_person);
}
