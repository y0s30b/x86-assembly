; SKKU Microprocessor HW3 of x86, by Yoseob Kim(2015312229)
[org 0x7c00]		; Assembly command
					; Let NASM compiler know starting address of memory
					; BIOS reads 1st sector and copied it on memory address 0x7c00
[bits 16] 			; Assembly command
					; Let NASM compiler know that this code consists of 16its

[SECTION .text] 	; text section
START:				; boot loader(1st sector) starts
    cli
    xor ax, ax
    mov ds, ax
    mov sp, 0x9000 		; stack pointer 0x9000
	
	mov ax, 0xB800
    mov es, ax 			; memory address of printing on screen
	
    mov al, byte [MSG_test]
    mov byte [es : 80*2*0+2*0], al
    mov byte [es : 80*2*0+2*0+1], 0x05
	mov al, byte [MSG_test+1]
    mov byte [es : 80*2*0+2*1], al
    mov byte [es : 80*2*0+2*1+1], 0x06
	mov al, byte [MSG_test+2]
    mov byte [es : 80*2*0+2*2], al
    mov byte [es : 80*2*0+2*2+1], 0x07
	mov al, byte [MSG_test+3]
    mov byte [es : 80*2*0+2*3], al
    mov byte [es : 80*2*0+2*3+1], 0x08
	sti
	
	
    call load_sectors 		; load rest sectors
    jmp sector_2
load_sectors:			 	; read and copy the rest sectors of disk

   	push es
    xor ax, ax
    mov es, ax									; es=0x0000
 	mov bx, sector_2 							; es:bx, Buffer Address Pointer
    mov ah,2 									; Read Sector Mode
    mov al,(sector_end - sector_2)/512 + 1  	; Sectors to Read Count
    mov ch,0 									; Cylinder Number=0
    mov cl,2 									; Sector Number=2
    mov dh,0 									; Head=0
    mov dl,0 									; Drive=0, A:drive
	int 0x13 									; BIOS interrupt
												; Services depend on ah value
    pop es
    ret
	
MSG_test: db'test',0

times   510-($-$$) db 0 		; $ : current address, $$ : start address of SECTION
								; $-$$ means the size of source
dw      0xAA55 					; signature bytes
								; End of Master Boot Record(1st Sector)
				
sector_2:						; Program Starts
	cli		
	lgdt	[gdt_ptr]			; Load GDT	
	

	
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax			; Switch Real mode to Protected mode

	

	jmp SYS_CODE_SEL:Protected_START	; jump Protected_START
											; Remove prefetch queue
;---------------------------------------------------------------		
Protected_START:	; Protected mode starts
[bits 32]			; Assembly command
					; Let NASM compiler know that this code consists of 32its

	mov ax, Video_SEL		
	mov es, ax

	mov edi, 80*2*1+2*0					
	mov eax, MSG_Protected_MODE_Test
	mov bl, 0x02
	call printf_s
	call print_cs_Protected
	
;-------------------------write your code here---------------------
; control transfer 						  						  ;
; 											 					  ;
	; get the base address of LDT and set the LDTR in GDT idx:4.
	; base 15:0 of the start address of ldt		

	; ldt1 setting (base address)
	mov eax, ldt
	mov word [gdt+LDTR1+2h], ax
	; base 23:16 of the start address of ldt
	shr eax, 16
	mov byte [gdt+LDTR1+4h], al
	; base 31:24 of the start address of ldt
	mov eax, ldt
	shr eax, 24
	mov byte [gdt+LDTR1+7h], al

	; ldt2 setting (base address)
	mov eax, ldt2
	mov word [gdt+LDTR2+2h], ax
	; base 23:16 of the start address of ldt
	shr eax, 16
	mov byte [gdt+LDTR2+4h], al
	; base 31:24 of the start address of ldt
	mov eax, ldt2
	shr eax, 24
	mov byte [gdt+LDTR2+7h], al

	; offset setting (ldt1)

	; offset setting (ldt2)
;																  ;
;------------------------------------------------------------------	

LDT0_Start:

; print strings
; control transfer

	call print_cs_LDT0_Start

; control transfer	

LDT0_Next:

; print strings
; control transfer

	call print_cs_LDT0_Next
    call print_cs_in_stack

LDT1_Start:

; print strings
; control transfer

	call print_cs_LDT1_Start
	jmp $						;end the program
;------------------------------------------------------------------------	
MSG_Protected_MODE_Test: db'Protected Mode',0
MSG_LDT0_Start: db'Jumped to LDT0 with LDT_CODE_SEL_0',0
MSG_LDT0_Next: db'Jumped to LDT0_Next with LDT_CODE_SEL_1',0
MSG_LDT1_Start: db'Jumped to LDT1 with LDT_CODE_SEL_2',0
CS_Protected_Start: db'CS register of Protected_Start:',0
CS_LDT0_Start: db'CS register of LDT0_Start:',0
CS_LDT0_Next: db'CS register of LDT0_Next:',0
CS_LDT1_Start: db'CS register of LDT1_Start:',0
CS_in_stack: db'CS register in stack:',0
printf_s:
	mov cl, byte [ds:eax]
	mov byte [es: edi], cl
	inc edi
	mov byte [es: edi], bl
	inc edi

	inc eax								
	mov cl, byte [ds:eax]
	mov ch, 0
	cmp cl, ch							
	je printf_end						
	jmp printf_s	

printf_end:
	ret
	
temp: dd 0

printf_n:
	inc eax
	inc eax
	inc eax
	mov bh, 0x01
	jmp printf2
printf2:
	mov cl, byte [ds:eax]
	
	mov dl, cl
	shr dl, 4
	cmp dl, 0x09
	ja a1
	jmp a2
printf3:
	mov byte [es: edi], dl
	inc edi
	mov byte [es: edi], bl
	inc edi
	mov dl, cl
	and dl, 0x0f
	cmp dl, 0x09
	ja a3
	jmp a4
printf4:
	mov byte [es: edi], dl
	inc edi
	mov byte [es: edi], bl
	inc edi
	
	cmp bh, 0x04
	je printf_end1
	jmp a5

a1 :
	add dl, 0x37
	jmp printf3	
a2 :
	add dl, 0x30
	jmp printf3
a3 :
	add dl, 0x37
	jmp printf4
a4 :
	add dl, 0x30
	jmp printf4
a5 :
	add bh, 0x01
	dec eax
	jmp printf2
printf_end1:
	ret
	
print_cs_LDT0_Start:
	pushad
	mov eax, CS_LDT0_Start
	mov edi, 80*2*15+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*15+2*27					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
	
print_cs_Protected:
	pushad
	mov eax, CS_Protected_Start
	mov edi, 80*2*14+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*14+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
print_cs_in_stack:
	pushad
	mov eax, CS_in_stack
	mov edi, 80*2*20+0
	mov bl, 0x02
	call printf_s
	mov eax, [esp+40]
	mov [temp], eax
	mov eax, temp	
	mov edi, 80*2*20+2*27
	mov bl, 0x04
	call printf_n
	popad
	ret
print_cs_LDT0_Next:
	pushad
	mov eax, CS_LDT0_Next
	mov edi, 80*2*16+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*16+2*27					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
print_cs_LDT1_Start:
	pushad
	mov eax, CS_LDT1_Start
	mov edi, 80*2*17+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*17+2*27					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
;---------------------------------------------------------------------

;----------------------Global Description Table-----------------------
;[SECTION .data]
;null descriptor. gdt_ptr could be put here to save a few
gdt:
	dw	0			
	dw	0			
	db	0			
	db	0			
	db	0			
	db	0			
SYS_CODE_SEL equ	08h
gdt1:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	9Ah			
	db	0cfh		
	db	0			
SYS_DATA_SEL equ	10h
gdt2:
	dw	0FFFFh		
	dw	00000h					
	db	0			
	db	92h			
	db	0cfh		
	db	0			
Video_SEL	equ	18h				
gdt3:
	dw	0FFFFh		
	dw	08000h					
	db	0Bh			
	db	92h			
	db	40h			
	db	00h			
;-------------------------write your code here---------------------------
; LDTR descriptors for two LDTs                                         ;
;																        ;	

; base addresses and limits of LDTRs in GDT must be defined in upper code blocks.
;LDTR1 descriptor (for LDT1)
LDTR1		 equ	20h
gdt4:
	; idx:4
	dw	0h			; limit 15:0			; temporary set 0
	dw	0h			; base 15:0				; temporary set 0
	db	0h			; base 23:16			; temporary set 0
	db	82h			; flags, type
	db	00h			; limit 19:16, flags	; temporary set 0
	db	0h			; base 31:24			; temporary set 0
	
;LDTR2 descriptor (for LDT1)
LDTR2		 equ	28h
gdt5:
	; idx:4
	dw	0h			; limit 15:0			; temporary set 0
	dw	0h			; base 15:0				; temporary set 0
	db	0h			; base 23:16			; temporary set 0
	db	82h			; flags, type
	db	00h			; limit 19:16, flags	; temporary set 0
	db	0h			; base 31:24			; temporary set 0
;																        ;	
;																        ;	
;------------------------------------------------------------------------		
gdt_end:

gdt_ptr:
		dw			gdt_end - gdt - 1	
		dd			gdt		
;-------------------------Local Descriptor Table-------------------------
;-------------------------write your code here---------------------------
; Make Local Descriptor Tables.									        ;
; Fill Code Segment Descriptors and Data Segment Descriptors	        ;	
;																        ;

ldt:
;Code Segment Descriptor										  ;
LDT_CODE_SEL_0	equ		00h
	; idx:0
	dw	00FFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	9Ah			; flags, type
	db	0C0h		; limit 19:16, flags
	db	00h			; base 31:24
;Data Segment Descriptor										  ;
LDT_DATA_SEL_0	equ		08h
	; idx:1
	dw	00FFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	92h			; flags, type
	db	0C0h		; limit 19:16, flags
	db	00h			; base 31:24	
;Code Segment Descriptor										  ;
LDT_CODE_SEL_1	equ		10h
	; idx:0
	dw	00FFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	9Ah			; flags, type
	db	0C0h		; limit 19:16, flags
	db	00h			; base 31:24

ldt2:
;Data Segment Descriptor										  ;
LDT_DATA_SEL_1	equ		18h
	; idx:1
	dw	00FFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	92h			; flags, type
	db	0C0h		; limit 19:16, flags
	db	00h			; base 31:24
;Code Segment Descriptor										  ;
LDT_CODE_SEL_2	equ		20h
	; idx:0
	dw	00FFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	9Ah			; flags, type
	db	0C0h		; limit 19:16, flags
	db	00h			; base 31:24
	
ldt_end:
;																        ;	
;																        ;	
;------------------------------------------------------------------------
sector_end:

