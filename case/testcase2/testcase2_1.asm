
.data  
 	array:.space 200	# store element
 	info:.space 20	# store n


	
.text

#因为输入的数是8-bit的无符号数 输入时不能超过255

start:
	addi $v0,$zero,5	#从I/O读取case的编号
	syscall 		
	beq $v0,0,case_000
	beq $v0,1,case_001
	beq $v0,2,case_010
	j start
	
case_000:
	addi $v0,$zero,5	#从I/O读取n
	syscall 
	sw $v0,info($zero) 	#将n存到地址当中
	
	addi $t0, $zero,0  	# t0: offset
	lw $t1,info($zero) 	# t1 <- n
	
init_000:	beq $t1,$zero,finish_init_000

	addi $v0,$zero,5	# 从I/O读取数据n个输入
	syscall 

	sw $v0,array($t0) 	# fill array[0-4]
	addi $t0, $t0, 4
	addi,$t1,$t1,-1
	j init_000
	
finish_init_000:	
       	j start
       	
case_001:
	lw $t1,info($zero) 	# t1 <- n
	addi $t0, $zero,0  	# t0: address (a)
	sll $t2,$t1,2	# t2 <- offset = n * 4
	
init_001:	beq $t1,$zero,finish_init_001

	lw $v0,array($t0) 	#array[a] -> v0 -> array[a+4 * n]
	add $t0,$t0,$t2
	sw $v0,array($t0)
	sub $t0,$t0,$t2
		
	addi $t0, $t0, 4	
	addi,$t1,$t1,-1
	j init_001
	
finish_init_001:
	
	
bubble_sort_001:
	# unsigned bubble sort
	#for (i=0; i<n-1; ++i)  
           #for (j=0; j<n-1-i; ++j) 
       	#if(a[j] > a[j + 1]) swap(a[j], a[j + 1]);
       	
       	lw $s0,info($zero) 	# s0 <- n
       	addi,$s1,$zero,0	# s1 <- i init i = 0
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
	addi $t0, $zero,0  	# t0: address (a)
	sll $t2,$t1,3	# t2 <- offset = n * 8
	
init_010:	
	beq $t1,$zero,finish_init_010
	lw $v0,array($t0) 	#array[a] -> v0 -> array[a+4 * n]
	add $t0,$t0,$t2
			# check vo + or - 
	srl $v1,$v0,7	# srl 7 bit to get MSB -> v1
	andi $v1,$v1,1	# 1: - or 0: +
	beq  $v1,$zero,isPositive
	
	sll $v1,$v0,1	# <- 1 
	nor $v1,$v1,$zero	# ~
	srl $v1,$v1,1	# -> 1
	addi $v1,$v1,128	# get MSB 1 back
	addi $v0,$v1,1	# +1
	
isPositive:			# positive no operation
	sw $v0,array($t0)
	sub $t0,$t0,$t2
		
	addi $t0, $t0, 4	
	addi,$t1,$t1,-1
	j init_001
	
finish_init_010:	
	j start
