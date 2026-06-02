// v2.0.0 - Split the bill evenly among diners
const decimal bill = 45.00m;
const decimal tipPercent = 0.18m;
const int diners = 3;

decimal total = bill * (1 + tipPercent);
decimal perPerson = total / diners;

Console.WriteLine($"Bill:       ${bill:F2}");
Console.WriteLine($"Tip:        ${bill * tipPercent:F2} ({tipPercent * 100:F0}%)");
Console.WriteLine($"Total:      ${total:F2}");
Console.WriteLine($"Diners:     {diners}");
Console.WriteLine($"Per person: ${perPerson:F2}");
