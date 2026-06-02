package main

import "fmt"

func main() {
	bill := 80.00
	tipRate := 0.18
	tip := bill * tipRate
	total := bill + tip
	fmt.Printf("Bill: $%.2f  Tip (%.0f%%): $%.2f  Total: $%.2f\n", bill, tipRate*100, tip, total)
}
