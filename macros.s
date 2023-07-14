PRODOS			= $bf00		; MLI entry point
STACKCTL		= $e0c068
NEWVIDEO		= $e0c029
SHADOW			= $e0c035
KBD				= $e0c000
KBDSTROBE		= $e0c010

STACKPTR		= $70		; Cache for stack pointer in fast graphics
SHADOWREGISTER	= $72		; Cache for shadow register in fast graphics
STACKREGISTER	= $73		; Cache for stack register in fast graphics
PARAML0			= $06		; Zero page locations for parameter passing
PARAML1			= $08
SCRATCHL		= $19


.macro OP8
	.i8
	.a8
.endmacro


.macro OP16
	.i16
	.a16
.endmacro


.macro BITS8A
	sep #%00100000
	.a8
.endmacro


.macro BITS8
	sep #%00110000
	OP8
.endmacro


.macro BITS16
	rep #%00110000
	OP16
.endmacro


.macro SYNCDBR
	phk
	plb
.endmacro


.macro SAVE_DBR
	phb
	phk
	plb
.endmacro


.macro RESTORE_DBR
	plb
.endmacro


.macro EMULATION
	sec		; Enable 8-bit mode
	xce
	OP8
.endmacro


.macro NATIVE
	clc				; Enable 16-bit mode
	xce
	BITS16
.endmacro


.macro SAVE_AXY				; Saves all registers
	pha
	phx
	phy
.endmacro


.macro RESTORE_AXY			; Restores all registers
	ply
	plx
	pla
.endmacro


.macro  pstring Arg
	.byte   .strlen(Arg), Arg
.endmacro


.macro FASTGRAPHICS			;34 cycles, 12 bytes
	sei						;2
	phd						;4
	sep #%00100000	;		 3   8-bit A only, to preserve X/Y
	.a8

	lda STACKCTL			;5
	sta STACKREGISTER		;4
	ora #$30				;2
	sta STACKCTL			;5

	rep #%00100000			;3
	.a16
	tsc						;2
	sta STACKPTR			;4
.endmacro


.macro SLOWGRAPHICS			;28 cycles, 12 bytes
	sep #%00100000	;        3    8-bit A only, to preserve X/Y
	.a8

	lda STACKREGISTER		;4
	sta STACKCTL			;5

	rep #%00100000			;3
	.a16
	lda STACKPTR			;4
	tcs						;2
	pld						;5
	cli						;2
.endmacro


.macro SHRVIDEO
	BITS8
	lda NEWVIDEO
	ora	#%11000001
	sta NEWVIDEO
	BITS16
.endmacro


.macro CLASSICVIDEO
	BITS8
	lda NEWVIDEO
	and #%00111111
	sta NEWVIDEO
	BITS16
.endmacro


.macro SHADOWMEMORY
	sep #%00100000	;		 3   16-bit A only, to preserve X/Y
	.a8
	lda SHADOW				;5
	sta SHADOWREGISTER		;4
	lda #0					;2
	sta SHADOW				;5
	rep #%00100000			;3
	.a16
.endmacro


.macro NORMALMEMORY
	sep #%00100000	;        3    16-bit A only, to preserve X/Y
	.a8
	lda SHADOWREGISTER		;4
	sta SHADOW				;5
	rep #%00100000			;3
	.a16
.endmacro
