default rel

struc XMMCTX_s
    .xmm0 resq 1
    .xmm1 resq 1
    .xmm2 resq 1
    .xmm3 resq 1
    .xmm4 resq 1
    .xmm5 resq 1
    .xmm6 resq 1
    .xmm7 resq 1
    .next resq 1
endstruc

TERM        equ 0x0
BUFSIZ      equ 256


section .rodata
align 16
ABSMASK: 
    dq 0x7FFFFFFFFFFFFFFF
    dq 0x7FFFFFFFFFFFFFFF

SCALE:      dq 1000000.
HEXALPHABET db '0123456789ABCDEF'

section .bss

MXCSR:      resd 1
BUFFER:     resb BUFSIZ
XMMCTX: resb XMMCTX_s


section .text

global showme

;---------------------------------------------------
; Description: showme driver
; Entry:	system V ABI va_args
; Exit:
; Destroy:  rax, rdi, rsi, rdx, rcx, r8, r9, r10, r11
;---------------------------------------------------
showme:
    pop r10         ; saving return address
    mov r11, rsp    ; saving rsp

    push r9         ; arg5
    push r8         ; arg4
    push rcx        ; arg3
    push rdx        ; arg2
    push rsi        ; arg1

    push rbp
    mov rbp, rsp
    add rbp, 8

    push r12
    mov r12, r11

    push rbx
    mov rbx, rdi

    push r13
    lea r13, [XMMCTX]
    movq [r13 + XMMCTX_s.xmm0],  xmm0
    movq [r13 + XMMCTX_s.xmm1],  xmm1
    movq [r13 + XMMCTX_s.xmm2],  xmm2
    movq [r13 + XMMCTX_s.xmm3],  xmm3
    movq [r13 + XMMCTX_s.xmm4],  xmm4
    movq [r13 + XMMCTX_s.xmm5],  xmm5
    movq [r13 + XMMCTX_s.xmm6],  xmm6
    movq [r13 + XMMCTX_s.xmm7],  xmm7
    mov  [r13 + XMMCTX_s.next],  r12

    call showme_parse   ; TODO: inline
    
    pop r13
    pop rbx
    mov r11, r12
    pop r12
    pop rbp

    mov rsp, r11
    push r10
    ret

;---------------------------------------------------
; Description: showme
; Entry:	rbx = format string
;           rbp -> va_args
; Exit:     
; Destroy:  rax, rdi, rsi, rdx, rcx, r8, r9, r11, rbx, rbp
;---------------------------------------------------
showme_parse:
    lea rsi, [BUFFER]

.FormatDecay:

    xor rcx, rcx
    mov cl, [rbx]
    inc rbx

    cmp cl, TERM
    je .ExitSuccess
    cmp cl, '%'
    jne .SkipDecaying
    
    mov cl, [rbx]
    inc rbx

    cmp cl, 'x'
    jg .NoHandle    ; dafault case

    lea rdi, [.FormatDecay]
    push rdi
    lea rdi, [.Trampoline]
    lea rdi, [rdi + (rcx - '%') * 8]
    jmp [rdi]

.Trampoline:
    dq              specsymbHandle
    dq ('b'-'%'-1)  DUP (.NoHandle)
    dq              bitHandle
    dq              asciiHandle
    dq              decHandle
    dq ('f'-'d'-1)  DUP (.NoHandle)
    dq              floatHandle
    dq ('s'-'f'-1)  DUP (.NoHandle)
    dq              szHandle
    dq ('x'-'s'-1)  DUP (.NoHandle)
    dq              hexHandle

.NoHandle:
    mov rdi, BUFSIZ-1
    call flush


    mov byte [rsi], '%'
    mov [rsi+1], cl
    add rsi, 2
    jmp .FormatDecay

.SkipDecaying:

    mov rdi, BUFSIZ
    call flush

    mov [rsi], cl
    inc rsi
    jmp .FormatDecay

.ExitSuccess:
    
    mov rdx, rsi
    lea rdi, [BUFFER]
    sub rdx, rdi
    call force_flush

    ret


;---------------------------------------------------
; Description: flushes string buffer if needed
; Entry:    rsi = buffer current position ptr
;           rdi = free place threshold
; Exit:     rsi = reseted buffer ptr
; Destroy:  rax, rdx
;---------------------------------------------------
flush:
    lea rdx, [BUFFER]
    sub rdx, rsi
    neg rdx
    cmp rdx, rdi
    jl .FlushSkip

    call force_flush

.FlushSkip:
    ret


;---------------------------------------------------
; Description: flushes string buffer
; Entry:    rsi = buffer current position ptr
;           rdx = current buffer len
; Exit:     rsi = reseted buffer ptr
; Destroy:  rax, rdi
;---------------------------------------------------
force_flush:
    cmp rdx, 0
    jle .FlushSkip

    mov rax, 0x1
    mov rdi, 1
    lea rsi, [BUFFER]
    syscall

.FlushSkip:
    ret

;---------------------------------------------------
; Description: adding ascii symbol to the buffer
; Entry:    rsi = buffer current position ptr
;           rbp -> ascii symbol
; Exit:     rsi = buffer current position
;           rbp -> next variadic argument
; Destroy:  rax, rdi, rdx  
;---------------------------------------------------
asciiHandle:
    mov rdi, BUFSIZ
    call flush

    mov al, [rbp]
    add rbp, 8

    mov [rsi], al
    inc rsi

    ret

;---------------------------------------------------
; Description: adding string zero terminated to buffer
; Entry:    rsi = buffer current position ptr
;           rbp -> sz ptr
; Exit:     rsi = buffer current position
;           rbp -> next variadic argument
; Destroy:  rax, rdi, rdx, r8
;---------------------------------------------------
; TODO: relocate regs
szHandle:
    mov r8, [rbp] 
    add rbp, 8

    mov cl, [r8]
    cmp cl, TERM
    je .EOS

    mov rdi, BUFSIZ
.L1:
    call flush

    mov [rsi], cl
    inc rsi
    inc r8
    mov cl, [r8]

    cmp cl, TERM
    jne .L1
.EOS:
    ret

;---------------------------------------------------
; Description: adding SPEC symb into buffer
; Entry:    rsi = buffer current position ptr
; Exit:     rsi = buffer current position
; Destroy:  rax, rdi, rdx
;---------------------------------------------------
specsymbHandle:
    mov rdi, BUFSIZ
    call flush

    mov byte [rsi], '%'
    inc rsi

    ret

;---------------------------------------------------
; Description: converts value into 0xHEX string 
; Entry:    rsi = buffer current position ptr
;           rbp -> hex number
; Exit:     rsi = buffer current position
;           rbp -> next variadic argument
; Destroy:  rax, rdi, rdx, rcx, r11
;---------------------------------------------------
hexHandle:
    mov rdi, BUFSIZ-7
    call flush

    mov edi, [rbp]
    add rbp, 8

    mov eax, 0
    mov ecx, edi
.L1:
    shr ecx, 4
    inc eax
    cmp cl, 0
    jnz .L1

    mov r11, rax
    lea rcx, [HEXALPHABET]
.L2:
    mov edx, edi
    and edx, 0xF
    shr edi, 4
    movzx edx, byte [rcx + rdx]
    mov [rsi + rax - 1], dl
    dec rax
    jne .L2

    add rsi, r11
    ret

;---------------------------------------------------
; Description: converts int to bin string 
; Entry:    rsi = buffer current position ptr
;           rbp -> int value
; Exit:     rsi = buffer current position
;           rbp -> next variadic argument
; Destroy:  rax, rdi, rdx, rcx
;---------------------------------------------------
bitHandle:
    mov rdi, BUFSIZ-31
    call flush

    mov edi, [rbp]
    add rbp, 8

    mov rdx, 33
    mov ecx, edi
.L1:
    rol ecx, 1
    dec rdx
    cmp rdx, 1
    je .L1e
    mov eax, ecx
    and eax, 1
    jz .L1
.L1e:

    mov eax, edx
    mov ecx, edi
.L2:
    shr ecx, 1
    and dil, 1
    or  dil, 0x30
    mov [rsi + rax - 1], dil
    mov edi, ecx
    dec rax
    jne .L2

    add rsi, rdx
    ret

;---------------------------------------------------
; Description: converts int to string 
; Entry:    rsi = buffer current position ptr
;           rbp -> int value
; Exit:     rsi = buffer current position
;           rbp -> next variadic argument
; Destroy:  rax, rdi, rdx, rcx, r8, r9, r11
;---------------------------------------------------
decHandle:
    mov rdi, BUFSIZ-10
    call flush

    mov edi, [rbp]
    add rbp, 8

    mov al, 9
    test edi, edi
    js .TwoComp
    cmp edi, 999999999
    jbe .FindLen
    jmp .Div

.TwoComp:
    mov byte [rsi], '-'
    neg edi
    mov al, 10
    cmp edi, 999999999
    ja .Div

.FindLen:
    mov ecx, 1000000000
    mov edx, 0xCCCCCCCD

.L1:
    imul rcx, rdx
    shr rcx, 35
    dec al
    cmp ecx, edi
    ja .L1
    xor r11, r11
    mov r11, rax
    inc r11
    test edi, edi
    je .DecZero

.Div:
    mov edx, 0xCCCCCCCD

.L2:
    mov ecx, edi
    imul rcx, rdx
    shr rcx, 35
    lea r8d, [rcx + rcx]
    lea r8d, [r8 + 4*r8]
    mov r9d, edi
    sub r9d, r8d

    or r9b, 0x30
    movzx eax, al
    mov byte [rsi + rax], r9b
    dec al
    cmp edi, 9
    mov edi, ecx
    ja .L2

    add rsi, r11
    ret
.DecZero:
    mov byte [rsi], '0'
    inc rsi
    ret

;---------------------------------------------------
; Description: converts float to string 
; Entry:    rsi = buffer current position ptr
;           r13 -> current float in xmm buffer
; Exit:     rsi = buffer current position
;           r13 -> next float in xmm buffer
; Destroy:  rax, rdi, rdx, xmm0, xmm1, xmm2
;---------------------------------------------------
floatHandle:
    mov rdi, BUFSIZ - 31
    call flush

    lea rdi, [MXCSR]
    stmxcsr [rdi]
    mov edx, [rdi]
    mov eax, edx
    and eax, 0x3FFF
    or eax, 0x2000
    mov [rdi], eax
    ldmxcsr [rdi]
    mov [rdi], edx

    lea rax, [XMMCTX + XMMCTX_s.next]
    cmp r13, rax
    jl .RegLoad

    mov rax, [r13]
    cmp rax, rbp
    jg .NextIsRelev

    mov rax, rbp
    add rbp, 8

.NextIsRelev:
    movq xmm0, [rax]
    add rax, 8
    mov [r13], rax
    jmp .Loaded

.RegLoad:
    movq xmm0, [r13]
    add r13, 8
.Loaded:
    xorpd xmm1, xmm1
    ucomisd xmm1, xmm0
    jbe .Positive

    mov byte [rsi], '-'
    inc rsi
    lea rax, [ABSMASK]
    andpd xmm0, [rax]
    
.Positive:
    movsd xmm1, xmm0

    push rbp

    movsd xmm2, xmm1
    roundsd xmm2, xmm2, 3
    subsd xmm1, xmm2
    movsd xmm2, [SCALE]
    mulsd xmm1, xmm2
    cvtsd2si rax, xmm1
    push rax

    cvtsd2si rax, xmm0
    push rax


    mov rbp, rsp
    xor rax, rax
    call decHandle
    mov byte [rsi], '.'
    inc rsi
    call decHandle

    add rsp, 16
    pop rbp

    lea rdi, [MXCSR]
    ldmxcsr [rdi]

    ret