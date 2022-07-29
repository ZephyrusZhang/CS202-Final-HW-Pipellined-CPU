.data 0x00
	buf  : .word 0xFFFFFC60, 0xFFFFFC70, 0x09EF2EAA
	info : .word 0x00000000			# store n
 	array: .word 0x00000000			# store elements
	
.text 0x0000

# the input cannot exceed 255 in these cases, assuming that the input are only 8-bits long
start:
	addi $a1, $zero, 4
	lw $a0, buf($zero)				# a0: address for input (0xFFFFFC60)
	lw $a1, buf($a1)				# a1: address for print (0xFFFFFC70)

	lw $v0, 0($a0)					# v0: case index from input
	
	ori $t0, $zero, 0
	ori $t1, $zero, 1
	ori $t2, $zero, 2
	ori $t3, $zero, 3
	ori $t4, $zero, 4
	ori $t5, $zero, 5
	ori $t6, $zero, 6
	ori $t7, $zero, 7		
				
	beq $v0, $t0, case_000
	beq $v0, $t1, case_001
	beq $v0, $t2, case_010
	beq $v0, $t3, case_011
	beq $v0, $t4, case_100
	beq $v0, $t5, case_101
	beq $v0, $t6, case_110
	beq $v0, $t7, case_111
	j start

### case 0
case_000:
	lw $v0, 0($a0)					# read n from input
	sw $v0, info($zero) 	 		# save n into memory
	lw $t1, info($zero) 	  		# t1: n
	sw $t1, 0($a1)					# print t1
	addi $t0, $zero, 0  	  		# t0: i = 0 (address)

init_000:
	beq $t1, $zero, finish_init_000
	lw $v0, 0($a0)					# read x from input
	sw $v0, array($t0) 	  			# array[i] = x
	sw $v0, 0($a1)					# print x
	addi $t0, $t0, 4				# i = i + 4 (shift array address)
	addi $t1, $t1, -1				# n = n - 1
	j init_000

finish_init_000:
	j start

### case 1
case_001:
	lw $t1, info($zero)				# t1: n
	addi $t0, $zero, 0				# t0: i = 0 (address)
	sll $t2, $t1, 2					# t2: 4n (offset for 2nd array)
	
init_001:	
	beq $t1, $zero, bubble_sort_001	# while (0 < n)

	lw $v0, array($t0)
	add $t0, $t0, $t2
	sw $v0, array($t0)				# array[4n + i] = array[i]
	sub $t0, $t0, $t2
		
	addi $t0, $t0, 4				# i = i + 4
	addi $t1, $t1, -1				# n = n - 1
	j init_001
	
bubble_sort_001:
    lw $s0, info($zero)				# s0: n
    addi $s1, $zero, 0				# s1: i = 0 (address)
    sll $s3, $s0, 2					# s3: 4n (offset for 2nd array)
    addi $t8, $s0, -1				# t8: n - 1

forout_001:
	beq $s1, $t8, forout_end_001   	# while (i < n - 1)
	
	addi $s2, $zero, 0				# s2: j = 0
	sub $t9, $t8, $s1				# t9: (n - 1) - i

forin_001:		
	beq $s2, $t9, forin_end_001	  	# while (j < (n - 1 - i))
	sll $s7, $s2, 2	   		  		# s7: 4j (align address)
	
	add $t3, $s3, $s7			  	# t3: 4n + 4j
	addi $t4, $t3, 4			  	# t4: (4n + 4j) + 4
	lw $s4, array($t3)				# s4: array[4n + 4j]
	lw $s5, array($t4)				# s5: array[4n + 4j + 4] (the next number)

	sltu $s6, $s4, $s5		     	# compared unsigned
	bne $s6, $zero, miss_001	  	# if s4 <= s5, nothing happens

swap_001:					  		# if s4 >  s5, swap the two consequtive numbers
	add $t3, $s3, $s7			  	# t3: 4n + 4j
	addi $t4, $t3, 4			  	# t4: (4n + 4j) + 4
	sw $s4, array($t4)		  		# array[4n + 4j + 4] = array[4n + 4j]
	sw $s5, array($t3)		  		# array[4n + 4j] = array[4n + 4j + 4]

miss_001:
	addi $s2, $s2, 1				# j = j + 1
	j forin_001

forin_end_001:	
	addi $s1, $s1, 1				# i = i + 1
	j forout_001

forout_end_001:						# completed bubble sort
	j start

### case 2
case_010:							# translate into 2's complement according to the 7th bit
	lw $t1, info($zero) 			# t1: n
	addi $t0, $zero, 0  			# t0: i = 0 (address)
	sll $t2, $t1, 3					# t2: 8n (offset for 3rd array)
	
init_010:
	beq $t1, $zero, finish_init_010 # while (0 < n)
	lw $v0, array($t0) 				# v0: x = array[i]

	srl $v1, $v0, 7					# v1: most significant bit (MSB) of array[i]
	andi $v1, $v1, 1
	beq $v1, $zero, isPositive		# (MSB == 1) ? negative : positive

isNagative:	
	sll $v1, $v0, 1					# v1: y = x << 1
	nor $v1, $v1, $zero				# y = ~y
	srl $v1, $v1, 1					# y = y >> 1
	addi $v1, $v1, 128				# recover MSB for y
	addi $v0, $v1, 1				# x = y + 1
	
isPositive:
	add $t0, $t0, $t2
	sw $v0, array($t0)				# array[8n + i] = x
	sub $t0, $t0, $t2
		
	addi $t0, $t0, 4				# i = i + 4
	addi $t1, $t1, -1				# n = n - 1
	j init_010
	
finish_init_010:
	j start

### case 3
case_011:
	lw $t1, info($zero) 			# t1: n
	sll $t0, $t1, 3					# t0: i = 8n (address for 3rd array)
	sll $t2, $t1, 2					# t2: 4n (offset for 4th array)
	add $t2, $t0, $t2				# t2: 4n + i
	
init_011:	
	beq $t1, $zero, finish_init_011	# while (0 < n)

	lw $v0, array($t0)
	sw $v0, array($t2)				# array[4n + i] = array[i]
		
	addi $t0, $t0, 4				# i = i + 4
	addi $t2, $t2, 4
	addi $t1, $t1, -1				# n = n - 1
	j init_011
	
finish_init_011:       	
    lw $s0, info($zero) 			# s0: n

    sll $s3, $s0, 2					# s3: 4n
    sll $s1, $s0, 3					# s1: 8n	
    add $s3, $s3, $s1				# s3: 4n + 8n = 12n
       	
    addi $s1, $zero, 0				# s1: i = 0
    addi $t8, $s0, -1				# t8: n - 1
forout_011:
	beq  $s1, $t8, forout_end_011	# while (i < n - 1)
	
	add $s2, $zero, $zero	      	# s2: j = 0
	sub $t9, $t8, $s1            	# t9: (n - 1) - i
forin_011:		
	beq $s2, $t9, forin_end_011  	# while (j < (n - i - 1))
	sll $s7, $s2, 2	   				# s7: 4j (align address)
	
	add $t3, $s3, $s7				# t3: 12n + 4j
	addi $t4, $t3, 4				# t4: 12n + 4j + 4
	lw $s4, array($t3)				# s4: array[12n + 4j]
	lw $s5, array($t4)				# s5: array[12n + 4j + 4] (the next number)
	
			
	sll $s4, $s4, 24				# shift 24bits left to compare
	sll $s5, $s5, 24
	
	slt $s6, $s4, $s5				# compare 8 bit signed integer
	
	srl $s4, $s4, 24				# shift back	
	srl $s5, $s5, 24
	
	bne $s6, $zero, miss_011		# if s4 <= s5, nothing happens
	
swap_011:							# if s4 >  s5, swap the two consequtive numbers
	add $t3, $s3, $s7				# t3: 12n + 4j
	addi $t4, $t3, 4				# t4: 12n + 4j + 4
	sw $s4, array($t4)				# array[12n + 4j + 4] = array[12n + 4j]
	sw $s5, array($t3)				# array[12n + 4j] = array[12n + 4j + 4]

miss_011:
	addi $s2, $s2, 1				# j = j + 1
	j forin_011

forin_end_011:	
	addi $s1, $s1, 1				# i = i + 1
	j forout_011

forout_end_011:
	j start

### case 4
case_100:
	lw $s0, info($zero) 			# s0: n
    sll $s1, $s0, 2					# s1: 4n     (min address)
    sll $s2, $s0, 3					# s2: 8n
    addi $s2, $s2, -4				# s2: 8n - 4 (max address)
       
    lw $s2, array($s2)				# s2: max
    lw $s1, array($s1)				# s1: min
       	
    subu $s3, $s2, $s1				# s3 = s2 - s1
       	  	
  	sw $s3, 0($a1) 					# print difference
	j start
	
### case 5
case_101:	
	lw $s0, info($zero) 			# s0: n
    sll $s1, $s0, 4					# s1: 16n	   
    sll $s2, $s0, 3					# s2: 8n
    sll $s3, $s0, 2					# s3: 4n
    add $s3, $s3, $s2				# s3: 12n     (min)
    addi $s1, $s1, -4				# s1: 16n - 4 (max) 
    lw $s3, array($s3)				# s3: min
    lw $s1, array($s1)				# s1: max
      
    subu $s4, $s1, $s3				# s4 = s1 - s3
       	
  	sw $s4, 0($a1)					# print difference	
	j start

### case 6
case_110:
	lw $v0, 0($a0)					# read the dataset index k from input

	addi $s0, $v0, 0				# s0: k (1 or 2 or 3)

	lw $s2, info($zero) 			# s2: n
	addi $s4, $zero, 0				# s4: 0
				
	lw $v0, 0($a0)					# read the element index i from input
	
	addi $s1, $v0, 0				# s1: i
	
	sll $s3, $s2, 2					# s3: 4n
	
	beq $s0, $zero, finish_mul_110	# while (0 < k)
	add $s4, $s4, $s3				# s4 += 4n
	addi $s0, $s0, -1				# k = k - 1
	
finish_mul_110:						# s4: k * 4n
	sll $s1, $s1, 2					# s1: 4i
	add $s1, $s4, $s1				# s1 = k * 4n + 4i (address)
	lw $s1, array($s1)				# s1 = array[address]
	
	sw $s1, 0($a1)					# print array[address]
	j start

### case 7
#	32bits output format:    1bit  | 15bit |    8bit   |  8bit  
#							0 or 1 | index | 0000_0000 | result 
#		?) 0 for dataset 0
#		   1 for dataset 2
case_111:
	lw $v0, 0($a0)					# read the element index i from input
	
	lw $s0, info($zero)				# s0: n
	addi $s1, $v0, 0				# s1: i
	
	sll $s2, $s1, 2					# s2: 4i
	addi $s3, $s2, 0				# s3: 4i
	sll $s4, $s0, 3					# s4: 8n
	add $s4, $s4, $s2				# s4: 8n + 4i
	
	lw $s3, array($s3)				# s3: a = ith element in dataset 0
	lw $s4, array($s4)				# s4: c = ith element in dataset 2
	
	# unify num s3 -> s5 (0) and num s4 -> s6 (2)
	# splicing the info together
 	
 	add $s5, $zero, $s1				# s5: i
 	add $s6, $zero, $s1				# s6: i
 	sll $s5, $s5, 16
 	add $s5, $s5, $s3				# s5: a + (i << 16)
 	sll $s6, $s6, 16
 	add $s6, $s6, $s4				# s6: c + (i << 16)
 	
 	addi $s7, $zero, 1				# s7: 1 representing dataset 2
 	sll $s7, $s7, 31
 	or $s6, $s6, $s7				# s6: (c + (i << 16)) | (1 << 31)
 		
	sw $s5, 0($a1)					# print	a + (i << 16)
    #############################
	# 5 seconds of delay
	addi $t0, $zero, 8				# t0: 8
	lw $t0, buf($t0)	    		# t0: i = 0x09EF2EAA

counting_start:
	beq $t0, $zero, counting_over	# while (0 < i)
	addi $t0, $t0, -1				# i = i - 1
	j counting_start
	#############################

counting_over:
	sw $s6, 0($a1)					# print (c + (i << 16)) | (1 << 31)
	j start