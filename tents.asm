# Copyright (C) 2012 Sol Boucher
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with it.  If not, see <http://www.gnu.org/licenses/>.

# tents.asm
# A solver for the Tents puzzle.
# @author Sol Boucher <slb1566@rit.edu>

.globl	main
.globl	init_grid
.globl	len_grid
.globl	set_expected
.globl	get_expected
.globl	count_up_group
.globl	validate_board
.globl	validate_coords
.globl	set_coordinate
.globl	get_coordinate
.globl	print_grid
.globl	next_tent
.globl	init_trees
.globl	iter_deref

# The symbol representing an undecided space.
SYMB_UNK = 95 #"_"

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

# The feedback to give during a normal run:
out_1:
	.asciiz "\n******************\n**     TENTS    **\n******************\n\n"
out_2:
	.asciiz "Initial Puzzle\n\n"
out_3:
	.asciiz "Final Puzzle\n\n"

# The feedback to give on errors:
err_1:
	.asciiz	"Invalid board size, Tents terminating\n"
err_2:
	.asciiz	"Illegal sum value, Tents terminating\n"
err_3:
	.asciiz "Illegal number of trees, Tents terminating\n"
err_4:
	.asciiz "Illegal tree location, Tents terminating\n"
err_5:
	.asciiz "Impossible Puzzle\n\n"

.text
.align 2

main:
	addi	$sp,$sp,-16
	sw	$ra,0($sp)
	sw	$s0,4($sp)
	sw	$s1,8($sp)
	sw	$s2,12($sp)
	
	#print a pretty banner:
	li	$v0,PRINT_STR
	la	$a0,out_1
	syscall
	
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
		#use user-provided expected count:
		li	$v0,READ_INT
		syscall
		move	$a2,$v0
		
		#give setting that a try
		move	$a0,$s1
		move	$a1,$s2
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
	
	#add trees:
	li	$v0,READ_INT
	syscall
	move	$s1,$v0 #now holds number of trees
	slt	$t0,$s1,$zero
	beq	$t0,$zero,ok_numtrees #if numtrees *is* negative
		li	$v0,PRINT_STR
		la	$a0,err_3
		syscall
		jr	$ra #bail out!
	ok_numtrees:
	move	$s2,$zero #now holds the current index
	j	plantfeet #while instead of do-while
	plantanother:
		#get the user's coordinate pair:
		li	$v0,READ_INT
		syscall
		move	$t0,$v0
		li	$v0,READ_INT
		syscall
		
		addi	$s2,$s2,1
		#prepare and check it for resale:
		move	$a0,$t0
		move	$a1,$v0
		li	$a2,SYMB_TREE #it's a tree we're planting
		jal	set_coordinate
		lw	$ra,0($sp)
		bne	$v0,$zero,plantfeet #if unreasonable
			li	$v0,PRINT_STR
			la	$a0,err_4
			syscall
			jr	$ra #bail out!
		plantfeet: #incrementation loop bound-checking
		bne	$s2,$s1,plantanother #until we've collected enough
	
	#initialize tree structures and find possible tents:
	li	$a0,SYMB_TREE #tree
	li	$a1,SYMB_EMPT #empty
	li	$a2,SYMB_UNK #undetermined
	jal	init_trees
	lw	$ra,0($sp)
	
	#print the initial board:
	li	$v0,PRINT_STR
	la	$a0,out_2
	syscall
	#move	$a0,$zero
	li	$a0,SYMB_TREE
	li	$a1,SYMB_UNK
	li	$a2,SYMB_EMPT
	jal	print_grid
	lw	$ra,0($sp)
	
	#perform the backtracking:
	# s0 now contains the board's side length
	# s1 now contains the number of trees
	beq	$s1,$zero,possible #empty puzzles mustn't go through the solver
	move	$s2,$zero #now contains our tree iterator
	backtrack: #do
		move	$a0,$s2
		jal	iter_deref
		lw	$ra,0($sp)
		move	$a0,$v0
		move	$a1,$v1
		li	$a2,SYMB_UNK
		li	$a3,SYMB_TENT
		jal	next_tent
		lw	$ra,0($sp)
		beq	$v0,$zero,backup #if there was a valid state
			addi	$s2,$s2,1
			j incremented
		backup: #else we need to step backward
			addi	$s2,$s2,-1
			slt	$t0,$s2,$zero
			bne	$t0,$zero,impossible
		incremented:
	bne	$s2,$s1,backtrack #while not done
	
	#check our work:
	li	$a0,SYMB_TENT
	jal	validate_board
	lw	$ra,0($sp)
	beq	$v0,$zero,backup #retry if invalid
	
	possible:
		#print the valid board:
		li	$v0,PRINT_STR
		la	$a0,out_3
		syscall
		#move	$a0,$zero
		li	$a0,SYMB_TREE
		li	$a1,SYMB_UNK
		li	$a2,SYMB_EMPT
		jal	print_grid
		lw	$ra,0($sp)
		j	probable
	impossible:
		#alert the user:
		li	$v0,PRINT_STR
		la	$a0,err_5
		syscall
	probable:
	
	lw	$s0,4($sp)
	lw	$s1,8($sp)
	lw	$s2,12($sp)
	addi	$sp,$sp,16
	jr	$ra
