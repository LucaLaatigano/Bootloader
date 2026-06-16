bits 16

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

call clearscreen ;; we call the subroutine for the screen to appear
push 0x0000 ;;we push into the stack 0x0000 to stablish the top-left part of the screen
call movecursor ;;we call the movecursor subroutine
add sp, 2 ;;here we go back the sp pointer, beacause the stack grows downwards

push msg ;;we push the msg onto the memory
call print ;; call print, to print every character
add sp,2 ;;go back the sp pointer so its now on the start of the stack

cli ;;clear interrupts
hlt;;stop the running

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

movecursor:
    push bp ;; we get the bp register as a flag to maintain the previous sp 
    mov bp, sp ;; saving the sp value into bp
    pusha ;; getting the 8 halves of every register inside the CPU

    mov dx, [bp+4] ;; here is the parameters that we are goint to get by storing it inside of bp+4, that is the begging of the stack but in the fourth place, there is value of row ands col
    mov ah, 0x02 ;; 0x02 the value that we need to set in the ah for use the function move the cursor in the list of functions in the BIOS
    mov bh, 0x00 ;; in the documetation it says that we can use multiple pages (multiple buffering), but we are not using that so we set up in 0x00 = 0
    int 0x10 ;; we call the interrupt

    popa ;; we give the 8 halves of register
    mov sp,bp ;;set back to sp its own value
    pop bp ;; we give back the bp registe
    ret;; we end the subroutine


print:
    push bp
    mov bp,sp
    pusha      

    mov si, [bp+4] ;; we get the value in the address bp+4, an that value is an character
    mov bh, 0x00   ;;we set page that we are on
    mov bl, 0x00   ;; foreground color, irrelevant - in text mode
    mov ah, 0x0E ;;here is the funcition in the list of the interrupt

.char:
    mov al, [si] ;;here is the first character in the msg, here [] we are gettin the value on the addres in si
    add si, 1 ;; here add plus to change to the next character which is H and so on 
    or al, 0 ;; we verify the value of al that there are the characther stored, in the msg we store this "Oh boy do I sure love assembly!", 0, that 0 will turn on the Zero flag and in the next intruction will break the loop
    je .return ;; this is the Jump if equals, no it read the Zero flag register which is zero alway, so if the character is 0 it will break the loop
    int 0x10 ;;we call the interrupt to print the given character
    jmp .char ;;here we create a loop, we call .char to start loop util the zero flag is on
.return:
    popa
    mov sp,bp
    pop bp
    ret ;;here we do as always we give back the register and finished the subroutine

msg:	db "Hello world", 0 ;;db(means define bytes) by defining bytes,we are basically telling the computer to store every word in every byte and then we define a tag to call after and push it into the stack

times 510-($-$$) db 0 ;;here we are basically telling the cpu to fill up all the memory left with zeros, $ means the current address and $$ means the address where the segmente started, now by substracting the current and where it started we get all the addresses left with nothing, and by substranting all that 510bytes we get all the memory addresses that we want to fill up with 0, 510 and because the next intruction takes 2 bytes
dw 0xAA55  ;;here we use dw(define word), to define a section on our stack where code finsihes, it 0xAA55 to tell the cpu "here finsish my code". In other word this a test that our computer works, because back in the 80 the wire may fail by reading 0 and 1, so it just a test