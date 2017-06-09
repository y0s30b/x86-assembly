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
	mov cr0, eax			; Switch Real mode to Protected mode	

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
	mov esp, 0x9000
	
	mov ax, Video_SEL
	mov es, ax
	
	mov eax, MSG_Protected_MODE_Test
	mov edi, 80*2*1+2*0
	mov bl, 0x02
	call printf
	
;code your program----------------------------------------------------------------------------------------	

; load idt
; set offset of Interrupt Descriptor



;----------------------------------------------------------------------------------------------------------

	; put base of tss1 on gdt4
	mov eax, tss1
    mov word [gdt4+2], ax
    shr eax, 16
    mov byte [gdt4+4], al
    mov byte [gdt4+7], ah
		
	; put base of tss2 on gdt6	
	mov eax, tss2
    mov word [gdt6+2], ax
    shr eax, 16
    mov byte [gdt6+4], al
    mov byte [gdt6+7], ah
	
	; set tss2 register value
	mov word [tss2+76], SYS_EXT_SEL
    mov word [tss2+84], SYS_DATA_SEL
    mov word [tss2+80], SYS_DATA_SEL
    mov word [tss2+72], Video_SEL
    mov dword [tss2+32], task2
    mov dword [tss2+56], esp

	mov ax, TSS1Selector
	ltr ax					; load TSS1Selector to TR			
	
	
task1:
	mov 	eax, 0x0
	mov 	ebx, 0x1
	mov 	ecx, 0x2
	mov 	edx, 0x3

	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	
	call print_reg_1	
	
	jmp $		; this is ending point of program
				; when you complete the code, this line must be deactive 
	
	;Use IDT for switching task2 
	
	call print_reg_3
	
	; print "Task2 switched from Task1"	
	
	xor edx, edx
	mov eax, 10
	mov ebx, 0
	div ebx
	
return:
	call print_reg_5
	
	; print "Task1 switched BACK from IRQ"
	
	;jmp $					; this is ending point of program
							; when return from IRQ, this line must be active to end program
		
task2:
	; print "Task2 switched from Task1"
	; return to task1
	
	mov eax, [esp-16]
	mov ebx, [esp-8]
	mov ecx, [esp-12]
	mov edx, [esp-12]
	add edx, eax
	mov [esp-16], edx 
	
	call print_reg_2

irq_00:						
	call print_reg_4

; print "Divided by Zero"
; Do not forget use push/pop (all and flags) for storing register values
; return to task1, return label	


	
MSG_Protected_MODE_Test: db'Protected Mode',0
Task2_Start: db'Task2 switched from Task1',0
Task2_Back: db'Task1 switched BACK from Task2',0
IRQ_Back: db'Task1 switched BACK from IRQ',0
MSG_irq00h: db 'Divided by Zero',0
temp: dd 0
;-------------------------------------------------------------
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
	

print_reg_esp_1:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov eax, esp
	add eax, 0x18
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_esp_2:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov eax, esp
	add eax, 0x18
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_esp_3:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov eax, esp
	add eax, 0x18
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_esp_4:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov eax, esp
	add eax, 0x18
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_esp_5:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov eax, esp
	add eax, 0x18
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	
print_reg_eax_1:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_eax_2:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_eax_3:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_eax_4:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_eax_5:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	
print_reg_ebx_1:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ebx
	mov eax, temp
	mov edi, 80*2*17+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ebx_2:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ebx
	mov eax, temp
	mov edi, 80*2*17+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ebx_3:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ebx
	mov eax, temp
	mov edi, 80*2*17+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ebx_4:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ebx
	mov eax, temp
	mov edi, 80*2*17+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ebx_5:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ebx
	mov eax, temp
	mov edi, 80*2*17+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	
print_reg_ecx_1:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ecx
	mov eax, temp
	mov edi, 80*2*18+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ecx_2:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ecx
	mov eax, temp
	mov edi, 80*2*18+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ecx_3:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ecx
	mov eax, temp
	mov edi, 80*2*18+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ecx_4:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ecx
	mov eax, temp
	mov edi, 80*2*18+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_ecx_5:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], ecx
	mov eax, temp
	mov edi, 80*2*18+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	
print_reg_edx_1:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], edx
	mov eax, temp
	mov edi, 80*2*19+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_edx_2:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], edx
	mov eax, temp
	mov edi, 80*2*19+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_edx_3:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], edx
	mov eax, temp
	mov edi, 80*2*19+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_edx_4:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], edx
	mov eax, temp
	mov edi, 80*2*19+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_edx_5:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], edx
	mov eax, temp
	mov edi, 80*2*19+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret	
	
print_reg_cs_1:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*21+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_cs_2:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*21+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_cs_3:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*21+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_cs_4:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*21+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_cs_5:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*21+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	
print_reg_eflags_1:
	pushfd
	push eax
	push ebx
	push ecx
	push edx
	mov eax, [esp+16]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	popfd
	ret
print_reg_eflags_2:
	pushfd
	push eax
	push ebx
	push ecx
	push edx
	mov eax, [esp+16]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	popfd
	ret
print_reg_eflags_3:
	pushfd
	push eax
	push ebx
	push ecx
	push edx
	mov eax, [esp+16]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	popfd
	ret
print_reg_eflags_4:
	pushfd
	push eax
	push ebx
	push ecx
	push edx
	mov eax, [esp+16]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	popfd
	ret
print_reg_eflags_5:
	pushfd
	push eax
	push ebx
	push ecx
	push edx
	mov eax, [esp+16]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	popfd
	ret	
	
print_reg_es_1:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], es
	mov eax, temp
	mov edi, 80*2*20+2*0					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_es_2:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], es
	mov eax, temp
	mov edi, 80*2*20+2*10					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_es_3:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], es
	mov eax, temp
	mov edi, 80*2*20+2*20					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_es_4:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], es
	mov eax, temp
	mov edi, 80*2*20+2*30					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
print_reg_es_5:
	push 	eax    
	push	ebx
	push 	ecx
	push 	edx
	mov [temp], es
	mov eax, temp
	mov edi, 80*2*20+2*40					
	mov bl, 0x02
	call printf1
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	
print_reg_1:
	call print_reg_eflags_1
	call print_reg_esp_1
	call print_reg_eax_1
	call print_reg_ebx_1
	call print_reg_ecx_1
	call print_reg_edx_1
	call print_reg_cs_1
	call print_reg_es_1
	ret
print_reg_2:
	call print_reg_eflags_2
	call print_reg_esp_2
	call print_reg_eax_2
	call print_reg_ebx_2
	call print_reg_ecx_2
	call print_reg_edx_2
	call print_reg_cs_2
	call print_reg_es_2
	ret
	
print_reg_3:
	call print_reg_eflags_3
	call print_reg_esp_3
	call print_reg_eax_3
	call print_reg_ebx_3
	call print_reg_ecx_3
	call print_reg_edx_3
	call print_reg_cs_3
	call print_reg_es_3
	ret

print_reg_4:
	call print_reg_eflags_4
	call print_reg_esp_4
	call print_reg_eax_4
	call print_reg_ebx_4
	call print_reg_ecx_4
	call print_reg_edx_4
	call print_reg_cs_4
	call print_reg_es_4
	ret	

print_reg_5:
	call print_reg_eflags_5
	call print_reg_esp_5
	call print_reg_eax_5
	call print_reg_ebx_5
	call print_reg_ecx_5
	call print_reg_edx_5
	call print_reg_cs_5
	call print_reg_es_5
	ret		
	
;---------------------------tss----------------------------
tss1:
	dw 0, 0                     ; back link to previous task
	dd 0                        ; ESP0
	dw 0, 0                    	; SS0, not used here
	dd 0                        ; ESP1
	dw 0, 0                    	; SS1, not used here
	dd 0                        ; ESP2
	dw 0, 0                   	; SS2, not used here
	dd 0						; CR3
tss1_EIP:
	dd 0						; EIP
	dd 0						; EFLAGS
	dd 0, 0, 0, 0          		; EAX, ECX, EDX, EBX
tss1_ESP:
	dd 0						; ESP
	dd 0						; EBP
	dd 0						; ESI
	dd 0						; EDI
	dw 0, 0                    	; ES, not used here
	dw 0, 0                    	; CS, not used here
	dw 0, 0                    	; SS, not used here
	dw 0, 0                    	; DS, not used here
	dw 0, 0                    	; FS, not used here
	dw 0, 0                    	; GS, not used here
	dw 0, 0                    	; LDT, not used here
	dw 0, 0                    	; T bit for debugging

tss2:
	dw 0, 0                     ; back link to previous task
	dd 0                        ; ESP0
	dw 0, 0                    	; SS0, not used here
	dd 0                        ; ESP1
	dw 0, 0                    	; SS1, not used here
	dd 0                        ; ESP2
	dw 0, 0                   	; SS2, not used here
	dd 0						; CR3
tss2_EIP:
	dd 0						; EIP
	dd 0						; EFLAGS
	dd 0, 0, 0, 0          		; EAX, ECX, EDX, EBX
tss2_ESP:
	dd 0						; ESP
	dd 0						; EBP
	dd 0						; ESI
	dd 0						; EDI
	dw 0, 0                    	; ES, not used here
	dw 0, 0                    	; CS, not used here
	dw 0, 0                    	; SS, not used here
	dw 0, 0                    	; DS, not used here
	dw 0, 0                    	; FS, not used here
	dw 0, 0                    	; GS, not used here
	dw 0, 0                    	; LDT, not used here
	dw 0, 0                    	; T bit for debugging

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
; ring0 tss Descriptor
TSS1Selector	equ		20h					
gdt4:
	dw	068h	; Segment Limit 15:0
	dw	0000h	; Base Address 15:0
	db	00h		; Base Address 23:16
	db	89h		; present, ring 0, system, 32-bit TSS Type	
	db	40h		; limit 19:16, flags
	db	00h		; Base Address 31:24
;Code Segment Descriptor
SYS_EXT_SEL    equ	28h
gdt5:
	dw	0FFFFh	; limit 15:0
	dw	00000h	; base 15:0				
	db	0		; base 23:16
	db	9Ah		; present, ring 0, code, non-conforming, readable
	db	0cfh	; limit 19:16, flags
	db	0		; base 31:24
; ring0 tss Descriptor
TSS2Selector	equ		30h					
gdt6:
	dw	068h	; Segment Limit 15:0
	dw	0000h	; Base Address 15:0
	db	00h		; Base Address 23:16
	db	89h		; present, ring 0, system, 32-bit TSS Type													
	db	40h		; limit 19:16, flags
	db	00h		; Base Address 31:24

gdt_end:

gdt_ptr:
	dw	gdt_end - gdt - 1	; GDT limit
	dd	gdt		; linear addr of GDT (set above)
;-----------------------------------------------------------------------------------------------------	
	
;--------------------------------------------------------------------------------------------------------
; Make Interrupt Descriptor Table
















sector_end:

