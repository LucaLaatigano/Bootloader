# Bootloader from Scratch

This is project that I made just for fun. I have followed the guide from Jophish using his [blog](https://www.joe-bergeron.com/posts/Writing%20a%20Tiny%20x86%20Bootloader/). To follow my own and updated explaination you just need to read what is in this readme, of course is difficult to explain this from scratch but I'll try to do my best.

# Writing the Bootloader

Before writing any code, the first thing to start with is what is a bootloader?. Well a bootloader is code that the computer reads before having anything install in it, what I mean by that is the following, when we have new computer that does not have anything just the hardware the question is, how are we going to print something in the screen?.  In order to print somethin like "Hello world" in the screen or make something appear in it, we need to write a bootloader. So basically a bootloader is a system that runs in your computer when we first boot the computer.

Well understood that we need to explain how are going to write that script. Mainly you need a code editor, use whatever code editor you want, I going to use VS CODE and I am going to use the plugin "Nasm x86_64 syntax highlighting" for the syntax handling. Secondly we need to install NASM(Netwide Assembly) in order to compile our assembly code in binary for the virtual machine. Now the run enviroment (the virtual machine), I going to use Bochs, which is a software simulated computer.For install all this I recommend use a package maneger installer, I used scoop because I have Windows 11. To install all this using scoop write the following line in your terminal "scoop install nasm bochs".


Now lets dive into the assembly code. First thing first, you need to understand some basics buil-in functions in assembly, I'll make a list of the ones we are going to use:
- `mov a, b` (just copies the addres that is stored in the register b into the register a)
- `push a` (we borrow into out stack a register to store our own values)
- `pop a` (we give back the register that we have borrowed)
- `call` (calls and tag that we stablish)
- `cli` (means clear interrupts)
- `hlt` (switches off the computer)
- `or a,b` (make the logic operation between to register a and b)
- `je .given` (jumps if a value equals some other value,ant it jumps into the given tag)
- `jmp .given` (unconditional jump, this just jump into the given tag)


With having understood all this functions, we can start coding our bootloader. The first thing to write is set up the segment in memory where we want to store all our code, we are going to use the following registers to set up that. The registers are ax(accumulator), ds(data segment), ss(stack segment), sp(stack pointer). Now before doing anything we need to understand this, back in the 80's the computer were bounded by the hardware that the computers had. So we can not mov a address from memory directly into and multiple porpuse register, because the wire do not connects those things. So we need to use the ax register in order to stored and adress into a multiple porpuse register. Here is the code to set up the begging, end, and pointer of our segment in memory

```
bits 16
mov ax, 0x7C0
mov ds, ax
mov ax, 0x7E0
mov ss, ax
mov sp, 0x2000
```

What does this code mean?. First we define how many bits our computer is going to have, then `mov ax, 0x7C0` and `mov ds, ax` we are copying the address where our code is going to start, it starts in the 0x7C0 adress because IBM stablished this address as common standard adress in every computer. Remember that our Bootloader will be 512 bytes long. Then we do the same thing with the ss register using ax, but in the address 0x7E0 because if we add 0x7C0 + 0x200 (512 bytes in hex) = 0x7E0. After that we set up the pointer, but first what is a pointer?. A pointer is an abstraction that is made when we want a register "pointing into and adress", you can abstract yourself and see it as an arrow that points an addres in memory, this is use because we want the pointer "pointing" to another address. So the sp register is going to have the address store of where our code starts. A statement that no much people know, is the the fact that a segment in memory grows down side up, think it as pile of plates where the plates instead of piling it up, we pile the plate down the other.


Lets dive into how to make appear something in the screen. To do this we are going to use the interrupt 0x10, which is the interrupt of sending things into the screen, in simple words. See the docs [here](http://employees.oneonta.edu/higgindm/assembly/DOS_AND_ROM_BIOS_INTS.htm). Now with having all this understood let write some code to set up the clearscreen tag.

```
clearscreen:
    push bp    
    mov bp, sp 
    pusha   

    mov ah, 0x07 
    mov al, 0x00 
    mov bh, 0x07 
    mov cx, 0x00 
    mov dh, 0x18 
    mov dl, 0x4f 
    int 0x10 
    mov sp,bp 
    pop bp 
```


Now lets explain this snippet, first before explaining any code I need to introduce the register that We are using here. Having a 16 bits system means that the register are 16 bits long, so a register is 2 bytes. Knowing this we can split this register in halves, one 1 byte long and the other 1 byte long. So this halves that I am talking are the register inside cpu that we are going to use, so I going to make a list of every halve register that we are about to use:

- `ax(accumulator)` can be splited in `ah(accummulator high) al(accumulator low)`
- `bs(base register)` can be splited in `bh(base high) bl(base low)
- `cx(count register)` can be splited in `ch(count high) cl(count low)
- `cx(data register)` can be splited in `dh(data high) dl(data low)

With this knowledge we can dive into the code. Remember we are using 0x10 for printing in the screen. So the first line `push bp`, we are pushing the base pointer register onto the stack that we already set up, why?. Because our sp is going to point to the following address in memory so we push it to save the sp address (the address that our segment starts), then the second line `mov bp, sp` we move the address in sp to bp. Then the following line pusha means "push all", what this does is to push into the stack all the registers, including the halves into the stack. We are going to use all this three lines every time, because we need to borrow the register if some other tag subroutine is using them, and save its value to not overwrite. So I will skip the explaination of these lines in the others snippets.

After that we use the halves that we talked about. Now to scroll the window the interrupt 0x10 in the BIOS has a list of "functions" that we could call, and by storing some values into the halves of the register we can control the behaviour of our screen. So we put the 0x07 value into ah, the window will try to scroll down. Now to skip the explanation of all the value you can see this [link](https://www.ctyme.com/intr/rb-0097.htm). So all the spec are on that link and the values are there too. Now at the end we do the opposite that we did at the begging instead of borrowing the register we are ginving them back, so we are poping out of our stack the registers.

How to move the cursor inside the screen, the following snippet does that:

```
movecursor:
    push bp 
    mov bp, sp 
    pusha 

    mov dx, [bp+4] 
    mov ah, 0x02 
    mov bh, 0x00 
    int 0x10 

    popa 
    mov sp,bp 
    pop bp 
    ret
```
The weird thing about these lines are first `mov dx, [bp+4]`, what is that?. Is very simple to understand, we have the bp pointer pointing in at the beggining of our stack, because sp is moving down. So adding bp+4 we are saying that from the begging of the stack 4 place more is going to be our starting cursor, use [] brakets in order to get the value that is stored inside the address, if we write just bp+4 we are passing just the address not the value. To understand the other value of 0x02 and 0x00, go [here](https://www.ctyme.com/intr/rb-0087.htm). In the spec link you are going to see that we need set to the register the value of a page that we are on, that just mean that we can write code to other pages and can switch using that register, but since we are no using that section, we just set it up in 0x00 = 0, page 0.

Before explaining the print function, you need to understand how the message is store, the following code:

````
msg:	db "Hello world", 0
```
Here we are defining another tag subroutine call msg, but we write db why?. It means define bytes, so the following characters are going to be define byte by byte. At the end we write 0, because to print all that msg we need a loop, and for no looping forever we need to use another register inside the cpu called the zero flag register that just have a 0 inside of it. Now we can get into the print subroutine:

```
print:
    push bp
    mov bp,sp
    pusha      

    mov si, [bp+4] 
    mov bh, 0x00   
    mov bl, 0x00   
    mov ah, 0x0E 

.char:
    mov al, [si] 
    add si, 1 
    or al, 0 
    je .return 
    int 0x10 
    jmp .char 
.return:
    popa
    mov sp,bp
    pop bp
    ret
```

Here we define three tag subroutines. First is the print subroutine, that is going to print a msg stored inside the memory, so remember the [bp+4] value, we are getting that value again and storing it inside si(source index), to have the first character of our msg. Then we set some values in the bh, bl and ah register, you can see the spec [here](https://www.ctyme.com/intr/rb-0106.htm). Now lets explain the other two left, first the .return we are just poping out of the segment the registers and returning for the subroutine to finish. Now the most interesting in the whole how the .char, here we need to print charact by character, so remember that we have the first char in the si register, now we mov into the al halve. We did that to add 1 to the si register and change to the next char. Now having the first char inside the al, we can do the or logic operation, for what reason?. We do this to compare that value with the zero flag value a scape of the loop, remember what does, if you compara a value with 0, you are going to get the same value. So when the loop reaches the 0 at the of our msg it will jump into the follwing line `je .return`, here we are calling the .return subroutine to stop the loop. The operation je means jump if equals, and the previous line we have 0, so it would jump is al is 0. Then we call the interrupt 0x10, and we go to the most important line `jpm`, means unconditional jump it just jumps somewhere. We jump into the same script and it would loop forever until the zero flag is activated.


Now the last but not least lines.
```
times 510-($-$$) db 0 
dw 0xAA55
```
times means multiply this in certain times. Now ($-$$), $ means the current address that we are on, and $$ means the address the of the start of the segment, we substracting this to get how many memory we are using an then we are going to substract that by 510 bytes, and also putting 0 zeros in the result of that substract. Why 510, remember that our code was going to be 512 bytes long, so the following lines, takes 2 bytes and we have 510 bytes left in memory. So basically what the times line does is to fill with 0 the memory of our stack that does not have any code.

Now the calles intructions:
```
call clearscreen 
push 0x0000 
call movecursor 
add sp, 2 

push msg 
call print 
add sp,2 

cli 
hlt
```
This snippet just call all the subroutines tags. To run our code, we doit after we set up our memory segment. First we call the clearscreen to build the screen, the we push into the stack 0x0000 = 0, we pushed 0 because means the top-left corner of the screen that our msg is going to start printing. Then call movecursor to setup the cursor. And after that we add sp + 2, but why?. Remember that our stack grow down side up, that mean when the pointer points the following address it will go down to keep pointing foward, so in order to set a step back we need to add. Then push the msg into the memory, and call print. Then to finished the code we clear interrupts with cli, and stop the computer with hlt.

And that is it, to run this code and to see the printed msg, we need to do the following:

1- compile our code in binary with nasm`, write this in the terminal:
```
nasm -f bin boot.asm -o boot.bin
```
2-Then create a txt to set up an own configuration, since I am using windows the windows set up is the following:
```
megs: 32
romimage: file=BIOS-bochs-latest, address=0xfffe0000
vgaromimage: file=VGABIOS-lgpl-latest.bin
floppya: 1_44=boot.bin, status=inserted
boot: a
log: bochsout.txt
mouse: enabled=0
display_library: win32, options="gui_debug"
```
Before writing the same lines, check where the BIOS-bochs-latest and the VGABIOS-lgpl-latest.bin files are on your computer. If don't know where are they use the following line in your terminal:
````
where bochs
```
And copy the files into the current folder that you are on vs code.

Then having all that we can run our code and see the message by writing this in your terminal:
```
bochs -f bochsrc.txt
```

And that is it. Thank you for reading all this long readme, but i hope you enjoy writing some assembly. I'd probably write an OS by my own from scratch and also make a 8-bit computer from scratch. If you want to do this project go to my [github](https://github.com/LucaLaatigano). Thank you all.