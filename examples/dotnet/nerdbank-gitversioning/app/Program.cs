// TipCalc v1 — compute a tip for a single bill.
// All inputs are hard-coded constants; the program takes no arguments.
// This is the v1 (initial release) implementation.

const double bill = 80.00;
const double tipRate = 0.18;

double tip = bill * tipRate;
double total = bill + tip;

Console.WriteLine($"Bill: {bill:C}  Tip ({tipRate:P0}): {tip:C}  Total: {total:C}");
