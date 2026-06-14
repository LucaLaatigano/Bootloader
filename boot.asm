;; Usefull website for searching interrups in the bios https://www.ctyme.com/intr/int.htm
;;In this section we stablished the segment that our boot is going to start,
;;is like definig from here the boot code starts

mov ax, 0x7C0
mov ds, ax

;;And in this section we set the end of the segment of our boot stack (our code)
;;that is 512 bytes o memory. We get the end of the stack by adding in hexadecimal
;;0x7C0 + 0x200 (512 bytes in hexadecimal) = 0x7C0

mov ax, 0x7E0
mov ss, ax

;; In all this instructions we use the ax(the accumulator, multipropose register) 
;;register, because we are cut by the hardware we can get something from the addresses
;;directly to ss(stack segment) or ds(data segment)

mov sp, 0x2000

;;Here we set a pointer of offset, refering to every address inside the the segment
;;To do this, by knowing that the stack grows downwards we need the the register in laste offset
;;and we start refering to certain addresses we start from the end to the beggining



clearscreen:
    push bp    ;; Here we pushing a value onto the memory that we setup to later give the register value as it was
    mov bp, sp ;; now here we overwrite the bp register with our own value, we are about to use it to be and frame anchor
    pusha   ;; here we do same thing as the first line of the function but with the halves of these registers ax(accumulator), bx(base register), cx(count register), dx(data register)


    mov ah, 0x07 ;; we are acceding and address inside the BIOS in the interrup that we called, for say scroll down
    mov al, 0x00 ;; we setting up the number of lines to scroll, we are setting 0x00 = 0 because we don't want to scroll yet
    mov bh, 0x07 ;; we are acceding the color on list of the interrupt, the color is gray lines and a black background
    mov cx, 0x00 ;; we are setting up the 0,0 top-left corner of the window
    mov dh, 0x18 ;; we are setting up how many rows is the window going to have 0x18 = 24
    mov dl, 0x4f ;; the same as before but here how many columns, 0x4F = 79
    int 0x10 ;;  call the interruption in the BIOS

    popa ;;  we are giving back the values of the eight halves registers
    mov sp,bp ;; we are setting back the value of bp
    pop bp ;;  we are givin bakc the bp
    ret ;;  we return for funtion to stop


