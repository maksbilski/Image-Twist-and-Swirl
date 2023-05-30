section .data
doubleTwo             dq 2.0
doubleOneHalf         dq 1.5
doubleOne             dq 1.0
doubleHalf            dq 0.5
doubleZero            dq 0.0
absMask               dq 0x7FFFFFFFFFFFFFFF
piConstant            dq 3.14159265358979323846


section .text
global performSwirl

; rdi - pointer to the origin pixel array
; rsi - pointer to the destination pixel array
; rdx - image width
; rcx - image height
; xmm0 - swirl factor

performSwirl:
; xmm1 - temporary register for double precision float values
; xmm2 - image width/2 in double
; xmm3 - image height/2 in double
; xmm4 - Y relative to center
; xmm5 - X relative to center
; xmm6 - original angle value (result of arc tangent)
        push        rbp
        mov         rbp, rsp
        push        r12
        push        r13
        sub         rsp, 16
        movaps      [rsp], xmm6
        sub         rsp, 16
        movaps      [rsp], xmm7
        sub         rsp, 16
        movaps      [rsp], xmm8

        ; Calculate width/2 and height/2
        cvtsi2sd    xmm1, rdx
        divsd       xmm1, qword [rel doubleTwo]
        movsd       xmm2, xmm1
        cvtsi2sd    xmm1, rcx
        divsd       xmm1, qword [rel doubleTwo]
        movsd       xmm3, xmm1

        ; Calculate total pixel count (width * height)
        mov         r9, rcx
        imul        r9, rdx
        mov         r8, 0  ; Pixel index

main_loop:
        ; If we have processed all pixels, exit
        cmp         r8, r9
        je          end_of_swirl

        ; Calculate x and y coordinates of current pixel
        mov         r10, rdx  ; Preserve original width
        mov         rax, r8  ; Current pixel index to rax
        xor         rdx, rdx  ; Clear rdx because rdx:rax is divided
        div         r10  ; Divide pixel index by width. Quotient in rax, remainder in rdx.
        cvtsi2sd    xmm5, rdx  ; Convert X to double and store in xmm5

        ; Compute y coordinate
        mov         rax, r8  ; Pixel index to rax
        xor         rdx, rdx  ; Clear rdx
        div         r10  ; Divide pixel index by width. Quotient in rax, remainder in rdx.
        cvtsi2sd    xmm1, rax  ; Convert Y to double and store in xmm4

        mov         rdx, r10  ; Restore width from r10

        ; Compute relative X and Y (distance from center)
        movsd       xmm4, xmm3
        subsd       xmm4, xmm1
        subsd       xmm5, xmm2

        ; Zero-case handling: X is exactly at the center
        movsd       xmm1, qword [rel doubleZero]
        comisd      xmm5, xmm1
        jnz         handle_non_zero_case

        ; In zero-case, adjust angle depending on which half of the image we're in
        movsd       xmm6, qword [rel piConstant]
        comisd      xmm4, xmm1
        jb          zero_case_y_lt_center

        ; Upper half of image, angle = pi/2
        mulsd       xmm6, qword [rel doubleHalf]
        jmp         continue_main_loop

zero_case_y_lt_center:
        ; Lower half of image, angle = 3*pi/2
        mulsd       xmm6, qword [rel doubleOneHalf]
        jmp         continue_main_loop

handle_non_zero_case:
        ; Compute original angle based on relative X and Y
        movsd       xmm6, xmm4
        movsd       xmm7, xmm5
        movsd       xmm8, qword [rel absMask]
        subsd       xmm8, qword [rel doubleOne]
        andpd       xmm6, xmm8  ; Absolute value of Y
        andpd       xmm7, xmm8  ; Absolute value of X

        ; Compute arc tangent of Y/X ratio, this gives the angle
        sub         rsp, 32
        movsd       qword [rsp], xmm6
        movsd       qword [rsp + 16], xmm7
        fld         qword [rsp]
        fld         qword [rsp + 16]
        fpatan
        fstp        qword [rsp]  ; Store result of fpatan
        movsd       xmm6, qword [rsp]  ; Move fpatan result to xmm6
        add         rsp, 32

        ; Determine the quarter of the UV space we are in, and adjust angle accordingly
        comisd      xmm5, xmm1  ; If X > 0, it will be 1st or 4th quarter
        ja          handle_x_gt_zero
        comisd      xmm4, xmm1  ; If Y < 0, it will be the 3rd quarter
        jb          handle_y_lt_zero

        ; If not 1st, 3rd or 4th quarter, it will be the 2nd quarter (X < 0, Y >= 0)
        movsd       xmm1, xmm6
        movsd       xmm6, qword [rel piConstant]
        subsd       xmm6, xmm1
        jmp         continue_main_loop

handle_x_gt_zero:
        ; If Y >= 0, it's 1st quarter
        comisd      xmm4, xmm1
        jae         continue_main_loop
        jz          continue_main_loop

        ; If not 1st quarter, it's 4th quarter (X > 0, Y < 0)
        movsd       xmm1, xmm6
        movsd       xmm6, qword [rel piConstant]
        mulsd       xmm6, qword [rel doubleTwo]
        subsd       xmm6, xmm1
        jmp         continue_main_loop

handle_y_lt_zero:
        ; 3rd quarter (X <= 0, Y < 0)
        addsd       xmm6, qword [rel piConstant]

continue_main_loop:
        ; Compute distance to center and adjust angle with swirl factor
        mulsd       xmm4, xmm4
        mulsd       xmm5, xmm5
        addsd       xmm4, xmm5
        sqrtsd      xmm4, xmm4  ; xmm4 = sqrt(xmm4), distance to center

        ; Compute new angle and calculate corresponding source pixel
        movsd       xmm5, qword [rel doubleTwo]
        mulsd       xmm5, xmm5
        divsd       xmm5, qword [rel piConstant]
        movsd       xmm8, xmm4
        mulsd       xmm8, xmm0
        addsd       xmm8, xmm5
        movsd       xmm7, qword [rel doubleOne]
        divsd       xmm7, xmm8
        addsd       xmm6, xmm7

        ; Calculate source x using cos(new angle)
        sub         rsp, 16
        movsd       [rsp], xmm6
        fld         qword [rsp]
        fcos
        fstp        qword [rsp]
        movsd       xmm7, qword [rsp]
        add         rsp, 16

        ; Calculate source y using sin(new angle)
        mulsd       xmm7, xmm4
        addsd       xmm7, qword [rel doubleHalf]
        roundsd     xmm7, xmm7, 1
        cvttsd2si   r10, xmm7

        sub         rsp, 16
        movsd       [rsp], xmm6
        fld         qword [rsp]
        fsin
        fstp        qword [rsp]
        movsd       xmm7, qword [rsp]
        add         rsp, 16

        mulsd       xmm7, xmm4
        addsd       xmm7, qword [rel doubleHalf]
        roundsd     xmm7, xmm7, 1
        cvttsd2si   r11, xmm7

        ; Adjust source x and y with center coordinates
        cvttsd2si   r12, xmm2
        cvttsd2si   r13, xmm3
        add         r10, r12
        add         r11, r13
        mov         r12, r11
        mov         r11, rcx
        sub         r11, r12

        ; Check boundaries for source x and y
        cmp         r10, 0
        jl          source_x_less_than_zero
        cmp         r10, rdx
        jge         source_x_greater_equal_width
        jmp         check_source_y

source_x_less_than_zero:
        mov         r10, 0
        jmp         check_source_y

source_x_greater_equal_width:
        mov         r10, rdx
        sub         r10, 1

check_source_y:
        cmp         r11, 0
        jl          source_y_less_than_zero
        cmp         r11, rcx
        jge         source_y_greater_equal_height
        jmp         finish_pixel_handling

source_y_less_than_zero:
        mov         r11, 0
        jmp         finish_pixel_handling

source_y_greater_equal_height:
        mov         r11, rcx
        sub         r11, 1

finish_pixel_handling:
        ; Convert 2D coordinates to 1D and move source pixel to destination
        mov         rax, r11
        imul        rax, rdx
        add         rax, r10
        imul        rax, 3
        mov         r10, rax
        mov         ax, word [rdi + r10]
        mov         r11b, byte [rdi + r10 + 2]
        mov         word [rsi], ax
        mov         byte [rsi + 2], r11b

        ; Move to the next pixel
        add         rsi, 3
        inc         r8
        jmp         main_loop

end_of_swirl:
        ; Restore registers and return
        add         rsp, 16
        movaps      xmm8, [rsp]
        add         rsp, 16
        movaps      xmm7, [rsp]
        add         rsp, 16
        movaps      xmm6, [rsp]
        pop         r13
        pop         r12
        leave
        ret
