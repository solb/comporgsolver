# grid.asm
# A array-based data structure for storing the trees puzzle.
# @author Sol Boucher <slb1566@rit.edu>

.globl	init_grid
.globl	len_grid
.globl	set_expected
.globl	get_expected
.globl	validate_coords
.globl	set_coordinate
.globl	get_coordinate
.globl	print_grid
.globl	next_tent
.globl	init_trees
.globl	iter_deref

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

# The (exclusive) ceiling indicating a tent.
UPPER_TENT = 5

# The zero character for tent translations.
ZERO_TENT = 48

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
treeit: # half[] - Pairs of coordinates corresponding to each tree (ending -1,-1).
	.space	MAX_LEN*MAX_LEN*2

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

# Checks a coordinate pair for validity
# @a 0 row coordinate
# @a 1 column coordinate
# @v 0 1 for valid, 0 for out-of-bounds
validate_coords:
	la	$t0,len
	lw	$t0,0($t0)
	
	#check provided coordinates:
	sge	$t1,$a0,$zero
	slt	$t2,$a0,$t0
	and	$v0,$t1,$t2
	sge	$t1,$a1,$zero
	slt	$t2,$a1,$t0
	and	$v0,$v0,$t1
	and	$v0,$v0,$t2
	
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

# @a0 the row coordinate
# @a1 the column coordinate
# @v0 byte - the value retrieved
get_coordinate:
	la	$t0,len
	lw	$t0,0($t0) #pull in length
	mul	$a0,$a0,$t0 #rows are major
	la	$t0,vals #address of grid itself
	add	$t0,$t0,$a0
	add	$t0,$t0,$a1 #cols are minor
	lb	$v0,0($t0)
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
			
			#convert into a number if necessary:
			slti	$t7,$t6,UPPER_TENT
			beq	$t7,$zero,isnttree #if an rotating tree
				addi	$t6,$t6,ZERO_TENT
			isnttree:
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

# Checks whether a coordinate pair is adjacent (including diagonally) to a symbol.
# @a 0 the row coordinate
# @a 1 the column coordiante
# @a 2 the symbol
# @v 0 whether it is adjacent
coord_adjacency:
	addi	$sp,$sp,-28
	sw	$ra,0($sp)
	sw	$s0,4($sp)
	sw	$s1,8($sp)
	sw	$s2,12($sp)
	sw	$s3,16($sp)
	sw	$s4,20($sp)
	sw	$s5,24($sp)
	
	move	$s0,$a0 #base row
	move	$s1,$a1 #base col
	move	$s2,$a2 #symb
	li	$s3,2 #max offset
	li	$s4,-1 #row offset
	outer:
		li	$s5,-1 #col offset
		checkadj:
			#don't compare given coordinates to themselves:
			seq	$t0,$s4,$zero
			seq	$t1,$s5,$zero
			and	$t0,$t0,$t1
			bne	$t0,$zero,skip #continue if on coordinates themselves
			
			#don't follow coordinates off the map:
			add	$a0,$s0,$s4 #calc row
			add	$a1,$s1,$s5 #calc col
			jal	validate_coords
			lw	$ra,0($sp)
			beq	$v0,$zero,skip #continue if out-of-bounds
			
			#finish if the target character was found:
			add	$a0,$s0,$s4 #calc row
			add	$a1,$s1,$s5 #calc col
			jal	get_coordinate
			lw	$ra,0($sp)
			beq	$v0,$s2,yesitis #break if adjacency found
			
			#increment and condition:
			skip:
			addi	$s5,$s5,1
			bne	$s5,$s3,checkadj #until done with row
		#increment and condition:
		addi	$s4,$s4,1
		bne	$s4,$s3,outer #until done with rows
	#we made it through, so it isn't adjacent:
	move	$v0,$zero
	j	noitisnt
	
	yesitis: #adjacent
		li	$v0,1
	noitisnt:
	
	lw	$s0,4($sp)
	lw	$s1,8($sp)
	lw	$s2,12($sp)
	lw	$s3,16($sp)
	lw	$s4,20($sp)
	lw	$s5,24($sp)
	addi	$sp,$sp,28
	jr	$ra

# Determines the tent corresponding to a tree's current state
# @a 0 the row coordinate of the TREE
# @a 1 the column coordinate of the TREE
# @v 0 the row coordinate of the TENT (or -1 if no tent)
# @v 1 the column coordinate of the TENT (or -1 if no tent)
find_tent_by_tree:
	addi	$sp,$sp,-12
	sw	$ra,0($sp)
	sw	$s0,4($sp)
	sw	$s1,8($sp)
	
	#get the tree's counter state:
	move	$s0,$a0 #row
	move	$s1,$a1 #col
	jal	get_coordinate
	lw	$ra,0($sp)
	move	$t0,$v0 #the tree's state

	#preload return values with tree coordinates:
	move	$v0,$s0 #row
	move	$v1,$s1 #col
	
	move	$t1,$zero #the current case being checked
	bne	$t0,$t1,side1 #if no side
		#use sentinels:
		li	$v0,-1
		li	$v1,-1
		j	checked #no need to recheck
	side1:
	addi	$t1,$t1,1
	bne	$t0,$t1,side2 #else if side 1
		#go right:
		addi	$v0,$s0,0
		addi	$v1,$s1,1
		j	desided
	side2:
	addi	$t1,$t1,1
	bne	$t0,$t1,side3 #else if side 2
		#go down:
		addi	$v0,$s0,1
		addi	$v1,$s1,0
		j	desided
	side3:
	addi	$t1,$t1,1
	bne	$t0,$t1,side4 #else if side 3
		#go left:
		addi	$v0,$s0,0
		addi	$v1,$s1,-1
		j	desided
	side4:
	#else side 4
		#go up:
		addi	$v0,$s0,-1
		addi	$v1,$s1,0
	desided:
	
	#retrieve length:
	la	$t2,len
	lw	$t2,0($t2)
	
	#check lower bounds:
	slt	$t0,$s0,$zero
	slt	$t1,$s1,$zero
	or	$t0,$t0,$t1
	
	#check upper bounds:
	sge	$t1,$s0,$t2
	sge	$t2,$s1,$t2
	or	$t1,$t1,$t2
	
	#use sentinels if they're off the edge:
	or	$t0,$t0,$t1
	beq	$t0,$zero,checked #if coordinates invalid
		li	$v0,-1
		li	$v1,-1
	checked:
	
	lw	$s0,4($sp)
	lw	$s1,8($sp)
	addi	$sp,$sp,12
	jr	$ra

# Moves a tree's tent to the next possible place, if possible.
# If there is no possible next state, the tree is reset to having no tents.
# @a 0 the row coordinate of the TREE
# @a 1 the column coordinate of the TREE
# @a 2 the indeterminate symbol
# @a 3 the tent symbol
# @v 0 whether the operation was successful (there was another state)
next_tent:
	addi	$sp,$sp,-32
	sw	$ra,0($sp)
	sw	$s0,4($sp)
	sw	$s1,8($sp)
	sw	$s2,12($sp)
	sw	$s3,16($sp)
	sw	$s4,20($sp)
	sw	$s5,24($sp)
	sw	$s6,28($sp)
	
	move	$s0,$a0 #tree row
	move	$s1,$a1	#tree col
	move	$s2,$a2 #indeterminate symbol
	move	$s3,$a3 #tent symbol
	
	#get rid of the old:
	jal	find_tent_by_tree
	lw	$ra,0($sp)
	slt	$t3,$v0,$zero
	bne	$t3,$zero,notentyet #if there is a tent
		move	$a0,$v0 #row
		move	$a1,$v1 #col
		move	$a2,$s2 #we'll erase that tent
		jal	set_coordinate
		lw	$ra,0($sp)
	notentyet:
	
	#retrieve the current tree state:
	move	$a0,$s0 #row
	move	$a1,$s1 #col
	jal	get_coordinate
	lw	$ra,0($sp)
	move	$s4,$v0 #s4 holds the tree's tent rotation
	
	tryincrement: #do
		#increment the state:
		addi	$s4,$s4,1
		rem	$s4,$s4,5
		move	$a0,$s0 #row
		move	$a1,$s1 #col
		move	$a2,$s4 #new value
		jal	set_coordinate
		lw	$ra,0($sp)
		
		#break if rotation finished:
		move	$v0,$zero #assume failure
		beq	$s4,$zero,skiptent #it did
		
		#locate where our tent might go:
		move	$a0,$s0 #row
		move	$a1,$s1 #col
		jal	find_tent_by_tree
		lw	$ra,0($sp)
		move	$s5,$v0 #now holds TENT row
		move	$s6,$v1 #now holds TENT col
		
		#check whether we're out-of-bounds:
		move	$a0,$s5 #TENT row
		move	$a1,$s6 #TENT col
		jal	validate_coords
		lw	$ra,0($sp)
		beq	$v0,$zero,tryincrement
		
		#check whether that spot is already taken:
		move	$a0,$s5 #TENT row
		move	$a1,$s6 #TENT col
		jal	get_coordinate
		lw	$ra,0($sp)
		bne	$v0,$s2,tryincrement
		
		#check whether there are already adjacent tents:
		move	$a0,$s5 #TENT row
		move	$a1,$s6 #TENT col
		move	$a2,$s3 #tent symbol
		jal	coord_adjacency
		lw	$ra,0($sp)
		beq	$v0,$zero,planttent #no adjacency found
		j	tryincrement
	
	planttent: #if we found an availability:
	move	$a0,$s5 #TENT row
	move	$a1,$s6 #TENT col
	move	$a2,$s3 #place a tent
	jal	set_coordinate
	lw	$ra,0($sp)
	li	$v0,1 #we've had a little bit of luck
	skiptent:
	
	lw	$s0,4($sp)
	lw	$s1,8($sp)
	lw	$s2,12($sp)
	lw	$s3,16($sp)
	lw	$s4,20($sp)
	sw	$s5,24($sp)
	sw	$s6,28($sp)
	addi	$sp,$sp,32
	jr	$ra

# Initializes the trees to empty-tent states.
# Also marks the surrounding spaces as unknown (possible tents).
# @a 0 the symbol for trees
# @a 1 the symbol for emptiness
# @a 2 the symbol for undetermined spaces
init_trees:
	addi	$sp,$sp,-36
	sw	$ra,0($sp)
	sw	$s0,4($sp)
	sw	$s1,8($sp)
	sw	$s2,12($sp)
	sw	$s3,16($sp)
	sw	$s4,20($sp)
	sw	$s5,24($sp)
	sw	$s6,28($sp)
	sw	$s7,32($sp)
	
	move	$s0,$a0 #tree symb
	move	$s1,$a1 #empty symb
	move	$s2,$a2 #unk symb
	move	$s3,$zero #row index
	move	$s4,$zero #column index
	la	$t8,treeit #pseudo--s-reg holding tree iterator
	initree:
		move	$a0,$s3 #row
		move	$a1,$s4 #col
		jal	get_coordinate
		lw	$ra,0($sp)
		bne	$v0,$s0,notatree #if we hit a tree:
			#convert from symbol to numeric notation:
			move	$a0,$s3 #row
			move	$a1,$s4 #col
			move	$a2,$zero #record no tent
			jal	set_coordinate
			lw	$ra,0($sp)
			
			#store this tent's coordinates in our iterator:
			sh	$s3,0($t8) #row
			sh	$s4,2($t8) #row
			addi	$t8,$t8,4 #next pair
			
			#loop through the adjacent spaces:
			move	$s5,$zero #now contains the tent rotation
			noteopenings: #do
				#increment the tree's counter:
				addi	$s5,$s5,1
				rem	$s5,$s5,5
				move	$a0,$s3 #row
				move	$a1,$s4 #col
				move	$a2,$s5 #rotation
				jal	set_coordinate
				lw	$ra,0($sp)
				beq	$s5,$zero,donepopping #finished yet?
				
				#find its current tent coordinates:
				move	$a0,$s3 #row
				move	$a1,$s4 #col
				jal	find_tent_by_tree
				lw	$ra,0($sp)
				move	$s6,$v0 #now contains tent row
				move	$s7,$v1 #now contains tent col
				
				#check whether location is valid and empty:
				slt	$t0,$s6,$zero #out-of-bounds?
				bne	$t0,$zero,noteopenings
				move	$a0,$s6 #tent row
				move	$a1,$s7 #tent col
				jal	get_coordinate
				lw	$ra,0($sp)
				bne	$v0,$s1,noteopenings #spot already taken?
				
				#check whether its row and column are clear:
				move	$a0,$zero #operate on rows
				move	$a1,$s6 #tent row
				jal	get_expected
				lw	$ra,0($sp)
				beq	$v0,$zero,noteopenings #row empty?
				li	$a0,1 #operate on cols
				move	$a1,$s7 #tent col
				jal	get_expected
				lw	$ra,0($sp)
				beq	$v0,$zero,noteopenings #col empty?
				
				#populate the location
				move	$a0,$s6 #tent row
				move	$a1,$s7 #tent col
				move	$a2,$s2 #open for use
				jal	set_coordinate
				lw	$ra,0($sp)
				j	noteopenings #check the rest of the adjacents
			donepopping:
		notatree:
		addi	$s4,$s4,1 #advance column
		la	$t0,len
		lw	$t0,0($t0) #now holds length
		bne	$s4,$t0,continuerow #if past the last column
			addi	$s3,$s3,1 #advance row
			move	$s4,$zero #reset column
		continuerow:
		bne	$s3,$t0,initree #while not past last row
	
	#close out tree iterator:
	li	$t0,-1
	sh	$t0,0($t8)
	sh	$t0,2($t8)
	
	lw	$s0,4($sp)
	lw	$s1,8($sp)
	lw	$s2,12($sp)
	lw	$s3,16($sp)
	lw	$s4,20($sp)
	lw	$s5,24($sp)
	lw	$s6,28($sp)
	lw	$s7,32($sp)
	addi	$sp,$sp,36
	jr	$ra

# Grabs the coordinates of the tree under the iterator.
# If we're just off the end, the coordinates will be (-1,-1).
# @a 0 the iterator's position (0-based)
# @v 0 the row-coordinate
# @v 1 the column-coordinate
iter_deref:
	addi	$sp,$sp,-8
	sw	$ra,0($sp)
	sw	$s0,4($sp)
	
	la	$s0,treeit
	mul	$a0,$a0,4 #move by coordinate *pairs*
	add	$s0,$s0,$a0 #address of requested pair
	lh	$v0,0($s0)
	lh	$v1,2($s0)
	
	lw	$s0,4($sp)
	addi	$sp,$sp,8
	jr	$ra
