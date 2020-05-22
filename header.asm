
;* RLE Depacker by Konop, Magnus, Probe, Seban, Tebe (alphabetical order)


dest	= $b000		; destination address

  org $2000
START
 	mwa #dest outputPointer

 	lda >packed-1
 	ldx <packed-1

 	jsr rle_depacker

 	jmp $b208



rle_depacker

	sta inputPointer+1

loop    jsr getByte
	beq stop
	lsr @

	tay
lp0	jsr getByte
lp1	sta $ffff
outputPointer	equ *-2

	inw outputPointer

	dey
_bpl    bmi loop

	bcs lp0
	bcc lp1

getByte	inx
	sne
	inc inputPointer+1

	lda $ff00,x		; lo(inputPointer) = 0 !!!
inputPointer	equ *-2

stop    rts


packed	ins 'head.rle'	; compressed rle file
	
	INI START
	