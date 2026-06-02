// TipCalc v3 — split the bill unevenly by per-person weight.
// All inputs are hard-coded constants; the program takes no arguments.
// This is the v3 implementation (feature: weighted/uneven split).

const double bill = 80.00;
const double tipRate = 0.18;

double[] weights = { 3.0, 2.0, 2.0, 1.0 }; // relative shares per diner
double totalWeight = 0;
foreach (var w in weights) totalWeight += w;

double tip = bill * tipRate;
double total = bill + tip;

Console.WriteLine($"Bill: {bill:C}  Tip ({tipRate:P0}): {tip:C}  Total: {total:C}");
Console.WriteLine($"Split unevenly among {weights.Length} diners by weight:");
for (int i = 0; i < weights.Length; i++)
{
    double share = total * (weights[i] / totalWeight);
    Console.WriteLine($"  Diner {i + 1} (weight {weights[i]}): {share:C}");
}
