.data 0x0000				      		
	buf: .word 0x0000
.text 0x0000						
start: lui   $1,0xFFFF			
        ori   $28,$1,0xF000		
switled:								
	lw   $1,0xC60($28)
	sw   $1,0xC70($28)
	j switled