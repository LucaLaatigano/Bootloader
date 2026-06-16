# Bootloader from Scratch

This is project that I made just for fun. I have followed the guide from Jophish using his [blog](https://www.joe-bergeron.com/posts/Writing%20a%20Tiny%20x86%20Bootloader/). To follow my own and updated explaination you just need to read what is in this readme, of course is difficult to explain this from scratch but I'll try to do my best.

# Writing the Bootloader

Before writing any code, the first thing to start with is what is a bootloader?. Well a bootloader is code that the computer reads before having anything install in it, what I mean by that is the following, when we have new computer that does not have anything just the hardware the question is, how are we going to print something in the screen?.  In order to print somethin like "Hello world" in the screen or make something appear in it, we need to write a bootloader. So basically a bootloader is a system that runs in your computer when we first boot the computer.

Well understood that we need to explain how are going to write that script. Mainly you need a code editor, use whatever code editor you want, I going to use VS CODE and I am going to use the plugin "Nasm x86_64 syntax highlighting" for the syntax handling. Secondly we need to install NASM(Netwide Assembly) in order to compile our assembly code in binary for the virtual machine. Now the run enviroment (the virtual machine), I going to use Bochs, which is a software simulated computer.For install all this I recommend use a package maneger installer, I used scoop because I have Windows 11. To install all this using scoop write the following line in your terminal "scoop install nasm bochs".


Now lets dive into the assembly code. First thing first, you need to understand some basics buil-in functions in assembly, I'll make a list of the ones we are going to use:
-mov a, b (just copies the addres that is stored in the register b into the register a)
-push a (we borrow into out stack a register to store our own values)
-pop a (we give back the register that we have borrowed)
-call (calls and tag that we stablish)
-cli (means clear interrupts)
-hlt (switches off the computer)
-or a,b (make the logic operation between to register a and b)
-je .given (jumps if a value equals some other value,ant it jumps into the given tag)
-jmp .given (unconditional jump, this just jump into the given tag)


With having understood all this functions, we can start coding our bootloader. The first thing to write is set up the segment in memory where we want to store all our code, we are going to use the following registers to set up that. The registers are ax(accumulator), ds(data segment), ss(stack segment), sp(stack pointer). Now before doing anything we need to understand this, back in the 80's the computer were bounded by the hardware that the computers had. So we can not mov a address from memory directly into and multiple porpuse register, because the wire do not connects those things. So we need to use the ax register in order to stored and adress into a multiple porpuse register. Here is the code to set up the begging, end, and pointer of our segment in memory

```
bits 16
mov ax, 0x7C0
mov ds, ax
mov ax, 0x7E0
mov ss, ax
mov sp, 0x2000
```