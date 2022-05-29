.data 
	buf: .word  0xFFFFFC60,0xFFFFFC70,0x09E4F580
 	array:.space 200	# store element
    	info:.space 20	# store n
 
 	
.text	  0x0000

#notice: the input can not be more than 255 in these cases

start:
	lw $v0,buf($zero)	#read the no. of case
	
	ori $t0,$zero,0
	ori $t1,$zero,1
	ori $t2,$zero,2
	ori $t3,$zero,3
	ori $t4,$zero,4
	ori $t5,$zero,5
	ori $t6,$zero,6
	ori $t7,$zero,7		
				
	beq $v0,$t0,case_000
	beq $v0,$t1,case_001
	beq $v0,$t2,case_010
	beq $v0,$t3,case_011
	beq $v0,$t4,case_100
	beq $v0,$t5,case_101
	beq $v0,$t6,case_110
	beq $v0,$t7,case_111
	j start
	
case_000:
	lw $v0,buf($zero)	#read the n
	sw $v0,info($zero) 	#reserve n in the memory
	
	addi $t0, $zero,0  	# t0: offset
	lw $t1,info($zero) 	# t1 <- n
	
init_000:	beq $t1,$zero,finish_init_000

	lw $v0,buf($zero)	#read the n

	sw $v0,array($t0) 	# fill array[0-4]
	addi $t0, $t0, 4
	addi $t1, $t1,-1

	j init_000
	
finish_init_000:	
       	j start
       	
case_001:
	lw $t1,info($zero) 	# t1 <- n
	addi $t0, $zero,0  	# t0: address (a)
	sll $t2,$t1,2	# t2 <- offset = n * 4
	
init_001:	beq $t1,$zero,bubble_sort_001

	lw $v0,array($t0) 	#array[a] -> v0 -> array[a+4 * n]
	add $t0,$t0,$t2
	sw $v0,array($t0)
	sub $t0,$t0,$t2
		
	addi $t0, $t0, 4	
	addi $t1,$t1,-1
	j init_001
	
	
bubble_sort_001:
       	
       	lw $s0,info($zero) 	# s0 <- n
       	addi $s1,$zero,0	# s1 <- i init i = 0
       	sll $s3,$s0,2	# s3 <- 4n
       	addi $t8,$s0,-1	# t8 <- n-1
forout_001:
	beq  $s1,$t8,forout_end_001 # while  i < n - 1
	
	add $s2,$zero,$zero	      # init s2 <- j  <-0
	sub $t9,$t8,$s1             # t9 <- (n - i - 1)
forin_001:		
	beq $s2,$t9,forin_end_001 # when j < (n - i - 1)
	sll $s7,$s2,2	   # s7 <- 4j align address
	
	add $t3,$s3,$s7	# t3 <- 4n + 4j
	addi $t4,$t3,4	# t4 <- 4n + 4j + 4
	lw $s4,array($t3)
	lw $s5,array($t4)
	sltu $s6,$s4,$s5	#unsigned bubble sort
	bne $s6,$zero,miss_001	# s4 <= s5 , miss
	
swap_001:			# s4 >s5 ,  swap and sw	
	add $t3,$s3,$s7	# t3 <- 4n + 4j
	addi $t4,$t3,4	# t4 <- 4n + 4j + 4
	sw $s4,array($t4)	# a[j] -> a[base+4n]
	sw $s5,array($t3)	# a[j+1] -> a[base+4n+j]
miss_001:
	addi $s2,$s2,1
	j forin_001
forin_end_001:	
	addi $s1,$s1,1
	j forout_001
forout_end_001:
	j start


case_010:			# to 2's complement
	lw $t1,info($zero) 	# t1 <- n
	addi $t0, $zero,0  	# t0: 0
	sll $t2,$t1,3	# t2 <- offset = n * 8
	
init_010:	
	beq $t1,$zero,finish_init_010
	lw $v0,array($t0) 	#array[a] -> v0 -> array[a+ * n]
	add $t0,$t0,$t2
			# check vo + or - 
	srl $v1,$v0,7	# srl 7 bit to get MSB -> v1
	andi $v1,$v1,1	# 1: - or 0: +
	beq  $v1,$zero,isPositive

isNagative:	
	sll $v1,$v0,1	# <- 1 
	nor $v1,$v1,$zero	# ~
	srl $v1,$v1,1	# -> 1
	addi $v1,$v1,128	# get MSB 1 back
	addi $v0,$v1,1	# +1
	
isPositive:			# positive no operation
	sw $v0,array($t0)
	sub $t0,$t0,$t2
		
	addi $t0, $t0, 4	
	addi $t1,$t1,-1
	j init_010
	
finish_init_010:	
	j start


#we assume the numbers here are only 8-bits long
#move the nums from part3 to part4
case_011:
	lw $t1,info($zero) 	# t1 <- n
	sll $t0,$t1,3	# t0 <- 8n
	sll $t2,$t1,2	# t2 <- 4n
	add $t2,$t0,$t2	# t2 <- 8n + 4n = 12n
	
init_011:	beq $t1,$zero,finish_init_011

	lw $v0,array($t0) 	#array[8n+a] -> v0 -> array[12n+a]
	sw $v0,array($t2)
		
	addi $t0,$t0, 4
	addi $t2,$t2, 4	
	addi $t1,$t1,-1
	j init_011
	
finish_init_011:
	
#bubble_sort_011:
       	
       	lw $s0,info($zero) 	# s0 <- n

       	sll $s3,$s0,2	# s3 <- 4n
       	sll $s1,$s0,3	# temp = s1 <- 8n	
       	add $s3,$s3,$s1	# s3 <- 4n + 8n = 12n
       	
       	addi $s1,$zero,0	# s1 <- i init i = 0
       	addi $t8,$s0,-1	# t8 <- n-1
forout_011:
	beq  $s1,$t8,forout_end_011 # while  i < n - 1
	
	add $s2,$zero,$zero	      # init s2 <- j  <-0
	sub $t9,$t8,$s1             # t9 <- (n - i - 1)
forin_011:		
	beq $s2,$t9,forin_end_011 # when j < (n - i - 1)
	sll $s7,$s2,2	   # s7 <- 4j align address
	
	add $t3,$s3,$s7	# t3 <- 12n + 4j
	addi $t4,$t3,4	# t4 <- 12n + 4j + 4
	lw $s4,array($t3)
	lw $s5,array($t4)
	
			
	sll $s4,$s4,24	#sll 24 bit to compare
	sll $s5,$s5,24
	
	slt $s6,$s4,$s5	#8 bit signed integer
	
	srl $s4,$s4,24	
	srl $s5,$s5,24	#shift back
	
	bne $s6,$zero,miss_011	# s4 <= s5 , miss
	
swap_011:			# s4 >s5 ,  swap and sw	
	add $t3,$s3,$s7	# t3 <- 12 + 4j
	addi $t4,$t3,4	# t4 <- 12 + 4j + 4
	sw $s4,array($t4)	# a[j] -> a[base+12n]
	sw $s5,array($t3)	# a[j+1] -> a[base+12n+j]
miss_011:
	addi $s2,$s2,1
	j forin_011
forin_end_011:	
	addi $s1,$s1,1
	j forout_011
forout_end_011:
	j start
	
		
case_100:
	lw $s0,info($zero) 	# s0 <- n
       	sll $s1,$s0,2	# s1 <- 4n	    (min)
       	sll $s2,$s0,3	# s2 <- 8n
       	addi $s2,$s2,-4	# s2 <- 8n - 4 (max)
       
       	lw $s2,array($s2)	# s2 <- max
       	lw $s1,array($s1)	# s1 <- min
       	
       	subu $s3,$s2,$s1	# s3 = s2 - s1
       	
   
       	
       	addi $t0,$zero,4	                            
  	sw $s3,buf($t0)	    # write -> s3
       	
	j start
	
case_101:	
       
	lw $s0,info($zero) 	# s0 <- n
       	sll $s1,$s0,4	# s1 <- 16n	   
       	sll $s2,$s0,3	# s2 <- 8n
       	sll $s3,$s0,2	# s3 <- 4n
       	add $s3,$s3,$s2	# s3 <- 12n	     (min)
       	addi $s1,$s1,-4	# s1 <- 16n - 4 (max) 
       	lw $s3,array($s3)	# s3 <- min
       	lw $s1,array($s1)	# s1 <- max
      
       	subu $s4,$s1,$s3	# s4 = s1 - s3
       	
	addi $t0,$zero,4	                            
  	sw $s4,buf($t0)	    # write -> s4

	j start

# here we return the 32 bit num, but we only have to show low 8-bit num on the board

case_110:	

	lw $v0,buf($zero)	#read the no. of the datasets -> v0
	addi $s0,$v0,0	# s0 = dataset no. 1 OR 2 OR 3

	lw $s2,info($zero) 	# s2 <- n
	addi $s4,$zero,0	# s4 <- 0
	
	lw $v0,buf($zero)	#read the index -> v0
	
	addi $s1,$v0,0	# s1 = index
	
	sll $s3,$s2,2	# s3 <- 4n
	
			# s0 = no
	beq $s0,$zero,finish_mul_110	
	add $s4,$s4,$s3	# s4 += 4n until s0 = 0
	addi $s0,$s0,-1	# s0 = s0 - 1
	
finish_mul_110:		# s4 <- s0 * 4n
	sll $s1,$s1,2	# s1 <- 4 * s1
	add $s1,$s4,$s1	# s0 * 4n + 4 * s1 (address)=s1 <- s4 + s1
	lw $s1,array($s1)	# s1 = a[address]
	

	addi $t0,$zero,4	                            
  	sw $s1,buf($t0)	    # write -> s1
  	
	j start
	
### define the 32 bits num 
#  0/1(1-bit)_index(15-bit)_0000_0000_8bit(result)
#  0 means  dataset 0 !
#  1 means  dataset 2 !
case_111:	
	
	lw $v0,buf($zero)	#read the index -> v0
	
	lw $s0,info($zero) 	# s0 <- n
	addi $s1,$v0,0	# s1 = index
	
	sll $s2,$s1,2	# s2 <-  4 * s1 
	addi $s3,$s2,0	# s3 = 0 + 4 * s1
	sll $s4,$s0,3	# s4 <- 8n
	add $s4,$s4,$s2	# s4 <- 8n + 4 * s1
	
	lw $s3,array($s3)	# s3 <- num in data set 0
	lw $s4,array($s4)	# s4 <- num in data set 2
	
	# unify num s3 -> s5 (0) and num s4 -> s6 (2)
 	
 	add $s5,$zero,$s1
 	add $s6,$zero,$s1
 	sll $s5,$s5,16
 	add $s5,$s5,$s3
 	sll $s6,$s6,16
 	add $s6,$s6,$s4
 	
 	addi $s7,$zero,1
 	sll $s7,$s7,31	
 	or $s6,$s6,$s7
 	
	
	addi $t0,$zero,4	                            
  	sw $s5,buf($t0)	    # write -> s5
	

       	
       	
       	#############################
	# 5 seconds time seperation #
	
	
	addi $t0,$zero,8
	#sll $t0,$t0,28		#need to spercify on board
	#addi $t0,$t0,-250000000		#need to spercify on board
	lw $t0,buf($t0)	    # write -> s5
counting_start:
	beq $t0,$zero,counting_over
	addi $t0,$t0,-1
	j counting_start
	#############################
	
	
counting_over:
		
	addi $t0,$zero,4	                            
  	sw $s6,buf($t0)	    # write -> s6
