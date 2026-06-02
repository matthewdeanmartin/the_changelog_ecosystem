package tipcalc;
public class Main {
    public static void main(String[] args) {
        double bill = 80.00;
        double tipRate = 0.18;
        double tip = bill * tipRate;
        double total = bill + tip;
        System.out.printf("Bill: $%.2f  Tip (%.0f%%): $%.2f  Total: $%.2f%n", bill, tipRate * 100, tip, total);
    }
}
