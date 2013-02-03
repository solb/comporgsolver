# grid.asm
# A array-based data structure for storing the trees puzzle.
# @author Sol Boucher <slb1566@rit.edu>

.globl	init_grid

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
	and	$v0,$t0,$v0
	beq	$v0,$zero,bad_len
		la	$t0,len
		sw	$a0,0($t0)
	bad_len:
	
	jr	$ra
