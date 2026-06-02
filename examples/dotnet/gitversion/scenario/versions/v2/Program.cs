// TipCalc v2 — split the bill evenly among diners
const decimal bill = 85.00m;
const decimal tipPercent = 18.0m;
const int diners = 4;

decimal tip = bill * tipPercent / 100m;
decimal total = bill + tip;
decimal perPerson = total / diners;

Console.WriteLine($"Bill:        ${bill:F2}");
Console.WriteLine($"Tip:         ${tip:F2} ({tipPercent}%)");
Console.WriteLine($"Total:       ${total:F2}");
Console.WriteLine($"Diners:      {diners}");
Console.WriteLine($"Per person:  ${perPerson:F2}");
