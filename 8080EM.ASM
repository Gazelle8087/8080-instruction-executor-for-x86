;	8080 instruction executor for x86 Rev. 1.00
;
;	Copyright (C) 2024 by Gazelle
;
;Permission is hereby granted, free of charge, to any person
;obtaining a copy of this software and associated documentation
;files (the "Software"), to deal in the Software without
;restriction, including without limitation the rights to use,
;copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the
;Software is furnished to do so, subject to the following
;conditions:
;
;The above copyright notice and this permission notice shall be
;included in all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;OTHER DEALINGS IN THE SOFTWARE.

;Repository https://github.com/Gazelle8087/8080-instruction-executor-for-x86
;
;2024/8/22 Rev. 1.00 Initial release

	page 66,78
	.model	small
	.code

	assume	ds:nothing,es:nothing,ss:nothing

;-------------------------------------
;temp	equ	cx
temp	equ	dx
;-------------------------------------
;
;	Entry point : nnnn:0e0h (far call)
;;	DS must point base of 8080 instruction code area
;
;	return condition
;
;	SI have the address where the code here under was fetched.
;	BP have the return code corresponding to the code here under.
;
;	1	HLT
;	2	OUT (n),A
;	3	IN  A,(n)
;	7	undefined code (1 bytes)
;
;	register assign
;
;	A    : al
;	flag : ah
;	B    : ch
;	C    : cl
;	D    : dh
;	E    : dl
;	H    : bh
;	L    : bl
;	PC   : si
;	SP   : di
;
;-----------------------------------------------
code_HLT	equ	1
code_OUT	equ	2
code_IN		equ	3
code_undef1	equ	7

ifidni		temp,<dx>
temp_h		equ	dh
temp_l		equ	dl
BC		equ	cx
DE		equ	bp
elseifidni	temp,<cx>
temp_h		equ	ch
temp_l		equ	cl
BC		equ	bp
DE		equ	dx
endif
;-----------------------------------------------
PC80		equ	si
SP80		equ	di
AF		equ	ax
HL		equ	bx

B		equ	ch
C_reg		equ	cl
D		equ	dh
E		equ	dl
H		equ	bh
L		equ	bl
M		equ	byte ptr ds:[HL]
A		equ	al

;======================================
		org	0e0h
entry:
		mov	bp,temp
		cld
		mov	temp_h,ds:[PC80]
		mov	temp_l,0
		inc	PC80
		jmp	temp

;======================================
fetch1		macro
		mov	temp_h,ds:[PC80]
		inc	PC80
		jmp	temp
endm

fetch2		macro
		inc	PC80
		mov	temp_h,ds:[PC80]
		inc	PC80
		jmp	temp
endm

fetch3		macro
		mov	temp_h,ds:[PC80+2]
		add	PC80,3
		jmp	temp
endm

;======= M1 cycle ===============================

;--- LD	reg16,imm16
LXI		macro	dst
		mov	dst,ds:[PC80]
		fetch3
endm

;--- LD	reg8,imm8
MVI		macro	dst
ifidni	dst,temp_h
		mov	temp,bp
		mov	dst,ds:[PC80]
		mov	bp,temp
		mov	temp_l,0
elseifidni	dst,temp_l
		mov	temp,bp
		mov	dst,ds:[PC80]
		mov	bp,temp
		mov	temp_l,0
else
		mov	dst,ds:[PC80]
endif
		fetch2
endm

;--- INC reg16
INX		macro	src
		inc	src
		fetch1
endm

;--- DEC reg16
DCX		macro	src
		dec	src
		fetch1
endm

;--- INC reg8
INR		macro	src

		sahf

ifidni		src,temp_h

		mov	temp,bp
		inc	src
		mov	bp,temp
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		inc	src
		mov	bp,temp
		mov	temp_l,0
else
		inc	src
endif
		lahf
		fetch1
endm

;--- DEC reg8
DCR		macro	src

		sahf

ifidni		src,temp_h

		mov	temp,bp
		dec	src
		mov	bp,temp
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		dec	src
		mov	bp,temp
		mov	temp_l,0
else
		dec	src
endif
		lahf
		fetch1
endm

;--- ADD HL,reg16
ADDHL		macro	src
		ror	ah,1
		add	HL,src
		rcl	ah,1
		fetch1
endm

;--- LD ??,??
LD		macro	dst,src

ifidni		dst,src

elseifidni	dst,temp_h

		mov	temp,bp
		mov	dst,src
		mov	bp,temp
		mov	temp_l,0

elseifidni	dst,temp_l

		mov	temp,bp
		mov	dst,src
		mov	bp,temp
		mov	temp_l,0

elseifidni	src,temp_h

		mov	temp,bp
		mov	dst,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		mov	dst,src
		mov	temp_l,0
else
		mov	dst,src
endif
		fetch1
endm

;--- ADD A,reg8
ADD8	macro	src
ifidni	src,temp_h

		mov	temp,bp
		add	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		add	A,src
		mov	temp_l,0
else
		add	A,src
endif
		lahf
		fetch1
endm

;--- ADC A,reg8
ADC8		macro	src

		sahf

ifidni		src,temp_h

		mov	temp,bp
		adc	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		adc	A,src
		mov	temp_l,0
else
		adc	A,src
endif
		lahf
		fetch1
endm

;---  SUB reg8
SUB8	macro	src
ifidni		src,temp_h

		mov	temp,bp
		sub	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		sub	A,src
		mov	temp_l,0
else
		sub	A,src
endif
		lahf
		fetch1
endm

;---  SBC A,reg8
SBC8	macro	src

		sahf

ifidni		src,temp_h

		mov	temp,bp
		sbb	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		sbb	A,src
		mov	temp_l,0
else
		sbb	A,src
endif
		lahf
		fetch1
endm

;--- AND reg8
ANA	macro	src
ifidni		src,temp_h

		mov	temp,bp
		and	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		and	A,src
		mov	temp_l,0
else
		and	A,src
endif
		lahf
		fetch1
endm

;---  OR reg8
ORA	macro	src
ifidni		src,temp_h

		mov	temp,bp
		or	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		or	A,src
		mov	temp_l,0
else
		or	A,src
endif
		lahf
		fetch1
endm

;--- XOR reg8
XRA	macro	src
ifidni		src,temp_h

		mov	temp,bp
		xor	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		xor	A,src
		mov	temp_l,0
else
		xor	A,src
endif
		lahf
		fetch1
endm

;--- CP reg8
CPA	macro	src
ifidni		src,temp_h

		mov	temp,bp
		cmp	A,src
		mov	temp_l,0

elseifidni	src,temp_l

		mov	temp,bp
		cmp	A,src
		mov	temp_l,0
else
		cmp	A,src
endif
		lahf
		fetch1
endm

;--- CALL cc,nn
CALL80		macro	cc
		add	PC80,2
ifnb		<cc>
		sahf
		j&cc	@f
		fetch1
@@:
endif
		sub	SP80,2
		mov	ds:[SP80],PC80
		mov	PC80,ds:[PC80-2]
		fetch1
endm

;--- JP cc,nn
JP80		macro	cc
ifnb		<cc>
		sahf
		j&cc	@f
		fetch3
@@:
endif
		mov	PC80,ds:[PC80]
		fetch1
endm

;--- RET cc
RET80		macro	cc
ifnb		<cc>
		sahf
		j&cc	@f
		fetch1
@@:
endif
		mov	PC80,ds:[SP80]
		add	SP80,2
		fetch1
endm

;--- RST n
RST		macro	nn
		sub	SP80,2
		mov	ds:[SP80],PC80
		mov	PC80,nn
		fetch1
endm

;---  PUSH reg16
PUSH8		macro	src
		sub	SP80,2
ifidni		src,AF
		xchg	ah,al
		mov	ds:[SP80],src
		xchg	ah,al
else
		mov	ds:[SP80],src
endif
		fetch1
endm

;--- POP reg16
POP8		macro	dst
		mov	dst,ds:[SP80]
ifidni		dst,AF
		xchg	ah,al
endif
		add	SP80,2
		fetch1
endm

;======================================
op2	=	0

M1	macro	nn
	rept	nn - op2
		org	op2 * 100h
		mov	temp,bp
		mov	bp,code_undef1
		retf
		op2	= op2 + 1
	endm
	op2	= nn + 1
	org	nn * 100h
endm

M1	00				;NOP
no_op:
		fetch1

exe_msg		db	0dh,0ah,'8080 instruction executor for x86 Rev. 1.00  ',0dh,0ah
		db	'Copyright (c) 2024 by Gazelle.  ',0dh,0ah
		db	'https://github.com/Gazelle8087  ',0dh,0ah,24h

M1	01				;LD	BC,nn
		LXI	BC

M1	02				;LD	(BC),A
ifidni		BC,<bp>
		mov	ds:[BC],A
		fetch1
else
		mov	temp,di
		mov	di,BC
		mov	ds:[di],A
		mov	di,temp
		mov	temp_l,0
		fetch1
endif

M1	03				;INC	BC
		INX	BC

M1	04				;INC	B
		INR	B

M1	05				;DEC	B
		DCR	B

M1	06				;LD	B,n
		MVI	B

M1	07				;RLCA
		sahf
		rol	A,1
		lahf
		fetch1

M1	09				;ADD	HL,BC
		ADDHL	BC

M1	0AH				;LD	A,(BC)
ifidni		BC,<bp>
		mov	A,ds:[BC]
		fetch1
else
		mov	temp,di
		mov	di,BC
		mov	A,ds:[di]
		mov	di,temp
		mov	temp_l,0
		fetch1
endif

M1	0BH				;DEC	BC
		DCX	BC

M1	0CH				;INC	C_reg
		INR	C_reg

M1	0DH				;DEC	C_reg
		DCR	C_reg

M1	0EH				;LD	C,n
		MVI	C_reg

M1	0FH				;RRCA
		sahf
		ror	A,1
		lahf
		fetch1

M1	11h				;LD	DE,nn
		LXI	DE

M1	12H				;LD	(DE),A
ifidni		DE,<bp>
		mov	ds:[DE],A
		fetch1
else
		mov	temp,di
		mov	di,DE
		mov	ds:[di],A
		mov	di,temp
		mov	temp_l,0
		fetch1
endif

M1	13H				;INC	DE
		INX	DE

M1	14H				;INC	D
		INR	D

M1	15H				;DEC	D
		DCR	D

M1	16H				;LD	D,n
		MVI	D

M1	17H				;RLA
		sahf
		rcl	A,1
		lahf
		fetch1


M1	19H				;ADD	HL,DE
		ADDHL	DE

M1	1AH				;LD	A,(DE)
ifidni		DE,<bp>
		mov	A,ds:[DE]
		fetch1
else
		mov	temp,di
		mov	di,DE
		mov	A,ds:[di]
		mov	di,temp
		mov	temp_l,0
		fetch1
endif

M1	1BH				;DEC	DE
		DCX	DE

M1	1CH				;INC	E
		INR	E

M1	1DH				;DEC	E
		DCR	E

M1	1EH				;LD	E,n
		MVI	E

M1	1FH				;RRA
		sahf
		rcr	A,1
		lahf
		fetch1


M1	21H				;LD	HL,nn
		LXI	HL

M1	22H				;LD	(nn),HL
		mov	temp,di
		mov	di,ds:[PC80]
		mov	ds:[di],HL
		mov	di,temp
		mov	temp_l,0
		fetch3

M1	23H				;INC	HL
		INX	HL

M1	24H				;INC	H
		INR	H

M1	25H				;DEC	H
		DCR	H

M1	26H				;LD	H,n
		MVI	H

M1	27H				;DAA	*****
		sahf
		daa
		lahf
		fetch1


M1	29H				;ADD	HL,HL
		ADDHL	HL

M1	2AH				;LD	HL,(nn)
		mov	HL,ds:[PC80]
		mov	HL,ds:[HL]
		fetch3

M1	2BH				;DEC	HL
		DCX	HL

M1	2CH				;INC	L
		INR	L

M1	2DH				;DEC	L
		DCR	L

M1	2EH				;LD	L,n
		MVI	L

M1	2FH				;CPL	complement A
		not	A
		fetch1


M1	31H				;LD	SP,nn
		LXI	SP80

M1	32H				;LD	(nn),A
		mov	temp,di
		mov	di,ds:[PC80]
		mov	ds:[di],A
		mov	di,temp
		mov	temp_l,0
		fetch3

M1	33H				;INC	SP
		INX	SP80

M1	34H				;INC	(HL)
		INR	M

M1	35H				;DEC	M
		DCR	M

M1	36H				;LD	(HL),n
		mov	temp_h,ds:[PC80]
		mov	ds:[HL],temp_h
		fetch2

M1	37H				;SCF	set carry flag
		or	ah,00000001b
		fetch1


M1	39H				;ADD	HL,SP
		ADDHL	SP80

M1	3AH				;LD	A,(nn)
		mov	temp,di
		mov	di,ds:[PC80]
		mov	A,ds:[di]
		mov	di,temp
		mov	temp_l,0
		fetch3

M1	3BH				;DEC	SP
		DCX	SP80

M1	3CH				;INC	A
		INR	A

M1	3DH				;DEC	A
		DCR	A

M1	3EH				;LD	A,n
		lodsb
		fetch1

M1	3FH				;CCF	complement carry flag
		xor	ah,00000001b
		fetch1
;--------------------------------------
M1	40H
		LD	B,B
M1	41H
		LD	B,C_reg
M1	42H
		LD	B,D
M1	43H
		LD	B,E
M1	44H
		LD	B,H
M1	45H
		LD	B,L
M1	46H
		LD	B,M
M1	47H
		LD	B,A

M1	48H
		LD	C_reg,B
M1	49H
		LD	C_reg,C_reg
M1	4AH
		LD	C_reg,D
M1	4BH
		LD	C_reg,E
M1	4CH
		LD	C_reg,H
M1	4DH
		LD	C_reg,L
M1	4EH
		LD	C_reg,M
M1	4FH
		LD	C_reg,A

M1	50H
		LD	D,B
M1	51H
		LD	D,C_reg
M1	52H
		LD	D,D
M1	53H
		LD	D,E
M1	54H
		LD	D,H
M1	55H
		LD	D,L
M1	56H
		LD	D,M
M1	57H
		LD	D,A

M1	58H
		LD	E,B
M1	59H
		LD	E,C_reg
M1	5AH
		LD	E,D
M1	5BH
		LD	E,E
M1	5CH
		LD	E,H
M1	5DH
		LD	E,L
M1	5EH
		LD	E,M
M1	5FH
		LD	E,A

M1	60H
		LD	H,B
M1	61H
		LD	H,C_reg
M1	62H
		LD	H,D
M1	63H
		LD	H,E
M1	64H
		LD	H,H
M1	65H
		LD	H,L
M1	66H
		LD	H,M
M1	67H
		LD	H,A

M1	68H
		LD	L,B
M1	69H
		LD	L,C_reg
M1	6AH
		LD	L,D
M1	6BH
		LD	L,E
M1	6CH
		LD	L,H
M1	6DH
		LD	L,L
M1	6EH
		LD	L,M
M1	6FH
		LD	L,A

M1	70H
		LD	M,B
M1	71H
		LD	M,C_reg
M1	72H
		LD	M,D
M1	73H
		LD	M,E
M1	74H
		LD	M,H
M1	75H
		LD	M,L
M1	76H				;HLT
		mov	temp,bp
		mov	bp,code_HLT
		retf
M1	77H
		LD	M,A

M1	78H
		LD	A,B
M1	79H
		LD	A,C_reg
M1	7AH
		LD	A,D
M1	7BH
		LD	A,E
M1	7CH
		LD	A,H
M1	7DH
		LD	A,L
M1	7EH
		LD	A,M
M1	7FH
		LD	A,A
;--------------------------------------
M1	80H
		ADD8	B
M1	81H
		ADD8	C_reg
M1	82H
		ADD8	D
M1	83H
		ADD8	E
M1	84H
		ADD8	H
M1	85H
		ADD8	L
M1	86H
		ADD8	M
M1	87H
		ADD8	A

M1	88H
		ADC8	B
M1	89H
		ADC8	C_reg
M1	8AH
		ADC8	D
M1	8BH
		ADC8	E
M1	8CH
		ADC8	H
M1	8DH
		ADC8	L
M1	8EH
		ADC8	M
M1	8FH
		ADC8	A

M1	90H
		SUB8	B
M1	91H
		SUB8	C_reg
M1	92H
		SUB8	D
M1	93H
		SUB8	E
M1	94H
		SUB8	H
M1	95H
		SUB8	L
M1	96H
		SUB8	M
M1	97H
		SUB8	A

M1	98H
		SBC8	B
M1	99H
		SBC8	C_reg
M1	9AH
		SBC8	D
M1	9BH
		SBC8	E
M1	9CH
		SBC8	H
M1	9DH
		SBC8	L
M1	9EH
		SBC8	M
M1	9FH
		SBC8	A

M1	0A0H
		ANA	B
M1	0A1H
		ANA	C_reg
M1	0A2H
		ANA	D
M1	0A3H
		ANA	E
M1	0A4H
		ANA	H
M1	0A5H
		ANA	L
M1	0A6H
		ANA	M
M1	0A7H
		ANA	A

M1	0A8H
		XRA	B
M1	0A9H
		XRA	C_reg
M1	0AAH
		XRA	D
M1	0ABH
		XRA	E
M1	0ACH
		XRA	H
M1	0ADH
		XRA	L
M1	0AEH
		XRA	M
M1	0AFH
		XRA	A

M1	0B0H
		ORA	B
M1	0B1H
		ORA	C_reg
M1	0B2H
		ORA	D
M1	0B3H
		ORA	E
M1	0B4H
		ORA	H
M1	0B5H
		ORA	L
M1	0B6H
		ORA	M
M1	0B7H
		ORA	A

M1	0B8H
		CPA	B
M1	0B9H
		CPA	C_reg
M1	0BAH
		CPA	D
M1	0BBH
		CPA	E
M1	0BCH
		CPA	H
M1	0BDH
		CPA	L
M1	0BEH
		CPA	M
M1	0BFH
		CPA	A
;--------------------------
M1	0C0H
		RET80	NZ

M1	0C1H
		POP8	BC

M1	0C2H
		JP80	NZ

M1	0C3H
		JP80

M1	0C4H
		CALL80	NZ

M1	0C5H
		PUSH8	BC

M1	0C6H				;add	A,n
		add	A,ds:[PC80]
		lahf
		fetch2

M1	0C7H
		RST	00h

M1	0C8H
		RET80	Z

M1	0C9H
		RET80

M1	0CAH
		JP80	Z

M1	0CCH
		CALL80	Z

M1	0CDH
		CALL80

M1	0CEH				;ADC	A,n
		sahf
		adc	A,ds:[PC80]
		lahf
		fetch2

M1	0CFH
		RST	08h

M1	0D0H
		RET80	NC

M1	0D1H
		POP8	DE

M1	0D2H
		JP80	NC

M1	0D3H				;OUT	(n),A
		mov	temp,bp
		mov	bp,code_OUT
		retf

M1	0D4H
		CALL80	NC

M1	0D5H
		PUSH8	DE

M1	0D6H				;SUB	n
		sub	A,ds:[PC80]
		lahf
		fetch2

M1	0D7H
		RST	10h

M1	0D8H
		RET80	C

M1	0DAH
		JP80	C

M1	0DBH				;IN	A,(n)
		mov	temp,bp
		mov	bp,code_IN
		retf

M1	0DCH
		CALL80	C

M1	0DEH				;SBC	A,n
		sahf
		sbb	A,ds:[PC80]
		lahf
		fetch2

M1	0DFH
		RST	18h

M1	0E0H
		RET80	PO

M1	0E1H
		POP8	HL

M1	0E2H
		JP80	PO

M1	0E3H
		xchg	HL,ds:[SP80]	;EX	(SP),HL
		fetch1

M1	0E4H
		CALL80	PO

M1	0E5H
		PUSH8	HL

M1	0E6H				;AND	n
		and	A,ds:[PC80]
		lahf
		fetch2

M1	0E7H
		RST	20h

M1	0E8H
		RET80	PE

M1	0E9H
		mov	PC80,HL		;JP	(HL)
		fetch1

M1	0EAH
		JP80	PE

M1	0EBH
		xchg	DE,HL		;EX	DE,HL
		fetch1

M1	0ECH
		CALL80	PE

M1	0EEH				;XOR	n
		xor	A,ds:[PC80]
		lahf
		fetch2

M1	0EFH
		RST	28h

M1	0F0H
		RET80	ns		;RET	P

M1	0F1H
		POP8	AF

M1	0F2H
		JP80	ns		;JP	P,nn

M1	0F3H
;		cli			;DI	****
		fetch1

M1	0F4H
		call80	ns		;CALL	P,nn

M1	0F5H
		PUSH8	AF

M1	0F6H				;OR	n
		or	A,ds:[PC80]
		lahf
		fetch2

M1	0F7H
		RST	30h

M1	0F8H
		RET80	s		;RET	M

M1	0F9H
		LD	SP80,HL		;LD	SP,HL

M1	0FAH
		JP80	s		;JP	M,nn

M1	0FBH				;EI	****
		sti
		fetch1

M1	0FCH
		CALL80	s		;CALL	M,nn

M1	0FEH				;CP	n
		cmp	A,ds:[PC80]
		lahf
		fetch2

M1	0FFH
		RST	38h

;================================================
exe_start:	mov	ax,cs
		mov	ds,ax
		mov	dx,offset exe_msg
		mov	ah,09h
		int	21h
		mov	ax,4c00h
		int	21h

		.data
		.stack

		end	exe_start
