// TipCalc v1.0.0 — compute a tip for a single bill (all constants).
// Later versions will split among diners (v2) and by weight (v3).

const decimal bill = 100.00m;
const decimal tipPercent = 0.18m;

decimal tip = bill * tipPercent;
decimal total = bill + tip;

Console.WriteLine($"Bill:  {bill:C}");
Console.WriteLine($"Tip:   {tip:C}  ({tipPercent:P0})");
Console.WriteLine($"Total: {total:C}");
