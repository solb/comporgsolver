# tents.asm
# A solver for the Tents puzzle.
# @author Sol Boucher <slb1566@rit.edu>

.globl	main
.globl	init_grid

# The system call for reading an int.
READ_INT = 5

# The system call for printing a string.
PRINT_STR = 4

.data
.align 2

# The feedback for invalid sizes.
err_1:
	.asciiz	"Invalid board size, Tents terminating\n"

.text
.align 2

main:
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	
	#prompt for size and initialize grid:
	li	$v0,READ_INT
	syscall
	move	$a0,$v0
	jal	init_grid
	lw	$ra,0($sp)
	bne	$v0,$zero,ok_size
		li	$v0,PRINT_STR
		la	$a0,err_1
		syscall
		jr	$ra
	ok_size:
	
	lw	$ra,0($sp)
	addi	$sp,$sp,4
	jr	$ra
