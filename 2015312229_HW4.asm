; SKKU Microprocessor HW4 of x86, by Yoseob Kim(2015312229)
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
    	mov ss, ax
    	mov sp, 0x9000 		; stack pointer 0x9000
    	mov ax, 0xB800
    	mov es, ax 			; memory address of printing on screen

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

times   510-($-$$) db 0 		; $ : current address, $$ : start address of SECTION
								; $-$$ means the size of source
dw      0xAA55 					; signature bytes
								; End of Master Boot Record(1st Sector)
				
sector_2:						; Program Starts
	cli		
	lgdt	[gdt_ptr]			; Load GDT	
	
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax		; Switch Real mode to Protected mode	
	
	jmp SYS_CODE_SEL:Protected_START	; jump Protected_START
											; Remove prefetch queue
Protected_START:
[bits 32]

	mov ax, SYS_DATA_SEL
	mov ds, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax
	mov es, ax
	mov esp, 0xA000
	
	mov ax, Video_SEL
	mov es, ax	
	mov eax, MSG_Protected_MODE_Test
	mov edi, 80*2*1+2*0
	mov bl, 0x02
	call printf
	
	mov eax, Busy_Flag
	mov edi, 80*2*9+2*0
	mov bl, 0x02
	call printf	

	mov eax, Registers
	mov edi, 80*2*17+2*0
	mov bl, 0x02
	call printf
	
	mov eax, TSS
	mov edi, 80*2*14+2*50
	mov bl, 0x02
	call printf		
	
	call print_busy1_init
	call print_busy2_init
	call print_busy3_init

;------------------------------------------------------------------------------------	
; Base of TSS descriptors and LDTR descriptors										;

	; ldt1 setting (base address)
	mov eax, ldt1
	mov word [gdt+LDTR1+2h], ax
	; base 23:16 of the start address of ldt
	shr eax, 16
	mov byte [gdt+LDTR1+4h], al
	; base 31:24 of the start address of ldt
	mov eax, ldt1
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

	; ldt3 setting (base address)
	mov eax, ldt3
	mov word [gdt+LDTR3+2h], ax
	; base 23:16 of the start address of ldt
	shr eax, 16
	mov byte [gdt+LDTR3+4h], al
	; base 31:24 of the start address of ldt
	mov eax, ldt3
	shr eax, 24
	mov byte [gdt+LDTR3+7h], al

	; limit setting (ldt1)
	mov ax, ldt2 - ldt1 - 1
	mov word [gdt+LDTR1], ax

	; limit setting (ldt2)
	mov ax, ldt3 - ldt2 - 1
	mov word [gdt+LDTR2], ax

	; limit setting (ldt3)
	mov ax, ldt_end - ldt3 - 1
	mov word [gdt+LDTR3], ax

; Initialize three TSS fields		
	; tss1												;
	mov ax, LDTR1			; LDT Segment Selector
	mov word [tss1+96h], ax

	mov ax, LDT_CODE_SEL1	; CS
	mov word [tss1+76h], ax

	mov ax, LDT_DATA_SEL1	; DS
	mov word [tss1+84h], ax
	
	mov ax, LDT_DATA_SEL1	; SS
	mov word [tss1+80h], ax

	mov ax, Video_SEL		; ES
	mov word [tss1+72h], ax

	mov ax, Task1			; EIP
	mov word [tss1+32h], ax

	mov ax, 0xA000			; ESP
	mov word [tss1+56h], ax

	; tss2
	mov ax, LDTR2			; LDT Segment Selector
	mov word [tss2+96h], ax

	mov ax, LDT_CODE_SEL2	; CS
	mov word [tss2+76h], ax

	mov ax, LDT_DATA_SEL2	; DS
	mov word [tss2+84h], ax
	
	mov ax, LDT_DATA_SEL2	; SS
	mov word [tss2+80h], ax

	mov ax, Video_SEL		; ES
	mov word [tss2+72h], ax

	mov ax, Task2			; EIP
	mov word [tss2+32h], ax

	mov ax, 0xB000			; ESP
	mov word [tss2+56h], ax

	; tss3
	mov ax, LDTR3			; LDT Segment Selector
	mov word [tss3+96h], ax

	mov ax, LDT_CODE_SEL3_0	; CS
	mov word [tss3+76h], ax

	mov ax, LDT_DATA_SEL3	; DS
	mov word [tss3+84h], ax
	
	mov ax, LDT_DATA_SEL3	; SS
	mov word [tss3+80h], ax

	mov ax, Video_SEL		; ES
	mov word [tss3+72h], ax

	mov ax, Task3			; EIP
	mov word [tss3+32h], ax

	mov ax, 0xC000			; ESP
	mov word [tss3+56h], ax
; Switch to Task1																	;

;										 											;
;------------------------------------------------------------------------------------	

Task1:
	call print_busy1_task
	call print_reg_1

; print "Task1 switched"

	mov eax, 0x0A
	mov ebx, 0x0B
	cmp eax, ebx

; call Task2 

	
; print "Task1 switched BACK from Task2"	
	
	call print_tss1_store
	call print_tss2_store
	call print_tss3_store
	call print_busy1_end
	call print_busy2_end
	call print_busy3_end
	
	;jmp $					; this is ending point of program
							; when switched back from task2, this line must be active to end program
	
	
	
Task2:

	call print_reg_2
	call print_busy2_task
	
; print "Task2 switched from Task1"
	
	mov eax, 0x0A
	push eax
	mov ebx, 0x0B
	push ebx
	mov ecx, 0x0C
	push ecx

; call Task3 using Task Gate
	
; print "Task2 switched BACK from Task3"

; return to Task1

Task3:

	call print_reg_3
	call print_busy3_task
	
; print "Task3 Switched from Task2"
	
; control transfer
	
Task3_next:

; print "Jumped to Task3_Next with LDT_CODE_SEL3_1"
	
; return to Task2

	jmp $		; this is ending point of program
				; when you make the task switching code, this line must be deactive 
				
;------------------------------------------------------------------------------------------

	
;------------------------------------------------------------------------------------------

MSG_Protected_MODE_Test: db'Protected Mode',0
Task1_Start: db'Task1 switched',0
Task2_Start: db'Task2 switched from Task1',0
Task3_Start: db'Task3 switched from Task2',0
Task2_Back: db'Task2 switched BACK from Task3',0
Task1_Back: db'Task1 switched BACK from Task2',0
Busy_Flag: db'***** Busy Flag *****',0
Registers: db'*** ESP, CS, DS, EFLAGS ***',0
TSS: db'*** TSS1, TSS2, TSS3 ***',0
MSG_TASK3_Next: db'Jumped to Task3_Next with LDT_CODE_SEL3_1',0
temp: dd 0

printf:
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
	jmp printf	

printf_end:
	ret
	
printf1:
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


	
;--------------------------------------------------------------------------------------------

print_busy1_init:
	pushad
	pushfd
	mov eax, [gdt4+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*10+0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_busy2_init:
	pushad
	pushfd
	mov eax, [gdt5+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*11+0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret		
print_busy3_init:
	pushad
	pushfd
	mov eax, [gdt6+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*12+0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_busy1_task:
	pushad
	pushfd
	mov eax, [gdt4+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*10+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_busy2_task:
	pushad
	pushfd
	mov eax, [gdt5+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*11+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret		
print_busy3_task:
	pushad
	pushfd
	mov eax, [gdt6+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*12+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_busy1_end:
	pushad
	pushfd
	mov eax, [gdt4+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*10+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_busy2_end:
	pushad
	pushfd
	mov eax, [gdt5+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*11+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret		
print_busy3_end:
	pushad
	pushfd
	mov eax, [gdt6+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*12+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
;--------------------------------------------------------------------------------	

print_reg_esp_1:
	pushad
	pushfd
	mov eax, esp
	add eax, 0x28
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_cs_1:
	pushad
	pushfd
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*19+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	

print_reg_ds_1:
	pushad
	pushfd
	mov [temp], ds
	mov eax, temp
	mov edi, 80*2*20+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_reg_eflags_1:
	pushad
	pushfd
	mov eax, [esp]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_1:
	call print_reg_esp_1
	call print_reg_cs_1
	call print_reg_ds_1
	call print_reg_eflags_1
	ret
	
print_reg_esp_2:
	pushad
	pushfd
	mov eax, esp
	add eax, 0x28
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_cs_2:
	pushad
	pushfd
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*19+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	

print_reg_ds_2:
	pushad
	pushfd
	mov [temp], ds
	mov eax, temp
	mov edi, 80*2*20+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_reg_eflags_2:
	pushad
	pushfd
	mov eax, [esp]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_2:
	call print_reg_esp_2
	call print_reg_cs_2
	call print_reg_ds_2
	call print_reg_eflags_2
	ret
	
print_reg_esp_3:
	pushad
	pushfd
	mov eax, esp
	add eax, 0x28
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_cs_3:
	pushad
	pushfd
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*19+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	

print_reg_ds_3:
	pushad
	pushfd
	mov [temp], ds
	mov eax, temp
	mov edi, 80*2*20+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_reg_eflags_3:
	pushad
	pushfd
	mov eax, [esp]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_3:
	call print_reg_esp_3
	call print_reg_cs_3
	call print_reg_ds_3
	call print_reg_eflags_3
	ret
	
;----------------------------------------------------------------------------------------

print_tss1_store:
	pushad
	pushfd
	mov eax, [tss1+96]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*50					
	mov bl, 0x02
	call printf1

	
	mov eax, [tss1+84]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1+76]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*17+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1+72]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*50					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss1+56]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*19+2*50					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss1+36]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*20+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1+32]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*50					
	mov bl, 0x02
	call printf1
	
	popfd
	popad
	ret
	
	
print_tss2_store:
	pushad
	pushfd
	mov eax, [tss2+96]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*60					
	mov bl, 0x02
	call printf1

	
	mov eax, [tss2+84]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2+76]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*17+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2+72]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*60					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss2+56]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*19+2*60					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss2+36]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*20+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2+32]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*60					
	mov bl, 0x02
	call printf1
	
	popfd
	popad
	ret
	
	
print_tss3_store:
	pushad
	pushfd
	mov eax, [tss3+96]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*70					
	mov bl, 0x02
	call printf1

	
	mov eax, [tss3+84]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3+76]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*17+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3+72]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*70					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss3+56]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*19+2*70					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss3+36]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*20+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3+32]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*70					
	mov bl, 0x02
	call printf1
	
	popfd
	popad
	ret
;--------------------------------------------------------------------------------	

print_register:
	pushad
	pushfd
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*1+2*60					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
;----------------------------------tss-----------------------------------
;-------------------------write your code here---------------------------
; Make 3 TSS field														;
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------
tss1 :
	dw 0	; Previous Task Link
	dw 0
	dd 0	; ESP0
	dw 0	; SS0
	dw 0
	dd 0	; ESP1
	dw 0	; SS1
	dw 0
	dd 0	; ESP2
	dw 0	; SS2
	dw 0
	dd 0	; CR3
	dd 0	; EIP
	dd 0	; EFLAGS
	dd 0	; EAX
	dd 0	; ECX
	dd 0	; EDX
	dd 0	; EBX
	dd 0	; ESP
	dd 0	; EBP
	dd 0	; ESI
	dd 0	; EDI
	dw 0	; ES
	dw 0
	dw 0	; CS
	dw 0
	dw 0	; SS
	dw 0
	dw 0	; DS
	dw 0
	dw 0	; FS
	dw 0
	dw 0	; GS
	dw 0
	dw 0	; LDT Segment Selector
	dw 0
	dw 0
	dw 0	; I/O Map Base Address

tss2 :
	dw 0	; Previous Task Link
	dw 0
	dd 0	; ESP0
	dw 0	; SS0
	dw 0
	dd 0	; ESP1
	dw 0	; SS1
	dw 0
	dd 0	; ESP2
	dw 0	; SS2
	dw 0
	dd 0	; CR3
	dd 0	; EIP
	dd 0	; EFLAGS
	dd 0	; EAX
	dd 0	; ECX
	dd 0	; EDX
	dd 0	; EBX
	dd 0	; ESP
	dd 0	; EBP
	dd 0	; ESI
	dd 0	; EDI
	dw 0	; ES
	dw 0
	dw 0	; CS
	dw 0
	dw 0	; SS
	dw 0
	dw 0	; DS
	dw 0
	dw 0	; FS
	dw 0
	dw 0	; GS
	dw 0
	dw 0	; LDT Segment Selector
	dw 0
	dw 0
	dw 0	; I/O Map Base Address

tss3 :
	dw 0	; Previous Task Link
	dw 0
	dd 0	; ESP0
	dw 0	; SS0
	dw 0
	dd 0	; ESP1
	dw 0	; SS1
	dw 0
	dd 0	; ESP2
	dw 0	; SS2
	dw 0
	dd 0	; CR3
	dd 0	; EIP
	dd 0	; EFLAGS
	dd 0	; EAX
	dd 0	; ECX
	dd 0	; EDX
	dd 0	; EBX
	dd 0	; ESP
	dd 0	; EBP
	dd 0	; ESI
	dd 0	; EDI
	dw 0	; ES
	dw 0
	dw 0	; CS
	dw 0
	dw 0	; SS
	dw 0
	dw 0	; DS
	dw 0
	dw 0	; FS
	dw 0
	dw 0	; GS
	dw 0
	dw 0	; LDT Segment Selector
	dw 0
	dw 0
	dw 0	; I/O Map Base Address

tss_end:
;-------------------------Global Descriptor Table------------------------
;null descriptor. gdt_ptr could be put here to save a few
gdt:
	dw	0			; limit 15:0
	dw	0			; base 15:0
	db	0			; base 23:16
	db	0			; type
	db	0			; limit 19:16, flags
	db	0			; base 31:24
;Code Segment Descriptor
SYS_CODE_SEL equ	08h
gdt1:
	dw	0FFFFh		; limit 15:0
	dw	00000h		; base 15:0				
	db	0			; base 23:16
	db	9Ah			; present, ring 0, code, non-conforming, readable
	db	0cfh		; limit 19:16, flags
	db	0			; base 31:24
;Data Segment Descriptor
SYS_DATA_SEL equ	10h
gdt2:
	dw	0FFFFh		; limit 15:0
	dw	00000h		; base 23:16			
	db	0			; base 23:16
	db	92h			; present, ring 0, data, expand-up, writable
	db	0cfh		; limit 19:16, flags
	db	0			; base 31:24
;Video Segment Descriptor
Video_SEL	equ	18h				
gdt3:
	dw	0FFFFh		; limit 15:0
	dw	08000h		; base 23:16			
	db	0Bh			; base 23:16
	db	92h			; present, ring 0, data, expand-up, writable
	db	40h			; limit 19:16, flags
	db	00h			; base 31:24
;-------------------------write your code here---------------------------
; TSS selector for three Task											;
; LDTR descriptors for three LDTs                                       ;
; Task Gate Descriptor for TSS3 selector						        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------

; System Descriptor(TSS Descriptor) 1
TSS1Selector			equ 20h
gdt4:
	dw	0068h	; limit 15:0
	dw	0000h	; base 15:0
	db	00h		; base 23:16
	db	89h		; flags, type
	db	00h		; flags, limit 19:16
	db	00h		; base 31:24
; System Descriptor(TSS Descriptor) 2
TSS2Selector			equ 28h
gdt5:
	dw	0068h	; limit 15:0
	dw	0000h	; base 15:0
	db	00h		; base 23:16
	db	89h		; flags, type
	db	00h		; flags, limit 19:16
	db	00h		; base 31:24
; System Descriptor(TSS Descriptor) 3
TSS3Selector 			equ 30h
gdt6:
	dw	0068h	; limit 15:0
	dw	0000h	; base 15:0
	db	00h		; base 23:16
	db	89h		; flags, type
	db	00h		; flags, limit 19:16
	db	00h		; base 31:24
; System Descriptor(LDT) 1
LDTR1					equ 38h
gdt7:
	dw	0h			; limit 15:0			; temporary set 0
	dw	0h			; base 15:0				; temporary set 0
	db	0h			; base 23:16			; temporary set 0
	db	82h			; flags, type
	db	00h			; limit 19:16, flags	; temporary set 0
	db	0h			; base 31:24			; temporary set 0
; System Descriptor(LDT) 2
LDTR2					equ 40h
gdt8:
	dw	0h			; limit 15:0			; temporary set 0
	dw	0h			; base 15:0				; temporary set 0
	db	0h			; base 23:16			; temporary set 0
	db	82h			; flags, type
	db	00h			; limit 19:16, flags	; temporary set 0
	db	0h			; base 31:24			; temporary set 0
; System Descriptor(LDT) 3
LDTR3					equ 48h
gdt9:
	dw	0h			; limit 15:0			; temporary set 0
	dw	0h			; base 15:0				; temporary set 0
	db	0h			; base 23:16			; temporary set 0
	db	82h			; flags, type
	db	00h			; limit 19:16, flags	; temporary set 0
	db	0h			; base 31:24			; temporary set 0
; System Descriptor(Task Gate)
Task_Gate_Descriptor	equ 50h
gdt10:
	dw	0h
	dw	0h			; TSS Segment Selector - temporary set 0
	db	0h
	db	85h			; flags, type
	db	0h
	db	0h
gdt_end:

gdt_ptr:
	dw	gdt_end - gdt - 1	; GDT limit
	dd	gdt		; linear addr of GDT (set above)
	
;-------------------------Local Descriptor Table-------------------------
;-------------------------write your code here---------------------------
; Make Local Descriptor Tables.									        ;
; Fill Code Segment Descriptors and Data Segment Descriptors	        ;	
;																        ;	
;																        ;
ldt1:
LDT_DATA_SEL1	equ 04h
	; idx:0
	dw	0FFFFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	92h			; flags, type
	db	0CFh		; limit 19:16, flags
	db	00h			; base 31:24
LDT_CODE_SEL1	equ 0Ch
	; idx:1
	dw	0FFFFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	9Ah			; flags, type
	db	0CFh		; limit 19:16, flags
	db	00h			; base 31:24

ldt2:
LDT_DATA_SEL2	equ 04h
	; idx:0
	dw	0FFFFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	92h			; flags, type
	db	0CFh		; limit 19:16, flags
	db	00h			; base 31:24
NULL0			equ 0Ch
	; idx:1
	dw 0
	dw 0
	db 0
	db 0
	db 0
	db 0
LDT_CODE_SEL2	equ 14h
	; idx:2
	dw	0FFFFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	9Ah			; flags, type
	db	0CFh		; limit 19:16, flags
	db	00h			; base 31:24

ldt3:
LDT_DATA_SEL3	equ 04h
	; idx:0
	dw	0FFFFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	92h			; flags, type
	db	0CFh		; limit 19:16, flags
	db	00h			; base 31:24
LDT_CODE_SEL3_0	equ 0Ch
	; idx:1
	dw	0FFFFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	9Ah			; flags, type
	db	0CFh		; limit 19:16, flags
	db	00h			; base 31:24
NULL1			equ 14h
	; idx:2
	dw 0
	dw 0
	db 0
	db 0
	db 0
	db 0
LDT_CODE_SEL3_1	equ 2Ch
	; idx:3
	dw	0FFFFh		; limit 15:0	
	dw	0000h		; base 15:0	
	db	00h			; base 23:16
	db	9Ah			; flags, type
	db	0CFh		; limit 19:16, flags
	db	00h			; base 31:24

ldt_end:

;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------
sector_end: