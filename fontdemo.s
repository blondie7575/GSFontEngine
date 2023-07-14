;
;  fontdemo.s
;
;  A very simplistic loader designed to show off the font engine
;  GS code, but running under ProDOS 8 (if it's good enough for Will Harvey...)
;
;  Created by Quinn Dunki on 7/13/23
;

.include "macros.s"

LOADBUFFER = $1000		; Clear of this loader code
BUFFERSIZE = $8200		; About max size we can fit between buffer and this loader code

.org $800

main:
	OP8		; We launch in emulation from ProDOS8. Stay there for now

	; Open the font file
	jsr PRODOS
	.byte $c8
	.addr fileOpenFonts
	bne ioError

	; Load the font data into bank 0
	jsr PRODOS
	.byte $ca
	.addr fileRead
	bne ioError

	NATIVE

	; Copy font data into bank 5
	ldx fileReadLen
	lda #5
	ldy #0
	jsr copyBytes

	; Prepare graphics
	lda #palette
	sta PARAML0
	lda #0
	jsr setPalette
;	jsr initSCBs

	; Move demo code into bank 2 where it's safe to execute
	lda #returnToProDOS
	sta bank2Return+1
	lda #bank2
	sta copyBytesLoop+1
	sta longJumpBank2+1
	ldx #(endBank2-bank2)+1
	lda #2
	ldy #bank2
	jsr copyBytes
	
longJumpBank2:
	jml $020000		; Self modifying code. Don't panic

returnToProDOS:
	SYNCDBR
	EMULATION
	rts

ioError:
	brk


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; copyBytes
; Copy data from read buffer in bank 0 to
; offset any other bank. Must be in native mode.
;
; X = Length of data in bytes
; Y = Origin within bank
; A = Bank number of destination
;
copyBytes:
	sty copyBytesDest+1
	sty copyBytesDest2+1

	phx
	BITS8
	sta copyBytesDest+3
	sta copyBytesDest2+3
	BITS16
	plx

	txa
	and #1
	bne copyBytesOdd

copyBytesEven:
	dex
	dex

copyBytesLoop:
	lda LOADBUFFER,x
copyBytesDest:
	sta $010000,x
	dex
	dex
	cpx #$fffe		; X will wrap when we're done
	bne copyBytesLoop
	rts

copyBytesOdd:
	dex
	BITS8A
	lda LOADBUFFER,x
copyBytesDest2:
	sta $010000,x
	BITS16
	bra copyBytesEven


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initSCBs
; Initialize all scanline control bytes
; Trashes A,X

initSCBs:
	lda #0
	ldx #$0100	;set all $100 scbs to A

initSCBsLoop:
	dex
	dex
	sta $e19cfe,x
	bne initSCBsLoop
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; setPalette
; Set all colors in a palette from memory
; PARAML0 = Pointer to 32 color bytes
; A = Palette index
;
setPalette:
	SAVE_AXY

	asl
	asl
	asl
	asl
	asl
	BITS8A
	sta setPaletteLoop_SMC+1
	BITS16
	ldx #0
	ldy #0

setPaletteLoop:
	lda (PARAML0),y
setPaletteLoop_SMC:
	sta $e19e00,x		; Self-modifying code!

	iny
	iny
	inx
	inx
	cpx #32
	bne setPaletteLoop

	RESTORE_AXY
	rts

palette:
	.word $0aef,$0080,$0080,$0861,$0c93,$0eb4,$0d66,$0f9a,$0777,$0f00,$0bbb,$ddd,$007b,$0a5b,$0000,$0fff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ProDOS 8 structures
;
fileRead:
	.byte 4
	.byte 1					; File handle (we know it's gonna be 1)
	.addr LOADBUFFER
	.word BUFFERSIZE
fileReadLen:
	.word 0					; Result (bytes read)

fileClose:
	.byte 1
	.byte 1					; File handle (we know it's gonna be 1)

fileOpenFonts:
	.byte 3
	.addr fontPath
	.addr $9200				; 1k below BASIC.SYSTEM
	.byte 0					; Result (file handle)
	.byte 0					; Padding

fontPath:
	pstring "/GSAPP/FONTBANK"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Bank 2 demo code. We run this from bank 2 because bank 0 won't
; be safe any more once we starting messing with all the soft switches
; to enable fast GS graphics
;
bank2:
	SYNCDBR

	; Demonstrate font engine
	SHRVIDEO
	SHADOWMEMORY
	
	; Erase the screen
	ldx #$eeee
	jsr colorFill

	; Draw some text
	lda #testString
	sta PARAML0
	lda #8
	sta PARAML1
	ldy #$43f0
	ldx #0
	jsl $050000

	; Draw more text in a different font!
	lda #testString
	sta PARAML0
	lda #16
	sta PARAML1
	ldy #$636c
	ldx #1
	jsl $050000

	; Wait for key
	BITS8
waitLoop:
	lda KBD
	bpl waitLoop
	sta KBDSTROBE
	BITS16

	NORMALMEMORY
	CLASSICVIDEO

bank2Return:
	jml $001234		; Self modifying code. Don't panic

testString:
	pstring "HELLO WORLD!"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; colorFill
; Fills the screen with a color (or two). Pretty fast, but not fastest possible
; X = 4:4:4:4 = Palette entries to fill
;
; Trashes A,Y

colorFill:
	FASTGRAPHICS

	lda #$9cff
	tcs
	ldy #200
	
colorFillLoop:
	; 80 PHXs, for 1 line
	; We could do the entire screen with PHXs, but this is a
	; balance between speed and code size
	.byte $da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da
	.byte $da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da
	.byte $da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da
	.byte $da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da

	dey
	bne colorFillLoop

	SLOWGRAPHICS
	rts
endBank2:

