.data 0x00      		        
   buf:   .word  0xFFFFFC60, 0xFFFFFC70	
.text 0x00					        
start:
	lw 		$v0, buf($zero)
	lw 		$t1, 0($v0)
	addi 	$t0, $zero,4
	sw 		$v0, buf($t0)
	sw		$t1, 0($v0)
	j	 	start
