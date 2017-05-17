[org 0x7c00]		; Assembly command
					; Let NASM compiler know starting address of memory
					; BIOS reads 1st sector and copied it on memory address 0x7c00
[bits 16] 			; Assembly command
					; Let NASM compiler know that this code consists of 16its

[SECTION .text] 	; Text section

START:				; Boot loader(1st sector) starts
    cli				; Clear interrupt
    xor ax, ax		; Initialize ax register
	mov ax, 0x8FF
	mov ds, ax		; Set data segment register
	mov bx, 0x00
	mov al, 0x01

;-----------Following code is for filling some values in the memory-------------;

mem:																		
	mov byte [ds:bx], al
	cmp bx, 0xFF
	je test_end
	jmp re

re:
	add al, 0x02
	add bx, 0x01
	jmp mem
	
test_end:
	cli
	xor ax, ax
	mov ds, ax
    mov ax, 0xB800
    mov es, ax 
	
;-------------------------------------------------------------------------------;

	sti						; Set interrupt
	
    call load_sectors 		; Load rest sectors
    jmp sector_2

load_sectors:			 	; Read and copy the rest sectors of disk

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

times   510-($-$$) db 0 		; $ : current address, $$ : start address of SECTION
								; $-$$ means the size of source
dw      0xAA55 					; signature bytes
								; End of Master Boot Record(1st Sector)
								
		

sector_2:						; Program Starts
	mov ax, 0x8FF
	mov ss, ax
	mov sp, 0x10
	mov ax, 0x4246
	push ax

	; what is this (below)?
;	mov bx, 0x8FFC
;	mov dl, byte [ds:bx]
;	add ah, dl
;	xchg al, bh
;	mov bx, 0x8FFD
;	mov word[ds:bx], ax
;	sub al, ah
;	mov bx, 0x8FFF
;	mov byte[ds:bx], al

	
;-------------------------Write your code here----------------------------------;	
; Print your Name in VMware screen											    ;
; Print your ID in VMware screen											    ;
; Print the value(word size) in the Stack Pointer after executing the above code;

	; 'A program prints some informations' by Yoseob Kim(2015312229)
	; SKKU Microprocessor x86-HW1, 2017-05-17
	
	; print ID		
	mov esi, ID
	mov edi, 0x1E0
	
IDloop:	
	movsb
	mov byte [es:edi], 0x1f
	inc edi
	cmp esi, ID+0xF
	jne IDloop

	; print NAME in English (Unicode support??)
	mov esi, NAMEE
	mov edi, 0x280

NAMEloop:
	movsb
	mov byte [es:edi], 0x2f
	inc edi
	cmp esi, NAMEE+0x11
	jne NAMEloop

	; print Answer - the value in the stack pointer
	mov esi, Answer
	mov edi, 0x3C0

Answerloop:
	movsb
	mov byte [es:edi], 0x4f
	inc edi
	cmp esi, Answer+0x26
	jne Answerloop


	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ;
	; !!! get the value of stack pointer !!! ;
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ;

	; My solution: transform each hexadecimal number to ascii character.
	; ex. 1234H --> 1 goes to '1', 2 goes to '2', 3 goes to '3', 4 goes to '4' respectively.

	mov bp, sp	; direct usage of sp is not allowed in NASM.
	mov word ax, [ss:bp]
	
;	mov bx, cx
;	add bh, 0x30
;	mov byte [es:0x500], bh ; --> B, 12

;	add bl, 0x30
;	mov byte [es:0x502], bl ; --> d, 34

;	mov bx, 0x0

	; bit 15 ~ 12
	mov bh, ah
	shr bh, 4

	cmp bh, 0xA
	jl	l1_9
	jge l1_A
	aaa
l1_9:
	add bh, 0x30
	jmp l1
l1_A:
	add bh, 0x37
l1:
	mov byte [es:edi], bh
	inc edi
	mov byte [es:edi], 0x5f
	inc edi

	; bit 11 ~ 8
	mov word ax, [ss:bp]	; bring stack pointer value each time.
	mov bh, ah
	and bh, 0x0F
	aaa
	add bh, 0x30
	mov byte [es:edi], bh
	inc edi
	mov byte [es:edi], 0x5f
	inc edi

	; bit 7 ~ 4
	mov word ax, [ss:bp]
	mov bl, al
	shr bl, 4
	aaa
	add bl, 0x30
	mov byte [es:edi], bl
	inc edi
	mov byte [es:edi], 0x5f
	inc edi

	; bit 3 ~ 0
	mov word ax, [ss:bp]
	mov bl, al
	and bl, 0x0F
	aaa
	add bl, 0x30
	mov byte [es:edi], bl
	inc edi
	mov byte [es:edi], 0x5f
	inc edi

	; Important thing is,
	; be careful of using ax, bx, cx, dx (core registers) to store any values.
	; if doing some operation like 'add', the value of core register would be changed.
	; if using core register without awareness, the exactly same problem occurs as in ARM-HW1.
	; (core register value "twisting" problem)
;																				;
;																				;
;																				;
;																				;
;																				;
;-------------------------------------------------------------------------------;



;---------------------- Write your Name and ID here-----------------------------;

ID  db 'ID : 2015312229',0
NAMEE db 'NAME : Yoseob Kim',0
Answer db 'A value in Stack Pointer(word size) : ',0

;-------------------------------------------------------------------------------;
	
sector_end:

