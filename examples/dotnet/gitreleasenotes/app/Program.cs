// v1.0.0 - Compute tip for a single bill
const decimal bill = 45.00m;
const decimal tipPercent = 0.18m;

decimal tip = bill * tipPercent;
decimal total = bill + tip;

Console.WriteLine($"Bill:  ${bill:F2}");
Console.WriteLine($"Tip:   ${tip:F2} ({tipPercent * 100:F0}%)");
Console.WriteLine($"Total: ${total:F2}");
