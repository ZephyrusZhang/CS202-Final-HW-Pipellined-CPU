.data  0x0000              		        
   buf:   .word  0xFFFFFC60, 0xFFFFFC70	
.text 0x0000					        
start:
	lw 		$v0, buf($zero)
	lw  	$t1, 0($v0)
	addi 	$t0, $zero, 4

    xor     $t2, $t1, $zero
    
	lw 		$v0, buf($t0)
	sw		$t2, 0($v0)
	j	 	start
