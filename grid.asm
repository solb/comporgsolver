# grid.asm
# A array-based data structure for storing the trees puzzle.
# @author Sol Boucher <slb1566@rit.edu>

.globl	init_grid
.globl	len_grid
.globl	set_expected
.globl	get_expected
.globl	set_coordinate
.globl	print_grid

# The minimum edge length of the square grid.
MIN_LEN = 2

# The maximum edge length of the square grid.
MAX_LEN = 12

# The character used for the corners of the boarder.
BRDR_CRNR = 43 #"+"

# The character used for the horizontal border edges.
BRDR_HORZ = 45 #"-"

# The character used for the vertical border edges.
BRDR_VERT = 124 #"|"

# The system call for printing an int.
PRINT_INT = 1

# The system call for printing a string.
PRINT_STR = 4

.data
.align 2

len:	# The number of rows or columns.
	.word	0

.align 2
vals:	# byte[] - The values of all coordinate locations.
	.space	MAX_LEN*MAX_LEN

.align 2
tentsr:	# word[] - The number of tents in each row.
	.space	MAX_LEN*4
.align 2
tentsc: # word[] - The number of tents in each column.
	.space	MAX_LEN*4

.align 2
prntq:	# A holding location for char-strings before they're printed.
	.byte	0
	.byte	0
.align 2
prntnl: # A reserved NL string for whenever we need it.
	.asciiz "\n"
.align 2
prntsc:	# A reserved space string for whenever we need it.
	.asciiz " "

.text
.align 2

# Constructor.
# Initialize a grid of the specified dimensions.
# The provided character is used to populate the grid's contents.
# @a 0 size (edge length)
# @a 1 byte - initial fill character
# @v 0 1 for success, 0 for invalid size
init_grid:
	#if(size>=MIN_LEN && size<=MAX_LEN)
	#	len=size
	#	return 1
	#else
	#	return 0
	sge	$t0,$a0,MIN_LEN
	sle	$v0,$a0,MAX_LEN
	and	$v0,$t0,$v0 #must be within both bounds
	beq	$v0,$zero,bad_len
		#save the length:
		la	$t0,len
		sw	$a0,0($t0)
		
		#initialize our contents:
		mul	$t0,$a0,$a0
		la	$t2,vals #current row pointer
		add	$t0,$t2,$t0 #end-of-grid pointer
		initr: #iterate over rows
			move	$t3,$t2 #current col pointer
			add	$t1,$t3,$a0 #end-of-row pointer
			initc: #iterate over cols
				sb	$a1,0($t3)
				addi	$t3,$t3,1
				bne	$t3,$t1,initc #until out of cols
			move	$t2,$t1
			bne	$t2,$t0,initr #until out of rows
	bad_len:
	
	jr	$ra

# Length.
# @v 0 side length of this grid
len_grid:
	la	$t0,len
	lw	$v0,0($t0)
	jr	$ra

# @a 0 0 for row, 1 for column
# @a 1 row or column of interest
# @a 2 expected number of tents in that group
# @v 0 1 for success, 1 for unrealistic expectation
set_expected:
	sge	$t0,$a2,$zero
	
	#check against length as upper bound:
	la	$t1,len
	lw	$t1,0($t1)
	sle	$v0,$a2,$t1
	
	and	$v0,$t0,$v0 #must be within both bounds
	beq	$v0,$zero,bad_group
		#get the address of the row or col expectations:
		bne	$a0,$zero,exscol
			la	$t0,tentsr #using rows
			j	exspicked
		exscol:	la	$t0,tentsc #using cols
		exspicked:
		
		#store the given value in the correct place:
		mul	$a1,$a1,4
		add	$t0,$t0,$a1
		sw	$a2,0($t0)
	bad_group:
	
	jr	$ra

# @a 0 0 for row, 1 for column
# @a 1 row of interest
# @v 0 expected number of tents in that row
get_expected:
	#get the address of the row or col expectations:
	bne	$a0,$zero,exgcol
		la	$t0,tentsr #using rows
		j	exgpicked
	exgcol:	la	$t0,tentsc #using cols
	exgpicked:
	
	#load the value from the provided location:
	mul	$a1,$a1,4
	add	$t0,$t0,$a1
	lw	$v0,0($t0)
	jr	$ra

# @a 0 row coordinate
# @a 1 column coordinate
# @a 2 byte - value to store there
# @v 0 1 for success, 0 for bad coordinates
set_coordinate:
	la	$t0,len
	lw	$t0,0($t0) #pull in length
	
	#check provided coordinates:
	sge	$t1,$a0,$zero
	slt	$t2,$a0,$t0
	and	$v0,$t1,$t2
	sge	$t1,$a1,$zero
	slt	$t2,$a1,$t0
	and	$v0,$v0,$t1
	and	$v0,$v0,$t2
	
	#perform the changes if possible:
	beq	$v0,$zero,bad_coords #unless coordinates are bad
		mul	$a0,$a0,$t0 #rows are made up of _len_ columns
		la	$t0,vals #now a pointer to the grid contents
		add	$t0,$t0,$a0
		add	$t0,$t0,$a1
		sb	$a2,0($t0)
	bad_coords:
	
	jr	$ra

# Print out a horizontal border line.
# This forms the top and bottom of the cute frame around the board.
# It should only be called if the s-registers are already set up as described.
# @s 0 the grid's side length
# @s 1 the null-terminated holding place to use
print_hline:
	#print a corner piece:
	li	$t0,BRDR_CRNR
	sb	$t0,0($s1)
	li	$v0,PRINT_STR
	move	$a0,$s1
	syscall
	
	#print a horizontal piece:
	li	$t0,BRDR_HORZ
	sb	$t0,0($s1)
	li	$v0,PRINT_STR
	move	$a0,$s1
	syscall
	
	#print the right number of horizontals
	move	$t1,$zero #current index
	printhz:
		#print two more horizontals:
		li	$v0,PRINT_STR
		move	$a0,$s1
		syscall
		li	$v0,PRINT_STR
		move	$a0,$s1
		syscall
		
		addi	$t1,$t1,1
		bne	$t1,$s0,printhz #until we've placed enough
	
	#print a corner piece:
	li	$t0,BRDR_CRNR
	sb	$t0,0($s1)
	li	$v0,PRINT_STR
	move	$a0,$s1
	syscall
	
	#print a trailing newline:
	li	$v0,PRINT_STR
	la	$a0,prntnl
	syscall
	
	jr	$ra

# Print out the grid.
# This should only be called after all set_expected calls.
print_grid:
	addi	$sp,$sp,-16
	sw	$ra,0($sp)
	sw	$s0,4($sp)
	sw	$s1,8($sp)
	sw	$s2,12($sp)
	
	#pull in the needed resources:
	la	$s0,len
	lw	$s0,0($s0) #grab the length
	la	$s1,prntq #grab the null-terminated holding place
	la	$s2,tentsr #grab the rows' expected values
	
	#print the top of the border:
	jal	print_hline
	lw	$ra,0($sp)
	
	#print the main body of the board:
	mul	$t0,$s0,$s0
	la	$t2,vals #current row pointer
	add	$t0,$t2,$t0 #end-of-grid pointer
	printr: #iterate over rows
		move	$t3,$t2 #current col pointer
		add	$t1,$t3,$s0 #end-of-row pointer
		
		#print a buffered vertical piece:
		li	$t7,BRDR_VERT
		sb	$t7,0($s1)
		li	$v0,PRINT_STR
		move	$a0,$s1
		syscall
		li	$v0,PRINT_STR
		la	$a0,prntsc
		syscall
		
		printc: #iterate over cols
			#print each character and a trailing space
			li	$v0,PRINT_STR
			lb	$t6,0($t3) #character to print
			sb	$t6,0($s1) #put in front of a NULL
			move	$a0,$s1
			syscall
			li	$v0,PRINT_STR
			la	$a0,prntsc
			syscall
			
			addi	$t3,$t3,1
			bne	$t3,$t1,printc #until out of cols
		
		#print a buffered vertical piece:
		li	$t7,BRDR_VERT
		sb	$t7,0($s1)
		li	$v0,PRINT_STR
		move	$a0,$s1
		syscall
		li	$v0,PRINT_STR
		la	$a0,prntsc
		syscall
		
		#print the row expectation and return:
		li	$v0,PRINT_INT
		sub	$a0,$t0,$t2
		div	$a0,$a0,$s0
		sub	$a0,$s0,$a0 #our index: len-(end-row)/len
		mul	$a0,$a0,4 #moving from byte to word addressing
		add	$a0,$s2,$a0 #use as offset from expectedr's start
		lw	$a0,0($a0)
		syscall
		li	$v0,PRINT_STR
		la	$a0,prntnl
		syscall
		
		move	$t2,$t1
		bne	$t2,$t0,printr #until out of rows
	
	#print the bottom of the border:
	jal	print_hline
	lw	$ra,0($sp)
	
	#print the col expectations:
	li	$v0,PRINT_STR
	la	$a0,prntsc
	syscall
	li	$v0,PRINT_STR
	la	$a0,prntsc
	syscall
	la	$s2,tentsc #the cols' expected values
	move	$s1,$zero #current column index
	print_expdcol:
		#the meat of the matter:
		li	$a0,1 #looking at columns
		move	$a1,$s1 #our specific column
		jal	get_expected #related expectation
		lw	$ra,0($sp)
		move	$a0,$v0
		li	$v0,PRINT_INT
		syscall
		
		#what we use to fill the empty spaces:
		li	$v0,PRINT_STR
		la	$a0,prntsc
		syscall
		
		#where we used to talk:
		addi	$s1,$s1,1
		bne	$s1,$s0,print_expdcol #until we've hit each one
	
	#print extra newlines:
	li	$v0,PRINT_STR
	la	$a0,prntnl
	syscall
	li	$v0,PRINT_STR
	la	$a0,prntnl
	syscall
	
	lw	$s0,4($sp)
	lw	$s1,8($sp)
	lw	$s2,12($sp)
	addi	$sp,$sp,16
	jr	$ra
