.data  0x00
	buf: .word  0xFFFFFC60,0xFFFFFC70,0x09EF2EAA
	info:.word  0x00000000     	 # store n
 	array:.word 0x00000000	 # store element

 

start:
	
	ori $t1,$zero,1
	ori $t2,$zero,2
	ori $t3,$zero,3
	ori $t4,$zero,4

	
	addi $v0,$zero,0 
	lw $t1,array($v0)
	addi $v0,$zero,4 
	lw $t2,array($v0)
	addi $v0,$zero,4 
	lw $t3,array($v0)
	addi $v0,$zero,4 
	lw $t4,array($v0)
	
	
	
	lw $t1,buf($zero)

	addi $t0,$zero,4	    # write -> s5	
  	lw $v0, buf($t0)
	sw $t1, 0($v0)


	j start
	
	



