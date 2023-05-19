section .data
double_two          dq 2.0
double_onehalf      dq 1.5
double_one          dq 1.0
double_half         dq 0.5
zero                dq 0.0
absolute_value_mask dq 0x7FFFFFFFFFFFFFFF
double_pi           dq 3.14159265358979323846 ; C_PI


section .text
global  swirl_prologue

; rdi - pixelArraySource
; rsi - pixelArrayCopy
; rdx - width
; rcx - height
; xmm0 - swirlFactor


swirl_prologue:
        push        rbp
        mov         rbp, rsp
        push        xmm6
        push        xmm7
        push        xmm8
        push        xmm9
        push        xmm10
        push        xmm11
        push        xmm12
        push        xmm13
        push        xmm14
        push        xmm15

; for this algorithm these registers are going to contain following values:
; xmm1 - operation register for double precision float values, something like RAX
; xmm2 - width/2 in double
; xmm3 - height/2 in double
; xmm4 - distance from current row to center (height/2)
; xmm5 - distance from current pixel in row to center (width/2)
; xmm6 - original angle value (result of arcus tangens)


swirl:
        cvtsi2sd    xmm1, rdx               ; store width in xmm1
        divsd       xmm1, qword [double_two]
        movsd       xmm2, xmm1              ; now xmm2 contains width/2

        cvtsi2sd    xmm1, rcx               ; store height in xmm1
        divsd       xmm1, qword [double_two]
        movsd       xmm3, xmm1              ; now xmm3 contains height/2

        mov         r8, 0                   ; r8 is the height loop counter

height_loop:
        cvtsi2sd    xmm4, r8                ; convert integer to scalar double-precision floating-point value
        subsd       xmm4, xmm3              ; transform height into UV space

        mov         r9, 0                   ; r9 is the width loop counter

width_loop:
        cvtsi2sd    xmm5, r9                ; convert integer to scalar double-precision floating-point value
        subsd       xmm5, xmm2              ; transform width into UV space, set ZF to 1 if result is 0
        xorpd       xmm1, xmm1              ; xmm1 is equal to zero now

        jnz         rel_x_is_not_zero


finish:

rel_x_is_zero:                              ; special case when rel x is equal to zero
        ucomisd     xmm4, xmm1              ; compare relative Y to zero
        jl          rel_y_below_zero

        mov         xmm6, qword [double_half]
        mulsd       xmm6, qword [double_pi] ; compute original angle (0.5f * C_PI)
        jmp         original_angle_computed

rel_y_below_zero:
        mov         xmm6, qword [double_onehalf]
        mulsd       xmm6, qword [double_pi] ; compute original angle (1.5f * C_PI)
        jmp         original_angle_computed

rel_x_is_not_zero:
        mov         xmm6, xmm4
        andpd       xmm6, qword [absolute_value_mask]

        mov         xmm7, xmm5
        andpd       xmm7, qword [absolute_value_mask]                 ;

        sub         rsp, 16

        movsd       [rsp], xmm6
        movsd       [rsp + 8], xmm7

        fld         qword [rsp]
        fld         qword [rsp + 8]

        fpatan                              ; abs(relY) in ST(0), abs(relX) in ST(1)

        fstp        qword [rsp]

        movsd       xmm6, qword [rsp]

        add         rsp, 16

        ucomisd     xmm5, xmm1

        jg          rel_x_is_grt_than_zero

        ucomisd     xmm4, xmm1

        jl          rel_y_is_less_than_zero

; (relX <= 0 && relY >=0)
        movsd       xmm1, xmm6
        movsd       xmm6, qword [double_pi]
        subsd       xmm6, xmm1

        jmp         original_angle_computed

rel_x_is_grt_than_zero:
        ucomisd     xmm4, xmm1
; (relX > 0 && relY > 0) we don't do nothing
        jge         original_angle_computed

; (relX > 0 && relY < 0)
        movsd       xmm1, xmm6
        movsd       xmm6, qword[double_pi]
        mulsd       xmm6, qword[double_two]
        subsd       xmm6, xmm1
        jmp         original_angle_computed

rel_y_is_less_than_zero:
        addsd       xmm6, qword [double_pi]

original_angle_computed:
        mulsd       xmm4, xmm4              ; relX*relX
        mulsd       xmm5, xmm5              ; relX*relX
        addsd       xmm4, xmm5              ; relX*relX + relY*relY
        sqrtsd      xmm4, xmm4              ; sqrt(relX*relX + relY*relY)

        movsd       xmm5, qword [double_two]
        mulsd       xmm5, xmm5              ; xmm5 now stores 4.0f
        divsd       xmm5, qword [double_pi]        ; 4.0f/C_PI
        mulsd       xmm0, xmm4              ; xmm0 now stores factor*radius
        addsd       xmm0, xmm5              ; xmm0 now stores factor*radius+(4.0f/C_PI)
        movsd       xmm7, qword [double_one]
        divsd       xmm7, xmm0              ; 1/(factor*radius+(4.0f/C_PI))
        addsd       xmm6, xmm7              ; xmm6 now stores originalAngle + 1/(factor*radius+(4.0f/C_PI))

        sub         rsp, 16                 ; decremeant stack pointer so we get free space to work with on the stack
        movsd       [rsp], xmm6             ; push newAngle onto the stack
        fld         qword [rsp]             ; push newAngle onto register stack
        fcos                                ; calculate cos(newAngle), newAngle in ST(0)
        fstp        qword [rsp]             ; push ST(0) onto the stack from the register stack
        movsd       xmm7, qword [rsp]       ; pop cos(newAngle) from stack to xmm7
        add         rsp, 16                 ; increment stack pointer

        mulsd       xmm7, xmm4              ; radius * cos(newAngle)
        roundsd     xmm7, xmm7, 0           ; round srcX to nearest odd or even
        cvttsd2si   r10, xmm7               ; tore the integer valu	srcY = height - srcYo register stack
        fsin                                ; calculate sin(newAngle), newAngle in ST(0)
        fstp        qword [rsp]             ; push ST(0) onto the stack from the register stack            ;
        movsd       xmm7, qword [rsp]       ; pop sin(newAngle) from stack to xmm7
        add         rsp, 16                 ; increment stack pointer

        mulsd       xmm7, xmm4              ; radius * sin(newAngle)
        roundsd     xmm7, xmm7, 0           ; round srcY to nearest odd or even
        cvttsd2si   r11, xmm7               ; store the integer value of srcY in the r11

        cvttsd2si   r12, xmm2               ; convert width/2 to integer
        cvttsd2si   r13, xmm3               ; convert height/2 to integer

        add         r10, r12                ; srcX += cX
        add         r11, r13                ; srcY += cY
        mov         r12, r11
        mov         r11, rcx
        sub         r11, r12                ; srcY = height - srcY

        ; if (srcX < 0) srcX = 0;
        cmp         r10, 0
        jge         srcX_non_negative
        mov         r10, 0
        jmp         srcX_within_width

srcX_non_negative:

        ; else if (srcX >= width) srcX = width - 1;
        cmp         r10, rdx
        jl          srcX_within_width
        mov         r12, rdx
        dec         r12
        mov         r10, r12

srcX_within_width:

        ; if (srcY < 0) srcY = 0;
        cmp         r11, 0
        jge         srcY_non_negative
        mov         r11, 0
        jmp         srcY_within_height
srcY_non_negative:

        ; else if (srcY >= height) srcY = height - 1;
        cmp         r11, rcx
        jl          srcY_within_height
        mov         r13, rcx
        dec         r13
        mov         r11, r13

srcY_within_height:
        ; load 3 bytes from source pixel array
        imul rdx, r11, rdi ; rdx = r11 * rdi
        add rdx, r10       ; rdx = rdx + r10
        movzx eax, word [rdx]
        movzx ecx, byte [rdx + 2]

        ; store 3 bytes to copy pixel array
        imul rdx, r8, rsi  ; rdx = r8 * rsi
        add rdx, r9        ; rdx = rdx + r9
        mov [rdx], ax
        mov byte [rdx + 2], cl

inc_width_loop_counter:
        inc         r9
        cmp         r9, rdx
        jne         width_loop

inc_height_loop_counter:
        inc         r8
        cmp         r8, rcx
        jne         height_loop

swirl_epilogue:
        pop         r15
        pop         r14
        pop         r13
        pop         r12
        pop         rbx
        mov         rsp, rbp
        pop         rbp
        ret
