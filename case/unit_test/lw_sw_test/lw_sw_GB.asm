.data  0x0000              		        
   buf:   .word  0xFFFFFC60, 0xFFFFFC70	
.text 0x0000					        
start:
	lw $v0,buf($zero)
	addi $t0,$zero,4
	sw $v0,buf($t0)
	j	 start