// TipCalc v2 — split the bill evenly among diners.
// All inputs are hard-coded constants; the program takes no arguments.
// This is the v2 implementation (feature: even split).

const double bill = 80.00;
const double tipRate = 0.18;
const int diners = 4;

double tip = bill * tipRate;
double total = bill + tip;
double perPerson = total / diners;

Console.WriteLine($"Bill: {bill:C}  Tip ({tipRate:P0}): {tip:C}  Total: {total:C}");
Console.WriteLine($"Split evenly among {diners} diners: {perPerson:C} each");
