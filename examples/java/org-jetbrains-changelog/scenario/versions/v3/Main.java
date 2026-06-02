package tipcalc;

public class Main {
    public static void main(String[] args) {
        double bill = 80.00;
        double tipRate = 0.18;
        double tip = bill * tipRate;
        double total = bill + tip;

        String[] names   = {"Ada", "Linus", "Grace", "Dennis"};
        int[]    weights = {3, 2, 3, 2};
        int totalWeight = 0;
        for (int w : weights) totalWeight += w;

        System.out.printf("Bill: $%.2f  Tip (%.0f%%): $%.2f  Total: $%.2f%n",
                bill, tipRate * 100, tip, total);
        System.out.println("Uneven split by weight:");
        for (int i = 0; i < names.length; i++) {
            double share = total * weights[i] / totalWeight;
            System.out.printf("  %-8s (weight %d): $%.2f%n", names[i], weights[i], share);
        }
    }
}
