package tipcalc;
public class Main {
    public static void main(String[] args) {
        double bill = 80.00;
        double tipRate = 0.18;
        double total = bill * (1 + tipRate);
        String[] names  = {"Ada", "Linus", "Grace", "Dennis"};
        int[]    weights = {3,    2,      3,      2};
        int totalWeight = 0;
        for (int w : weights) totalWeight += w;
        System.out.printf("Bill: $%.2f  Total with tip: $%.2f%n", bill, total);
        for (int i = 0; i < names.length; i++) {
            System.out.printf("  %s: $%.2f (weight %d)%n", names[i], total * weights[i] / totalWeight, weights[i]);
        }
    }
}
