// tipcalc v3.0.0 — split the bill UNEVENLY by constant per-person weights.
const BILL: f64 = 80.00;
const TIP_RATE: f64 = 0.18;

fn main() {
    let tip = BILL * TIP_RATE;
    let total = BILL + tip;
    let weights = [("Ada", 3.0_f64), ("Linus", 2.0), ("Grace", 1.0), ("Dennis", 1.0)];
    let denom: f64 = weights.iter().map(|(_, w)| w).sum();
    println!("Bill: ${:.2}  Tip ({:.0}%): ${:.2}  Total: ${:.2}", BILL, TIP_RATE * 100.0, tip, total);
    println!("Split unevenly by weight:");
    for (name, w) in &weights {
        let share = total * (w / denom);
        println!("  {}: ${:.2}", name, share);
    }
}
