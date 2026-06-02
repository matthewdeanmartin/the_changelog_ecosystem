// TipCalc v3 — split the bill unevenly by per-person weight
const decimal bill = 85.00m;
const decimal tipPercent = 18.0m;

decimal[] weights = [3.0m, 2.0m, 1.0m, 1.0m];
string[] names = ["Alice", "Bob", "Carol", "Dave"];

decimal tip = bill * tipPercent / 100m;
decimal total = bill + tip;
decimal totalWeight = weights.Sum();

Console.WriteLine($"Bill:  ${bill:F2}");
Console.WriteLine($"Tip:   ${tip:F2} ({tipPercent}%)");
Console.WriteLine($"Total: ${total:F2}");
Console.WriteLine();
Console.WriteLine("Per-person breakdown (weighted):");
for (int i = 0; i < names.Length; i++)
{
    decimal share = total * weights[i] / totalWeight;
    Console.WriteLine($"  {names[i],-6} (weight {weights[i]}): ${share:F2}");
}
