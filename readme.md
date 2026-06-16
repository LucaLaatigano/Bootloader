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


Lets dive into how to make appear something in the screen?. To do this we are going to use the interrupt 0x10, which is the interrupt of sending things into the screen, see the docs [here](http://employees.oneonta.edu/higgindm/assembly/DOS_AND_ROM_BIOS_INTS.htm). Now with having all this understood let write some code to set up the clearscreen tag.

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





