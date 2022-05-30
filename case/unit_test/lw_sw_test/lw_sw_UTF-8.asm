.data  0x0000 
	buf:    .word  0xFFFFFC60,0xFFFFFC70,0x09E4F580
 	array:.space 200	# store element
    	info:.space 20	# store n	
.text	 0x0000
start:lw $v0,buf($zero)	  #read a num -> v0
	addi $t0,$zero,4	                            
  	sw $v0,buf($t0)	  # v0 -> output_unit address