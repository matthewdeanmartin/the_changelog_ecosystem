// v3.0.0 - Split the bill unevenly by weight
const decimal bill = 45.00m;
const decimal tipPercent = 0.18m;

decimal[] weights = { 2m, 3m, 1m };
string[] names   = { "Alice", "Bob", "Carol" };

decimal total       = bill * (1 + tipPercent);
decimal totalWeight = weights.Sum();

Console.WriteLine($"Bill:  ${bill:F2}");
Console.WriteLine($"Tip:   ${bill * tipPercent:F2} ({tipPercent * 100:F0}%)");
Console.WriteLine($"Total: ${total:F2}");
Console.WriteLine();

for (int i = 0; i < names.Length; i++)
{
    decimal share = total * weights[i] / totalWeight;
    Console.WriteLine($"  {names[i],6} (weight {weights[i]}): ${share:F2}");
}
