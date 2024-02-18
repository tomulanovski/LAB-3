
global infile
global outfile
global _start
section .data
    STDOUT EQU 1
    STDERR EQU 2
    newline db 10
    extern strlen
    infile dd 0
    outfile dd 1
    buf db 1 ;; buffer in size 1 for 1 char

section .text

    WRITE EQU 4
    OPEN EQU 5
    CLOSE EQU 6
    READ EQU 3
    EXIT EQU 1

_start:
    call main
    call encoder
        
main:
    push ebp 
    mov  ebp, esp
    mov  edi, [ebp+16] ; argv[1]
    mov  esi, 1 ; counter for arguments

    loop:
    ; loop condition
        cmp esi, dword[ebp+8]
        je end_loop

        mov edx, edi
        cmp byte[edx], '-'
        je redirect_func 
        jmp print_debug 

    redirect_func:
        inc edx             
        cmp byte[edx], 'i'     ; redirect input
        je redirect_input
        cmp byte[edx], 'o'      ; redirect output
        je redirect_output


    redirect_input:
        inc edx  ; will get file name
        mov eax, 5 ; open
        mov ebx, edx
        mov ecx, 0
        mov edx, 0444
        int 0x80
        mov [infile], eax
        jmp print_debug

    redirect_output:
        inc edx  ; file name = edx without 'o'
        mov eax, 5 ;open
        mov ebx, edx
        mov ecx, 0x41
        mov edx, 0777
        int 0x80
        mov [outfile], eax
        jmp print_debug


    print_debug:

        ; Print the current argument to stderr 
        
        push edi            ; save edi to the stack
        call strlen         ; call strlen with argument edi
        mov edx, eax        ; Count of bytes
        mov eax, 4
        mov ebx, STDERR
        mov ecx, edi
        int 0x80            ; Linux system call

        add esp, 4

        ; Print a newline character
        mov eax, 4
        mov ebx, STDERR       ; fd for stderr
        mov ecx, newline      
        mov edx, 1            ; Length of the newline character
        int 0x80              ; Call the kernel

        ; Increment the argument count and the pointer to next arg, and continue the loop
        mov edi, [ebp+16 + 4*esi]
        inc esi
        jmp loop 

        
    end_loop:
        pop ebp
        ret

encoder:
    ;read single byte to buffer from input
    mov eax,3             ;read
    mov ebx, [infile]
    mov ecx, buf          ;store byte in buf
    mov edx, 1            ; number of bytes to read = 1 char
    int 0x80

    ;check if read succeeded
    cmp eax, 1              
    jne exit_program        ;exiting because read failed


    ;check if in range
    cmp byte[buf], 'A'
    jl print_encode      ;jump to print_encode (without encoding) if less than 'A' in ASCII
    cmp byte[buf], 'Z'
    jg check_lower            ;jump to not_upper if greater than 'Z' in ASCII

    ; char is upper- encode
    inc byte[buf] 
    jmp print_encode 

    check_lower:
        cmp byte[buf], 'a'
        jl print_encode       ;less than 'a': no encode
        cmp byte[buf], 'z'
        jg print_encode       ;bigger than 'z': no encode

        ; is lower - encode
        inc byte[buf]           

    print_encode:
        mov eax, 4              ;write
        mov ebx, [outfile]      
        mov ecx, buf
        mov edx, 1
        int 0x80
        jmp encoder



    exit_program:

        ; close input
        mov eax, 6       
        mov ebx, [infile]
        int 0x80
        
        ;close output
        mov eax, 6
        mov ebx, [outfile]
        int 0x80

        mov eax, 1       ; System call number for "exit"
        xor ebx, ebx     ; Exit status code of 0
        int 0x80         ; Call the kernel