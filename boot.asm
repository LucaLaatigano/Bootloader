
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
