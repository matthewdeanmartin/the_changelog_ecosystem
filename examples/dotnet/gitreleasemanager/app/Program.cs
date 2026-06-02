// TipCalc v1 — compute tip for a single bill (hard-coded constants)
const decimal bill = 85.00m;
const decimal tipPercent = 18.0m;

decimal tip = bill * tipPercent / 100m;
decimal total = bill + tip;

Console.WriteLine($"Bill:  ${bill:F2}");
Console.WriteLine($"Tip:   ${tip:F2} ({tipPercent}%)");
Console.WriteLine($"Total: ${total:F2}");
