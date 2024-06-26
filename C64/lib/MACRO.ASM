


.macro	basic_start(addr)

	.word upstartEnd	// link address
	.word 10		// line num
	.byte $9e		// sys

	?a=0
	?b=0
	?c=0
	?d=0
	?e=0

	?v = %%addr

	ift ?v>=10000
	?a=?v/10000
	?v=?v-(?a*10000)
	eif

	ift ?v>=1000
	?b=?v/1000
	?v=?v-(?b*1000)
	eif

	ift ?v>=100
	?c=?v/100
	?v=?v-(?c*100)
	eif

	ift ?v>=10
	?d=?v/10
	?v=?v-(?d*10)
	eif

	?e=?v%10

	dta ?a+$30,?b+$30,?c+$30,?d+$30,?e+$30

	.byte 0
upstartEnd
	.word 0			// empty link signals the end of the program

.endm


//
// Switch bank in VIC-II
//
// Args:
//    bank: bank number to switch to. Valid values: 0-3.
//
.macro SwitchVICBank(bank)
    //
    // The VIC-II chip can only access 16K bytes at a time. In order to
    // have it access all of the 64K available, we have to tell it to look
    // at one of four banks.
    //
    // This is controller by bits 0 and 1 in $dd00 (PORT A of CIA #2).
    //
    //  +------+-------+----------+-------------------------------------+
    //  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                  |
    //  |      |       | LOCATION |                                     |
    //  +------+-------+----------+-------------------------------------+
    //  |  00  |   3   |   49152  | ($C000-$FFFF)*                      |
    //  |  01  |   2   |   32768  | ($8000-$BFFF)                       |
    //  |  10  |   1   |   16384  | ($4000-$7FFF)*                      |
    //  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)       |
    //  +------+-------+----------+-------------------------------------+
    ?bits=%11

    ift (%%bank==0)
     ?bits=%11
    eli (%%bank==1)
     ?bits=%10
    eli (%%bank==2)
     ?bits=%01
    eli (%%bank==3)
     ?bits=%00
    eif

    //
    // Set Data Direction for CIA #2, Port A to output
    //
    lda $dd02
    and #%11111100  // Mask the bits were interested in.
    ora #$03        // Set bits 0 and 1.
    sta $dd02

    //
    // Tell VIC-II to switch to bank
    //
    lda $dd00
    and #%11111100
    ora #?bits
    sta $dd00
.endm


//
// Enter hires bitmap mode (a.k.a. standard bitmap mode)
//
.macro SetHiresBitmapMode
    //
    // Clear extended color mode (bit 6) and set bitmap mode (bit 5)
    //
    lda $d011
    and #%10111111
    ora #%00100000
    sta $d011

    //
    // Clear multi color mode (bit 4)
    //
    lda $d016
    and #%11101111
    sta $d016
.endm


//
// Enter hires bitmap mode (a.k.a. standard bitmap mode)
//
.macro SetMulticolorBitmapMode
    //
    // Clear extended color mode (bit 6) and set bitmap mode (bit 5)
    //
    lda $d011
    and #%10111111
    ora #%00100000
    sta $d011

    //
    // Clear multi color mode (bit 4)
    //
    lda $d016
    ora #%00010000
    sta $d016
.endm


//
// Switch location of screen memory.
//
// Args:
//   address: Address relative to current VIC-II bank base address.
//            Valid values: $0000-$3c00. Must be a multiple of $0400.
//
.macro SetScreenMemory(address)
    //
    // The most significant nibble of $D018 selects where the screen is
    // located in the current VIC-II bank.
    //
    //  +------------+-----------------------------+
    //  |            |         LOCATION*           |
    //  |    BITS    +---------+-------------------+
    //  |            | DECIMAL |        HEX        |
    //  +------------+---------+-------------------+
    //  |  0000XXXX  |      0  |  $0000            |
    //  |  0001XXXX  |   1024  |  $0400 (DEFAULT)  |
    //  |  0010XXXX  |   2048  |  $0800            |
    //  |  0011XXXX  |   3072  |  $0C00            |
    //  |  0100XXXX  |   4096  |  $1000            |
    //  |  0101XXXX  |   5120  |  $1400            |
    //  |  0110XXXX  |   6144  |  $1800            |
    //  |  0111XXXX  |   7168  |  $1C00            |
    //  |  1000XXXX  |   8192  |  $2000            |
    //  |  1001XXXX  |   9216  |  $2400            |
    //  |  1010XXXX  |  10240  |  $2800            |
    //  |  1011XXXX  |  11264  |  $2C00            |
    //  |  1100XXXX  |  12288  |  $3000            |
    //  |  1101XXXX  |  13312  |  $3400            |
    //  |  1110XXXX  |  14336  |  $3800            |
    //  |  1111XXXX  |  15360  |  $3C00            |
    //  +------------+---------+-------------------+
    //
    ?bits = (%%address / $0400) << 4

    lda $d018
    and #%00001111
    ora #?bits
    sta $d018
.endm


//
// Set location of bitmap.
//
// Args:
//    address: Address relative to VIC-II bank address.
//             Valid values: $0000 (bitmap at $0000-$1FFF)
//                           $2000 (bitmap at $2000-$3FFF)
//
.macro SetBitmapAddress(address)
    //
    // In standard bitmap mode the location of the bitmap area can
    // be set to either BANK address + $0000 or BANK address + $2000
    //
    // By setting bit 3, we can configure which of the locations to use.
    //

    lda $d018

    ift %%address == $0000
        and #%11110111
    eli %%address == $2000
        ora #%00001000
    eif

    sta $d018
.endm

//
// Once this is done, random values appear in location $D41B (RANDOM)
//
.macro InitializeSIDrnd
	LDA #$FF  ; maximum frequency value
	STA $D40E ; voice 3 frequency low byte
	STA $D40F ; voice 3 frequency high byte
	LDA #$80  ; noise waveform, gate bit off
	STA $D412 ; voice 3 control register
.endm

;-------------------------------------
  .MACRO rolw
     ROL :1
    ROL :1+1
  .ENDM
;-------------------------------------
  .MACRO aslw
    ASL :1
    ROL :1+1
  .ENDM
;-------------------------------------
  .MACRO rorw
    ROR :1+1
    ROR :1
  .ENDM
;-------------------------------------
  .MACRO lsrw
    LSR :1+1
    ROR :1
  .ENDM
;-------------------------------------
    .macro randomize
    ;usage: randomize floor ceiling
    ;returns (in A) a random .byte between "floor" and "ceiling"
    .if :2 < :1
      .error "floor higher than ceiling"
    .endif
?rand
      lda random
      cmp #:2+1-:1 ;ceiling
      bcs ?rand
    .if %1>0    ; if floor = 0 - no add offset
      adc #:1
    .endif
    .endm
;-------------------------------------
    .macro phx
      txa
      pha
    .endm
;-------------------------------------
    .macro phy
      tya
      pha
    .endm
;-------------------------------------
    .macro plx
      pla
      tax
    .endm
;-------------------------------------
    .macro ply
      pla
      tay
    .endm
;-------------------------------------
    .macro txy
      txa
      tay
    .endm
;-------------------------------------
    .macro tyx
      tya
      tax
    .endm
;-------------------------------------
	.MACRO WAIT
;	WAIT
;	waits one frame (1/50 s(PAL) or 1/60s(NTSC))
?ze	LDA $D012
	cmp #16	; if line<16 then wait for line>15 (long VBI protection)
	bcc ?ze
	sbc #10	; last lines correction
?wa	cmp $D012
	bcc ?wa
?wf	cmp $D012
	bcs ?wf
	.ENDM
;-------------------------------------
.macro halt
?s	jmp ?s
.endm