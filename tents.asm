# tents.asm
# A solver for the Tents puzzle.
# @author Sol Boucher <slb1566@rit.edu>

.globl	main
.globl	init_grid
.globl	len_grid
.globl	set_expected
.globl	get_expected

# The symbol representing an undecided space.
SYMB_UNK = 32 #" "

# The symbol representing a definitely empty space.
SYMB_EMPT = 46 #"."

# The symbol representing a tree space.
SYMB_TREE = 84 #"T"

# The symbol representing a tent space.
SYMB_TENT = 65 #"A"

# The system call for reading an int.
READ_INT = 5

# The system call for printing a string.
PRINT_STR = 4

.data
.align 2

# The feedback to give on errors:
err_1:
	.asciiz	"Invalid board size, Tents terminating\n"
err_2:
	.asciiz	"Illegal sum value, Tents terminating\n"

.text
.align 2

main:
	addi	$sp,$sp,-4
	sw	$ra,0($sp)
	
	#prompt for size and initialize grid:
	li	$v0,READ_INT
	syscall
	move	$a0,$v0
	li	$a1,SYMB_EMPT
	jal	init_grid
	lw	$ra,0($sp)
	bne	$v0,$zero,ok_size #if out of range
		li	$v0,PRINT_STR
		la	$a0,err_1
		syscall
		jr	$ra #bail out!
	ok_size:
	
	#record the expected trees per row
	jal	len_grid
	lw	$ra,0($sp)
	move	$s0,$v0		#number of rows/cols
	move	$s1,$zero	#working with rows (not cols)
	move	$s2,$zero	#current index
	expect: #for each reported row or column
		#use current grouping scheme and index
		move	$a0,$s1
		move	$a1,$s2
		
		#use user-provided expected count:
		li	$v0,READ_INT
		syscall
		move	$a2,$v0
		
		#give setting that a try
		jal	set_expected
		lw	$ra,0($sp)
		bne	$v0,$zero,ok_expectation #if unreasonable
			li	$v0,PRINT_STR
			la	$a0,err_2
			syscall
			jr	$ra #bail out!
		ok_expectation:
		
		#increment counter and maybe loop:
		addi	$s2,$s2,1
		bne	$s2,$s0,expect #until out of groups
		
		#if we've done all the rows, do the columns:
		bne	$s1,$zero,expect_done #unless we've done cols, too
			li	$s1,1 #columns
			move	$s2,$zero #from the top---err, left
			j	expect
	expect_done:
	
	lw	$ra,0($sp)
	addi	$sp,$sp,4
	jr	$ra
