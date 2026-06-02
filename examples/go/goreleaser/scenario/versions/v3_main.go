package main

import "fmt"

func main() {
	bill := 80.00
	tipRate := 0.18
	total := bill * (1 + tipRate)
	names := []string{"Ada", "Linus", "Grace", "Dennis"}
	weights := []int{3, 2, 3, 2}
	totalWeight := 0
	for _, w := range weights {
		totalWeight += w
	}
	fmt.Printf("Bill: $%.2f  Total with tip: $%.2f\n", bill, total)
	for i, name := range names {
		fmt.Printf("  %s: $%.2f (weight %d)\n", name, total*float64(weights[i])/float64(totalWeight), weights[i])
	}
}
