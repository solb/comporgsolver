# grid.asm
# A array-based data structure for storing the trees puzzle.
# @author Sol Boucher <slb1566@rit.edu>

.globl	init_grid
.globl	len_grid
.globl	set_expected
.globl	set_expected

# The minimum edge length of the square grid.
MIN_LEN = 2

# The maximum edge length of the square grid.
MAX_LEN = 12

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

.text
.align 2

# Constructor.
# Initialize a grid of the specified dimensions.
# @a 0 size (edge length)
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
		la	$t0,len
		sw	$a0,0($t0)
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
