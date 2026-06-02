package main

import "fmt"

func main() {
	bill := 80.00
	tipRate := 0.18
	diners := 4
	tip := bill * tipRate
	total := bill + tip
	perPerson := total / float64(diners)
	fmt.Printf("Bill: $%.2f  Tip: $%.2f  Total: $%.2f\n", bill, tip, total)
	fmt.Printf("Split evenly among %d: $%.2f each\n", diners, perPerson)
}
