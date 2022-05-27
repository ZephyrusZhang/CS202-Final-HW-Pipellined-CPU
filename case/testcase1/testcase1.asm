
.data
	buf:   .word  0xFFFFFC60, 0xFFFFFC70 #input and output address in main

	# FFFFFC60 input
	# FFFFFC70 output
.text	
	
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

	beq $v0,$t0,case1_000
	beq $v0,$t1,case1_001
	beq $v0,$t2,case1_010
	beq $v0,$t3,case1_011
	beq $v0,$t4,case1_100
	beq $v0,$t5,case1_101
	beq $v0,$t6,case1_110
	beq $v0,$t7,case1_111
	j start
	
case1_000:
	lw $v0,buf($zero)	#read the no. of case
	
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
	addi $a0,$zero,1          # is palindrome
	j case1_000_label2
	
  case1_000_exit2:
	addi $a0,$zero,0          # is not palindrome
	
  case1_000_label2:
  		  
  	addi $t0,$zero,4	                            
  	sw $a0,buf($t0)	    # write -> a0  0 or 1  not or is

  	j start
case1_001:
  			     
	lw $v0,buf($zero)		#read integer -> v0 
	
  	addi $s1,$v0,0            	#input a -> s1
			  
  	addi $t0,$zero,4	                            
  	sw $s1,buf($t0)	    	# write result s1

	
 	lw $v0,buf($zero)		#read integer b -> v0 	  
  	 
	
  	addi $s2,$v0,0            	#input b -> s2
  	
  	addi $t0,$zero,4	                            
  	sw $s2,buf($t0)	    	# write result s2
	
	j start
case1_010:
	and $s3,$s1,$s2		# result -> s3
	
	addi $t0,$zero,4	                            
  	sw $s3,buf($t0)	    	# write result s3	   
  	
	j start
case1_011: 	
	or $s3,$s1,$s2		# result -> s3
	
	addi $t0,$zero,4	                            
  	sw $s3,buf($t0)	    	# write result s3	  	   
  	
  	j start
case1_100:   	
  	xor $s3,$s1,$s2		# result -> s3
	
	addi $t0,$zero,4	                            
  	sw $s3,buf($t0)	    	# write result s3	 

	j start
  	
case1_101:   	
  	sllv $s3,$s1,$s2		# result -> s3
	
	addi $t0,$zero,4	                            
  	sw $s3,buf($t0)	    	# write result s3
  	
  	j start
  	
case1_110:   	
  	srlv $s3,$s1,$s2		# result -> s3
	
	addi $t0,$zero,4	                            
  	sw $s3,buf($t0)	    	# write result s3
  	
  	j start
case1_111:   	
  	srav $s3,$s1,$s2		# result -> s3
	
	addi $t0,$zero,4	                            
  	sw $s3,buf($t0)	    	# write result s3
		  	
	j start
	
