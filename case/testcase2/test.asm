.data
.text

main: lui   $1,0xFFFF
          ori   $28,$1,0xF000
switled:
	 lw   $1,0xC60($28)
	 sw   $1,0xC70($28)
	 j switled