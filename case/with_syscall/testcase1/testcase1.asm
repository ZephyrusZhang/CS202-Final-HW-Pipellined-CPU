
.data
	newline:.asciiz "\n"
	buf:   .word  0x00000055, 0x000000A #input and output address in main

	
.text	

start:
	addi $v0,$zero,5	#read the no. of case
	syscall 		
	beq $v0,0,case1_000
	beq $v0,1,case1_001
	beq $v0,2,case1_010
	beq $v0,3,case1_011
	beq $v0,4,case1_100
	beq $v0,5,case1_101
	beq $v0,6,case1_110
	beq $v0,7,case1_111
	j start
	
case1_000:
	addi $v0,$zero,5		#read integer  
	syscall
	
	add $s0,$zero,$v0
	add $t0,$zero,$v0 
	addi $t1,$zero,0		
	addi $t2,$zero,0
	addi $s1,$t0,0		#get x2  ($s1)
	
  case1_000_cycle1:			
	beq $t0,$zero,case1_000_exit1	#get x2r ($s2)
	andi $t2,$t0,1
	add $t1,$t1,$t2
	srl $t0,$t0,1
	sll $t1,$t1,1
	j case1_000_cycle1
	
  case1_000_exit1: 
	srl $t1,$t1,1
	addi $s2,$t1,0
	addi $t0,$s0,0    #initialize registers
	addi $t1,$zero,0
	addi $t2,$zero,0

  case1_000_label1:
	bne $s1,$s2,case1_000_exit2
	addi $a0,$zero,1          #是回文
	j case1_000_label2
	
  case1_000_exit2:
	addi $a0,$zero,0          #不是回文
	
  case1_000_label2:
  		               #打印是否是回文 待修改
  	addi $v0,$zero,1	    #原值存储在s1	
  	syscall		    #是否是回文存储再a0
  			
  	la $a0, newline   	    #newline  待修改
	li $v0,4
	syscall

  	j start
case1_001:
  	addi $v0,$zero,5		#read integer  待修改      
	syscall
	
  	addi $s1,$v0,0            	#input a 存储在s1
  	
  	addi $a0,$s1,0	    	#打印计算结果   待修改
	li $v0,35
  	syscall		
  	la $a0, newline   	    #newline  待修改
	li $v0,4
	syscall
	
  	addi $v0,$zero,5		#read integer  待修改    
  	  
	syscall
	
  	addi $s2,$v0,0            	#input b 存储在s2
  	
  	addi $a0,$s2,0	    	#打印计算结果   待修改
	li $v0,35
  	syscall	
  	la $a0, newline   	    #newline  待修改
	li $v0,4
	syscall	
	
	j start
case1_010:
	and $s3,$s1,$s2		#s3存储计算结果
	
	addi $a0,$s3,0	    	#打印计算结果  待修改
	li $v0,35
  	syscall		   
  	
  	la $a0, newline  		#newline   待修改
	li $v0,4
	syscall

	j start
case1_011: 	
	or $s3,$s1,$s2		#s3存储计算结果
	
	addi $a0,$s3,0	    	#打印计算结果  待修改
	li $v0,35
  	syscall		   
  	
  	la $a0, newline   		#newline   待修改
	li $v0,4
	syscall
  	
  	j start
case1_100:   	
  	xor $s3,$s1,$s2		#s3存储计算结果
	
	addi $a0,$s3,0	    	#打印计算结果   待修改
	li $v0,35
  	syscall		   
  	
  	la $a0, newline   		#newline    待修改
	li $v0,4
	syscall

	j start
  	
case1_101:   	
  	sllv $s3,$s1,$s2			#s3存储计算结果
	
	addi $a0,$s3,0	    	#打印计算结果   待修改
	li $v0,35
  	syscall		   	
  	  	  	
  	la $a0, newline   		#newline    待修改
	li $v0,4
	syscall
	
  	j start
  	
case1_110:   	
  	srlv $s3,$s1,$s2			#s3存储计算结果
	
	addi $a0,$s3,0	    	#打印计算结果   待修改
	li $v0,35
  	syscall		   	
  	  	  	
  	la $a0, newline   		#newline    待修改
	li $v0,4
	syscall  	
  	
  	j start
case1_111:   	
  	srav $s3,$s1,$s2		#s3存储计算结果
	
	addi $a0,$s3,0	    	#打印计算结果   待修改
	li $v0,35
  	syscall		   	
  	  	  	
  	la $a0, newline   		#newline    待修改
	li $v0,4
	syscall  	  	
	j start
	
