.data  0x0000              		        
   	buf:   .word  0xFFFFFC70
	array: .word  0x00000000
.text 0x0000					        
start:
	addi	$t0, $zero, 0
	addi	$t1, $zero, 4
	addi	$t2, $zero, 8
	addi	$t3, $zero, 12
	sw 	$t3, array($t0)
	sw 	$t2, array($t1)
	sw 	$t1, array($t2)
	sw 	$t0, array($t3)
	
	lw	$t4, array($t0)
	lw 	$v0, buf($zero)
	lw  	$t4, 0($v0)
	j	start
