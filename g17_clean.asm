    ;16 384
		opt r+
    icl '../lib/atari.hea'
    icl '../lib/system.hea'
   .zpvar counter .word = $80+20  ; save beginning for RMT
   .zpvar tempSrc, tempDest .word
   .zpvar temp .word
   .zpvar swirlCount, totalCount, NO_SIGNAL_HSCR, VBLBeat .byte
   .zpvar DLA, DLIX, DLIY .byte ;do not do this, evar!
   .zpvar scrollAddr .word
   
/* intro plan

1. present graphics
   + I have GFX 9+10 now
   + do a converter (python?)
   + view static screen
     + in gr9
     + in gr10
     + in mixed mode
     + in pirxompression
   - view animation
     + all together
     + by head
     + swirl effect
       starts and ends always on phase 0
     +DONE!!! (size calcs:
         one screen = 160 * 40 = 6400 bytes = $1900
         full animation = 78 lines = 3120*15 = 46800 :(
         afterpirxomression : 17 kb!!!!
         "by head" will cut the size)
     + animate it!
        + MSX synchro
        + effects sequential presentation
   
   
   - if some time left - improve graphix
      + fix gfx to remove vertical support on bars - picture will be clearer
      - flower in hand of Sikor
      - new colour scheme from Atari800 palette
      
2. add music
   + hack the player (sources from Miker!)
   + paste to the maIN code
3. facebook joke (tagged on this photo, like, like, like)
   basically no scroller, just sth like facebook comments flood
   + facebook alike logo on top
   - appearing of the above logo
4. additional FX
   + vertical blinds on sprites covering jagged borders
     + trial-and-error method of finding right GTIACTL values employed
   - beer fountain
   + no signal input joke
==================================
demo screenplay
+ during loading the "no signal input" screen pops-up
+ when demo is loaded, music starts to play and no signal input fades
    + exactly it bounces (msx synch) and 
    + goes to the right (out of the screen)
--  (this proved to be too difficult) 
    screen (PHOTO) with horizontal bars only appears 
    (this is char 0 for first 10 lines)
    bottom of the screen is invisible
-- heads appear (blinking over bars) 
+ heads start to move right and left accordingly to the music
-- bottom appears
+ "Added July 27, 2009" appears
+ facebolek logo appears (how?)
  it is hidden within the background colour
  appears by blink (to $00, then to final colours)
+ "Like * Comment" appears
+ "N" people like this appears
+ "In this photo"

+- comments appear 

==================================
*/

    .macro gpause
    	IFT :0>0
				lda :1
				jsr pauseMany
			EIF
			jsr pause1
		.endm
GTIACTLBITS = %010110
;%10100 - blinds OK, 
bottom_background_colour = $0E

;************************************
;********NO SIGNAL SCREEN************
;************************************
    opt o- h-
PMG = $B800 ; just before the ROM
		org $b000
NO_SIGNAL_fnt
    :8 .by 0 ;space char
    ins '/gfx/NO_SIGNAL2.fnt'


/* not necessary as map is just a sequence
NO_SIGNAL_MAP
    ;NO SIGNAL INPUT character map, 16 x 4
    ins '/gfx/NO_SIGNAL_MAP2.bin'+1
*/
INIaddr
   
    ; "NO SIGNAL" print
    ldy #4
NO_SIGNAL_outer
    ldx #0
NO_SIGNAL_inner
NS_MOD_VAL
    lda #1   
NS_MOD_DEST
    sta NO_SIGNAL+16,x
    inc NS_MOD_VAL+1 
    inx
    cpx #16
    bne NO_SIGNAL_inner
    adw NS_MOD_DEST+1 #48 ; dirty self-mod
    dey
    bne NO_SIGNAL_outer


    mva #>NO_SIGNAL_fnt CHBAS
    mva #$7F COLPF1s  ;gr.8 letters
    mva #$77 COLPF2s  ;gr.8 background
    sta COLBAKS
    mwa #dl_NOSIGNAL $0230
    sty HSCROL
    
    rts
dl_NOSIGNAL
    .byte $70,$70,$70
    dta $01 ; jump
dl_nosignal_jump
    dta a (dl_nosignal_space_begin)
    ;org *+10*8
		:10*8 dta $0
dl_nosignal_space_begin
    ;org *+12*8
		:12*8 dta $0
dl_nosignal_space_end
    dta $42+$10 ;HSCROLL
dl_nosignal_pict    
    dta a(NO_SIGNAL)
    :3 dta $02+$10 ;HSCROLL
    dta $41
    dta a(dl_NOSIGNAL)
NO_SIGNAL_HEADER
    ;org *+42
    :42 .by 0
NO_SIGNAL
		:$200 .by 0
;************************************
;************************************
    
    opt o+ h+
		org $2600
RUNaddr
    jmp jumpo
;------------------------------
dl
    dta $00+$80
    dta $4f
    dta a (facebolek)
    :17 .by $0f
    dta $80
 
    .REPT 10, #
    dta $42
scradr0:1
    dta a (screen0:1)

    .ENDR
    dta $42
    dta a (screen_bottom)
    :9 .by $02
    dta $00

    dta $1
dl_skip1
    dta a(dl_end)

dl_line1
    dta $42 ;added July 27, 2009 * Like * Comment
    dta a (textScreen)
    dta $00

    dta $1
dl_skip2
    dta a(dl_end)

dl_line2
    dta $42
    dta a (textScreen+40)
    .by 2

    .byte $70
    dta $42
dl_bottom_text_addr
    dta a (messageScreen)
    .by $00,$02

dl_end
    dta $41
    dta a (dl)
;------------------------------
dli
    sta DLA; pha
    stx DLIX; phx
    sty DLiY ; phy
dli_facebook_switch
    SEC
    bcc dli_skip_facebook
dli_facebook_colour    
    lda #$94
    sta WSYNC
    sta COLBAK
    lda #$18 ;CLI
    sta dli_facebook_switch
    jmp dli_exit
        
dli_skip_facebook    
    ldy #$0
    mva #$ea COLPF1
    mva #$bc COLPF2
    mva #bottom_background_colour COLPF3
    lda #$80+GTIACTLBITS
    sta WSYNC
    sta GTIACTL   
    ldx #9
dli_upper_loop
        lda fontTable,x
        sta CHBASE
     
        lda #$80+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
        lda #$40+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
        sty COLBAK
        lda #$80+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
        lda #$40+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
        sty COLBAK
        lda #$80+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
        lda #$40+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
        sty COLBAK
        lda #$80+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
        lda #$40+GTIACTLBITS
        sta WSYNC
        sta GTIACTL
      dex
      bpl dli_upper_loop

      mva #>font_bottom CHBASE

        ldx #10
dli_bottom_loop 

          lda #$80+GTIACTLBITS
          sta WSYNC
          sta GTIACTL
          lda #$40+GTIACTLBITS
          sta WSYNC
          sta GTIACTL
          sty COLBAK

          lda #$80+GTIACTLBITS
          sta WSYNC
          sta GTIACTL
          lda #$40+GTIACTLBITS
          sta WSYNC
          sta GTIACTL
          sty COLBAK

          lda #$80+GTIACTLBITS
          sta WSYNC
          sta GTIACTL
          lda #$40+GTIACTLBITS
          sta WSYNC
          sta GTIACTL
          sty COLBAK

          lda #$80+GTIACTLBITS
          sta WSYNC
          sta GTIACTL
          lda #$40+GTIACTLBITS

          sta WSYNC
          sta GTIACTL
        dex
        bne dli_bottom_loop 


  
    lda #$00+GTIACTLBITS
    sta GTIACTL
    ;mva #>$E000 CHBASE  ;std. charset
    mva #>font_facebook CHBASE  

    mva #bottom_background_colour COLBAK
    mva #$00 COLPF1 ;gr.8 letters
    mva #bottom_background_colour COLPF2 ;gr.8 background
    
    lda #$38 ;CLI
    sta dli_facebook_switch

 
dli_exit
    ldy DLiY
    ldx DLiX
    lda DLA
    rti

;***************************************************************
;*********************** start ***********************
;***************************************************************

jumpo

    ldx #<MODUL					;low byte of RMT module to X reg
    ldy #>MODUL					;hi byte of RMT module to Y reg
    lda #0						;starting song line 0-255 to A reg
		sta VBLBeat
    jsr RASTERMUSICTRACKER		;Init
    ; info about plastic pop module:
    ; beat every 48 frames
    ; (every 8 steps, step every 6 frames)
   
   
    vmain VBLANK,7
    
    ;jmp skip_NO_SIGNAL_entirely
    
    gpause #48*3-1
   
    ; NO SIGNAL jumping
    ; add dl_nosignal_jump 
    ; and add parabolically
    ; untill it reaches  dl_nosignal_space_end

    mwa #dl_nosignal_space_begin tempSrc
    mwa #1 tempDest ; adder

    ldx #13
wait1    
    adw tempSrc tempDest
    inc tempDest
    mwa tempSrc dl_nosignal_jump
    gpause
    dex
    bne wait1
    
    gpause #48*2-13-4-1
       
;----start from top of the screen
    mva #7 counter
    mva #140 NO_SIGNAL_HSCR

see_saw
    ;mwa #dl_nosignal_space_end tempSrc
    mwa #1 tempDest ; subber
    ldx #17
wait2    
    sbw tempSrc tempDest
    inc tempDest
    mwa tempSrc dl_nosignal_jump
    gpause
    jsr NO_SIGNAL_scroll
    dex
    bne wait2
    
    ;up
    ldx #17
wait3    
    dec tempDest
    adw tempSrc tempDest
    mwa tempSrc dl_nosignal_jump
    gpause
    jsr NO_SIGNAL_scroll
    dex
    bne wait3

    ldx #48-34-1
waito_scrollto
    gpause
    jsr NO_SIGNAL_scroll
    dex
    bne waito_scrollto


    dec counter
    jne see_saw
no_jump_dim_loop    
    gpause
    dec COLPF1s
    lda COLPF1s
    sta COLPF2s
    sta COLBAKs
    and #$0F
    bne no_jump_dim_loop
    
    
skip_NO_SIGNAL_entirely
;---------------------end-of-[NO SIGNAL]-jumping    
    
    ;clearing PMG
    lda #0
    sta COLPF1s
    sta COLPF2s
    sta COLBAKs
    TAY

    ;mem clr
  	sty tempDest
    ldx #>(PMG+$200)
		stx tempDest+1

		ldx #6 ; clear 4 pages of RAM
clr_loop
    sta (tempDest),y
    iny
    bne clr_loop
		inc tempDest+1
		dex
		bne clr_loop
 
    ;vertical blinds (missiles)
    lda #$30
    ldx #28 ;blinds start
    sta PMG+$300-1,x
    lda #$FF
PMGblinds
    sta PMG+$300,x
    inx
    cpx #189  ;blinds end
    bne PMGblinds
    
    mva #41 HPOSM0
    mva #41-8 HPOSM3
    mva #208 HPOSM1
    mva #216 HPOSM2

    mva #$ff  SIZEM
    mva #>PMG PMBASE
    mva #3 PMCNTL
    mva #%00000001 SIZEP0
    
    lda #%00111110
    sta dmactls

    mwa #dl $0230

    lda #$38 ;CLI
    sta dli_facebook_switch
    vdli dli

    mva #$00+GTIACTLBITS GTICTLS  ;  == gr.8
  
    mva #$90 COLPM0s
    mva #$22 COLPM1s
    mva #$24 COLPM2s
    mva #$06 COLPM3s
    mva #$f8 COLPF0s
    lda #bottom_background_colour 
    sta COLPF1s  ;gr.8 letters
    sta COLPF2s  ;gr.8 background
    sta COLPF3s
    sta COLBAKS
    sta dli_facebook_colour+1
;--------------------------end-of-initialisation
    gpause #48*4-1
    jsr facebook_appear
    gpause #48*5-1
   ; + "Added July 27, 2009" appears
    mwa #dl_line1 dl_skip1
    
;--------------------------
    gpause #48-1
    mva #5 totalCount
demo_loop_1
    jsr totalBang
    dec totalCount
    bne demo_loop_1
;--------------------------
		lda #%00010101
		sta facebolek+6*40+13 
    ;+ "N" people like this appears
    mwa #dl_line2 dl_skip2
    gpause #48*3-1
    jsr print_InThisPhoto
    gpause #48-1
    jsr print_ITP_Miker
    ldx #0
    jsr ITP_sprites
    inc one_people_like_this
    
    lda #%00000100
    sta facebolek+4*40+16
    
   
    jsr print_ITP_pirx
    ldx #1
    jsr ITP_sprites
    inc one_people_like_this
    
    
    jsr print_ITP_sikor
    ldx #2
    jsr ITP_sprites
    gpause #48-1
    lda #%00000101
    sta facebolek+5*40+16

    inc one_people_like_this
    gpause #48/2-1
    inc one_people_like_this
  		lda #%00000100
    sta facebolek+6*40+16
  	gpause #48/2-1
    inc one_people_like_this
    jsr print_ITP_clear
    gpause #48*1-1
    lda #%00000101
    sta facebolek+7*40+16
	

		lda #%00011101
		sta facebolek+8*40+13  
		lda #%00010011
		sta facebolek+9*40+13  

    ;start bottom "scroller"
    mva #1 VBLBeat
    ;--------------------
    mva #3 counter+1
headEqalizerOuterLoop1
    mva #48*5+12 counter
headEqalizerLoop1
    jsr headEqualizer
    dec counter
    bne headEqalizerLoop1
    dec counter+1
    bne headEqalizerOuterLoop1
    ;--------------------
    mva #0 counter
    jsr headPrint
    lda #%00000101
    sta facebolek+7*40+16

    lda #%10101010
    sta facebolek+6*40+17

		lda #%10001000
    sta facebolek+7*40+17

    lda #%01110101
    sta facebolek+9*40+16

    lda #%01110100
    sta facebolek+10*40+16

    lda #%01111111
    sta facebolek+9*40+17

    lda #%01010101
    sta facebolek+10*40+17

    
    mva #4 counter+1
almost_the_last_loop
     mva #0 counter
swi1
    lda counter
		jsr swirlSikorRight
		gpause
    inc counter
    lda counter
    cmp #26
    bne swi1


     mva #0 counter
swi2
    lda counter
		jsr swirlPirxRight
		gpause
    inc counter
    lda counter
    cmp #26
    bne swi2


     mva #0 counter
swi3
    lda counter
		jsr swirlMikerRight
		gpause
    inc counter
    lda counter
    cmp #26
    bne swi3

   
     mva #25 counter
swi4
    lda counter
		jsr swirlMikerLeft
		gpause
    dec counter
    ;lda counter
    ;cmp #26
    bpl swi4

    lda #%00011101
		sta facebolek+6*40+13 

    
     mva #25 counter
swi5
    lda counter
		jsr swirlPirxLeft
		gpause
    dec counter
    ;lda counter
    ;cmp #26
    bpl swi5

    lda #%00010101
		sta facebolek+6*40+13 
    
     mva #25 counter
swi6
    lda counter
		jsr swirlSikorLeft
		gpause
    dec counter
    ;lda counter
    ;cmp #26
    bpl swi6
    
    dec counter+1
    jne almost_the_last_loop

    mva #4 counter+1
the_last_loop
     mva #0 counter
swi7
    lda counter
		jsr swirlSikorRight
    lda counter
		jsr swirlPirxRight
    lda counter
		jsr swirlMikerRight
		gpause
    inc counter
    lda counter
    cmp #26
    bne swi7

    mva #25 counter
swi8
    lda counter
		jsr swirlSikorLeft
    lda counter
		jsr swirlPirxLeft
    lda counter
		jsr swirlMikerLeft
		gpause
    dec counter
    bpl swi8
    dec counter+1
		bne the_last_loop

		gpause #48*5
fin    
    jsr headEqualizer
    jmp fin
    
;***************************************************************
;***********************subroutines***********************
;***************************************************************
headEqualizer
vol = trackn_audc
    ; head equalizer
    lda trackn_note+0
    and #$0f
    jsr printMiker
    lda trackn_note+1
    and #$0f
    jsr printPirx
    lda vol+3
    and #$0f
    jsr printSikor
    gpause
    rts
;----------------------
pause1
		pause
		rts
pauseMany
		clc
		adc RTCLOK+2
pauseManyLoop
		cmp RTCLOK+2
		bne pauseManyLoop
		rts

print_ITP_clear
    mwa #inThisPhoto_place tempDest
    mwa #PMG+$400 tempSrc ; zeroes
    ldy #in_this_photo_txt_miker-in_this_photo_txt-1+6
    jmp copyMe

print_ITP_sikor
    mwa #in_this_photo_txt_sikor tempSrc
    mwa #inThisPhoto_place+in_this_photo_txt_miker-in_this_photo_txt tempDest
    ldy #5-1
    jmp copyMe
print_ITP_pirx
    mwa #in_this_photo_txt_pirx tempSrc
    mwa #inThisPhoto_place+in_this_photo_txt_miker-in_this_photo_txt tempDest
    ldy #5-1
    jmp copyMe
print_ITP_Miker
    mwa #in_this_photo_txt_miker tempSrc
    mwa #inThisPhoto_place+in_this_photo_txt_miker-in_this_photo_txt tempDest
    ldy #5-1
    jmp copyMe
    
print_InThisPhoto
    mwa #inThisPhoto_place tempDest

    mwa #in_this_photo_txt tempSrc
    ldy #in_this_photo_txt_miker-in_this_photo_txt-1
    ;jmp copyMe
;--------------------
copyMe
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl copyMe
    rts
;--------------------

ITP_sprites
        
    ; "in this photo sprites"
    ; X - MIKER, PIRX, SIKOR
    lda #0    
    ldy #150
ITP_s_clr_loop
    sta PMG+$400,y
    dey
    bne ITP_s_clr_loop

    lda ITP_s_tab_H,x
    sta temp+1

    lda ITP_s_tab_V,x
    tax
    clc
    adc #29 ; frame height
    sta temp

    lda #$FF
    sta PMG+$400,x
    sta PMG+$400+1,x
    sta PMG+$400+2,x
    txa
    clc
    adc #3
    tax
    lda #$81
spriteput
    sta PMG+$400,x
    inx
    cpx temp
    bne spriteput  
    lda #$FF
    sta PMG+$400,x
    sta PMG+$400+1,x
    sta PMG+$400+2,x

    ldx #3*3 ; ==48*3
ITP_s_blink    
    lda temp+1
    sta HPOSP0
    gpause #8-1
    lda #0
    sta HPOSP0
    gpause #8-1
    dex
    bne ITP_s_blink
    
    rts
/*
miker_spr_H = 63
miker_spr_V = 66
pirx_spr_H = 109
pirx_spr_V = 56
sikor_spr_H = 171
sikor_spr_V = 61
*/
ITP_s_tab_H
    dta 63,109,171
ITP_s_tab_V
    dta 66,56,61
    


;--------------------
totalBang
    ; head bang
    mva #0 counter
headbang1
    jsr headPrint
    gpause #2-1
    inc counter
    lda counter
    cmp #16
    bne headbang1
    gpause #16-1
headbang2
    dec counter
    jsr headPrint
    gpause #2-1
    lda counter
    bne headbang2
    gpause #16-1
    rts
;--------------------------    
NO_SIGNAL_scroll
   ldy NO_SIGNAL_HSCR
    ;if NO_SIGNAL_HSCR<0 then NO_SIGNAL_HSCR++, continue
    bmi HSCR_skip01
    ; else
    sty HSCROL
    cpy #4
    bne HSCR_skip01
    ; move the screen
    ldy #42
NO_SIGNAL_move
    lda NO_SIGNAL,y
    sta NO_SIGNAL+1,y
    lda NO_SIGNAL+48,y
    sta NO_SIGNAL+48+1,y
    lda NO_SIGNAL+48*2,y
    sta NO_SIGNAL+48*2+1,y
    lda NO_SIGNAL+48*3,y
    sta NO_SIGNAL+48*3+1,y
    dey
    bne NO_SIGNAL_move
    
    ldy #0 
    sty HSCROL
    iny
    sty NO_SIGNAL_HSCR
    rts
HSCR_skip01    
    inc NO_SIGNAL_HSCR
    rts
;--------------------------
facebook_appear
    ldx #14
    stx COLPF1s
fb_appear_loop1
    gpause
    stx dli_facebook_colour+1
    stx COLPF1s
    stx COLPF2s
    stx COLBAKS
    stx COLPF1
    stx COLPF2
    stx COLBAK
    dex
    dex
    bpl fb_appear_loop1
    ; now it is dark
    ldx #0
fb_appear_loop2
    stx COLPF1s
    stx COLPF1
    stx COLPF2s
    stx COLPF2
    stx dli_facebook_colour+1
    gpause
    inx
    inx
    cpx #16
    bne fb_appear_loop2

    mva #$9F COLPF1s  ;gr.8 letters
    mva #$94 COLPF2s  ;gr.8 background
    sta dli_facebook_colour+1
    sta COLBAKS
    rts
    


;--------------------------
headPrint    ; prints heads
    lda counter
    and #$0f
    jsr printMiker
    lda counter
    and #$0f
    jsr printPirx
    lda counter
    and #$0f
    jsr printSikor
    rts


   /*
    Miker
    H:3 -- 10 : 8 bytes * 16 phases * 10 lines
    Pirx
    H:14 -- 23 : 10 bytes * 16 phases * 10 lines
    Sikor
    H: 30 -- 38 : 9 bytes * 16 phases * 10 lines
    */ 
widthMiker = 8
widthPirx = 10
widthSikor = 9
printMiker
; A =animation phase (0..15)  
/* adres_początkowy = miker + widthMiker*faza 
   czytaj widthMiker bajtów
   docel = screen00 +3
   adres_początkowy = adres_początkowy + (widthMiker*16)
   docel = docel + 40
*/
    ;widthMiker*faza
    asl
    asl
    asl ;A*8, one byte, because max is 8*16=128
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #miker
    mwa #screen00+3 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
remiker2
    ldy #widthMiker-1 ;miker'w width
remiker
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl remiker
    ; one line moved
    adw tempSrc #widthMiker*16
    adw tempDest #40
    dex
    bne remiker2
    rts
    
printPirx
; A =animation phase (0..15)  
    ;widthPirx*faza
    asl
    sta tempSrc
    asl
    asl ;A*10, one byte, because max is 10*16
    clc
    adc tempSrc
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #pirx
    mwa #screen00+14 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
rePirx2
    ldy #widthPirx-1 
rePirx
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl rePirx
    ; one line moved
    adw tempSrc #widthPirx*16
    adw tempDest #40
    dex
    bne rePirx2
    rts
    
printSikor
; A =animation phase (0..15)  
    ;widthSikor*faza
    sta tempSrc
    asl
	asl
    asl ;A*9, one byte, because max is 9*16
    clc
    adc tempSrc
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #sikor
    mwa #screen00+30 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
reSikor2
    ldy #widthSikor-1 
reSikor
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl reSikor
    ; one line moved
    adw tempSrc #widthSikor*16
    adw tempDest #40
    dex
    bne reSikor2
    rts

swirlMikerRight
; A =animation phase (0..15)  
    ;widthMiker*faza
    ; in swirlMiker the beginning phase is just the same
    sta swirlCount
    cmp #15
    bcc doNotSwirlTopMiker
    lda #15
doNotSwirlTopMiker
    asl
    asl
    asl ;A*8, one byte, because max is 8*16=128
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #miker
    mwa #screen00+3 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
Sremiker2
    ldy #widthMiker-1 ;miker'w width
Sremiker
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl Sremiker
    ; one line moved
    adw tempSrc #widthMiker*16
    adw tempDest #40
    lda swirlCount
    cmp #15+1
	bcs doDotSwirlMikerTop


    lda swirlCount
    beq doDotSwirlMiker
    sbw tempSrc #widthMiker
doDotSwirlMikerTop
    dec swirlCount
doDotSwirlMiker
    dex
    bne Sremiker2
    rts
;--	------------
swirlMikerLeft
; A =animation phase (0..25)  

    ;widthMiker*faza
    sec
    sbc #10
    sta swirlCount ; negatives, too
    ; if A>= 0 then OK
    bpl skipSML01 ; skipSwirlMikerLeft01
    lda #0
skipSML01
    asl
    asl
    asl ;A*8, one byte, because max is 8*16=128
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #miker
    mwa #screen00+3 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
Sremiker2L
    ldy #widthMiker-1 ;miker'w width
SremikerL
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl SremikerL
    ; one line moved
    adw tempSrc #widthMiker*16
    adw tempDest #40
    
    lda swirlCount
    ; if swirlCount < 0 then do not swirl (it is 0)
    bmi skipSML02
    
    lda swirlCount
    ; if swirlCount >=15 then do not swirl
    cmp #15
    bcs skipSML02

    adw tempSrc #widthMiker
skipSML02
    inc swirlCount

    dex
    bne Sremiker2L
    rts

;---------------
swirlPirxRight
; A =animation phase (0..15)  
    ;widthPirx*faza
    ; in swirlMiker the beginning phase is just the same
    sta swirlCount
    cmp #15
    bcc doNotSwirlTopPirx
    lda #15
doNotSwirlTopPirx
    asl
    sta tempSrc
    asl
    asl ;A*8, one byte, because max is 8*16=128
    clc
    adc tempSrc
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #pirx
    mwa #screen00+14 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
SrePirx2
    ldy #widthPirx-1 ;miker'w width
SrePirx
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl SrePirx
    ; one line moved
    adw tempSrc #widthPirx*16
    adw tempDest #40
    lda swirlCount
    cmp #15+1
	bcs doDotSwirlPirxTop


    lda swirlCount
    beq doDotSwirlPirx
    sbw tempSrc #widthPirx
doDotSwirlPirxTop
    dec swirlCount
doDotSwirlPirx
    dex
    bne SrePirx2
    rts
;--	------------
swirlPirxLeft
    ;widthPirx*faza
    sec
    sbc #10
    sta swirlCount ; negatives, too
    ; if A>= 0 then OK
    bpl skipSPL01 ; skipSwirlPirxLeft01
    lda #0
skipSPL01
    asl
    sta tempSrc
    asl
    asl ;A*10,
    clc
    adc tempSrc
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #pirx
    mwa #screen00+14 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
SrePirx2L
    ldy #widthPirx-1
SrePirxL
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl SrePirxL
    ; one line moved
    adw tempSrc #widthPirx*16
    adw tempDest #40
    
    lda swirlCount
    ; if swirlCount < 0 then do not swirl (it is 0)
    bmi skipSPL02
    
    lda swirlCount
    ; if swirlCount >=15 then do not swirl
    cmp #15
    bcs skipSPL02

    adw tempSrc #widthPirx
skipSPL02
    inc swirlCount

    dex
    bne SrePirx2L
    rts

;---------------
swirlSikorRight
    sta swirlCount
    cmp #15
    bcc doNotSwirlTopSikor
    lda #15
doNotSwirlTopSikor
    sta tempSrc
    asl
    asl
    asl ;A*9
    clc
    adc tempSrc
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #Sikor
    mwa #screen00+30 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
SreSikor2
    ldy #widthSikor-1 
SreSikor
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl SreSikor
    ; one line moved
    adw tempSrc #widthSikor*16
    adw tempDest #40
    lda swirlCount
    cmp #15+1
	bcs doDotSwirlSikorTop


    lda swirlCount
    beq doDotSwirlSikor
    sbw tempSrc #widthSikor
doDotSwirlSikorTop
    dec swirlCount
doDotSwirlSikor
    dex
    bne SreSikor2
    rts
;--	------------
swirlSikorLeft
    ;widthSikor*faza
    sec
    sbc #10
    sta swirlCount ; negatives, too
    ; if A>= 0 then OK
    bpl skipSiPL01 ; skipSwirlSikorLeft01
    lda #0
skipSiPL01
    sta tempSrc
    asl
    asl
    asl ;A*9,
    clc
    adc tempSrc
    sta tempSrc
    lda #0
    sta tempSrc+1
    adw tempSrc #Sikor
    mwa #screen00+30 tempDest
    ; src and dest addressess loaded

    ldx #10 ;number of lines
SreSikor2L
    ldy #widthSikor-1
SreSikorL
    lda (tempSrc),y
    sta (tempDest),y
    dey
    bpl SreSikorL
    ; one line moved
    adw tempSrc #widthSikor*16
    adw tempDest #40
    
    lda swirlCount
    ; if swirlCount < 0 then do not swirl (it is 0)
    bmi skipSiPL02
    
    lda swirlCount
    ; if swirlCount >=15 then do not swirl
    cmp #15
    bcs skipSiPL02

    adw tempSrc #widthSikor
skipSiPL02
    inc swirlCount

    dex
    bne SreSikor2L
    rts

;---------------
VBLANK
  jsr RASTERMUSICTRACKER+3
  ldy VBLBeat
  beq getMeOutVBL
	dey
	beq scrollMe
	sty VBLBeat
	bne getMeOutVBL
scrollMe
	ldy #48*2	
	sty VBLBeat
	
	adw dl_bottom_text_addr #40
	cpw dl_bottom_text_addr #messageScreenEnd
	bne getMeOutVBL
	mwa #messageScreen dl_bottom_text_addr
	
getMeOutVBL
  jmp XITVBV
;---------------

     

;-----------------------------
fontTable 
      .by >font09, >font08, >font07, >font06, >font05
      .by >font04, >font03, >font02, >font01, >font00
;-----------------------------

    .ERROR *>$3000
    
    org $3000
font_facebook
    ;ins '/gfs/LIGHTFACE.FNT' FFFUUUUUUUUUUUUUUUUUUUUUUUUUUUUU  GFS????
    ins '/gfx/LIGHTFACE_lite.FNT'   
screen00
    ins '/gfx/mapa00.bin',+0,40
screen01
    ins '/gfx/mapa01.bin',+0,40
screen02
    ins '/gfx/mapa02.bin',+0,40
screen03
    ins '/gfx/mapa03.bin',+0,40
screen04
    ins '/gfx/mapa04.bin',+0,40
screen05
    ins '/gfx/mapa05.bin',+0,40
screen06
    ins '/gfx/mapa06.bin',+0,40
screen07
    ins '/gfx/mapa07.bin',+0,40
screen08
    ins '/gfx/mapa08.bin',+0,40
screen09
    ins '/gfx/mapa09.bin',+0,40
screen_bottom
    INS '/gfx/mapa_bottom.bin'
    
    .ERROR *>$4000 
    org $4000

    .REPT 10, #
font0:1
    INS '/gfx/charset0:1.fnt'   ;font
    .ENDR

font_bottom
    INS '/gfx/charset_bottom.fnt'   ;font

miker
    ins '/gfx/miker.bin'
pirx
    ins 'gfx/pirx.bin'
sikor
    ins 'gfx/sikor.bin'

   .ERROR *>$8000 
    org $8000
MODUL
    ins 'msx/plastic_pop.rmt',+6
    .ERROR *>$8600
    org $8600
    icl 'rmtplayr.a65'
    .ERROR *>$9000
    org $9000
facebolek
    ins 'gfx/facebolek_flipv2.bmp',+(22+80)
in_this_photo_txt
    dta d"In This Photo: "
in_this_photo_txt_miker
    dta d                "Miker"
in_this_photo_txt_pirx
    dta d                "pirx "
in_this_photo_txt_Sikor
    dta d                "Sikor"
textScreen
    dta d"Added July 27,2009"
    dta 84 ; "dot"
    dta d"Like"
    dta 84
    dta d"Comment         " 
    
    dta 64,65 ;'thumbs up'
    :4 dta d" "
inThisPhoto_place    
    :34 dta d" "
    dta 64+16, 65+16,0
one_people_like_this
    dta d"1 people like this.                  "
messageScreen
    :80 .by 0
    dta d"EHLO ppl! pirx is back here, njoy pls!!!"
    dta d"Code, dsgn, gfx: pirx/5oft [www.5oft.pl]"
    dta d"MSX: Sack/Cosine. Sidey version: Miker  "
    dta d"general support and color scheme: Miker "
    dta d"Tools: mads, python, Altirra, exomizer, "
    dta d"AtariTools0.1.7, gimp, pirxompression..."
    dta d"Grtz:SikorBtronicPecusDrac030PhaeronDely"
    dta d"TebeJHusakDracon__EmkayKrapGorghPigulaPi"
    dta d"nokioYerzPr0beAzbestNostyAbbucKazJuryGrz"
    dta d"eniuTdcEpiXxlMacgyverRybagsCandleSebanZa"
    dta d"xonF0xPajeroLotharekPaskudElectronMonoGr"
    dta d"zybsonInnuendoMaziGreyLevisAcid..&..You!"
    
messageScreenEnd
    :40 .by 0

HappyEnding

    RUN RUNaddr
         
