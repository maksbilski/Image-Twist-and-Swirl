section .data
double_two          dq 2.0
double_onehalf      dq 1.5
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
        movsd       xmm6, qword [pi]
        subsd       xmm6, xmm1

        jmp         original_angle_computed

rel_x_is_grt_than_zero:
        ucomisd     xmm4, xmm1
; (relX > 0 && relY > 0) we don't do nothing
        jge         original_angle_computed

; (relX > 0 && relY < 0)
        movsd       xmm1, xmm6
        movsd       xmm6, qword[pi]
        mulsd       xmm6, qword[dtwo]
        subsd       xmm6, xmm1
        jmp         original_angle_computed

; (relX <=0 && relY <0)
rel_y_is_less_than_zero:
        addsd       xmm6, qword [pi]

original_angle_computed:




finish:

swirl_epilogue:
        pop         r15
        pop         r14
        pop         r13
        pop         r12
        pop         rbx
        mov         rsp, rbp
        pop         rbp
        ret
