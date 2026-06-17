# Bootloader from Scratch

This is a project that I made just for fun. I followed the guide by Jophish from his [blog](https://www.joe-bergeron.com/posts/Writing%20a%20Tiny%20x86%20Bootloader/). To follow my own updated explanation, you just need to read what is in this README. Of course, it is difficult to explain this entirely from scratch, but I'll do my best!

## Writing the Bootloader

Before writing any code, the first thing to understand is: what is a bootloader? A bootloader is the code that the computer reads before having any operating system installed on it. When we have a brand new computer with just the bare hardware, the question is: how are we going to print something on the screen? In order to print something like "Hello world" or make anything appear at all, we need to write a bootloader. Basically, it's the very first system that runs when we boot up the computer.

Now that we understand what it is, let's explain how we are going to write that script. Mainly, you need a code editor. You can use whatever editor you want; I am going to use VS Code with the "Nasm x86_64 syntax highlighting" extension. Secondly, we need to install NASM (Netwide Assembler) in order to compile our assembly code into a binary format for our virtual machine. For the runtime environment (the virtual machine), I am going to use Bochs, which is a highly customizable PC emulator.

To install all of this, I recommend using a package manager. I used Scoop because I am on Windows 11. To install these tools using Scoop, just type the following command in your terminal:

```bash
scoop install nasm bochs
```

Now let's dive into the assembly code. First things first, you need to understand some basic built-in instructions in assembly. I'll make a list of the ones we are going to use:

- `mov a, b` (Copies the value stored in register `b` into register `a`)
- `push a` (Pushes a register's value onto our stack to save it)
- `pop a` (Pops the value from the stack back into the register)
- `call` (Calls a subroutine/tag that we establish)
- `cli` (Clear Interrupts - disables interrupts)
- `hlt` (Halt - stops the CPU execution)
- `or a, b` (Performs a bitwise OR logic operation between registers `a` and `b`)
- `je .given` (Jump if Equals - jumps to the given tag if a specific condition is met)
- `jmp .given` (Unconditional jump - always jumps to the given tag)

With these instructions in mind, we can start coding our bootloader. The first thing to do is set up the memory segment where we want to store all our code. We are going to use the following registers for this: `ax` (accumulator), `ds` (data segment), `ss` (stack segment), and `sp` (stack pointer). 

Back in the 80s, computers were strictly bounded by their hardware architecture. Because of this, we cannot move a memory address directly into a segment register. The internal wiring doesn't allow it. We need to use a general-purpose register like `ax` as an intermediary to store an address before moving it into a segment register. 

Here is the code to set up the beginning, end, and pointer of our memory segment:

```nasm
bits 16
mov ax, 0x7C0
mov ds, ax
mov ax, 0x7E0
mov ss, ax
mov sp, 0x2000
```

What does this code mean? First, we define that our code will run in a 16-bit environment. Then, with `mov ax, 0x7C0` and `mov ds, ax`, we are pointing to the address where our code is going to start. It starts at the `0x7C0` address because IBM established this specific address as a common standard in every computer for bootloaders. Remember that our bootloader will be exactly 512 bytes long. 

Then, we do the same thing with the `ss` (stack segment) register, but at the address `0x7E0`. Why? Because if we add `0x7C0` + `0x200` (which is 512 bytes in hex) we get `0x7E0`. After that, we set up the stack pointer. But what is a pointer? A pointer is an abstraction used when we want a register to "point" to an address in memory. You can imagine it as an arrow pointing to a specific location. The `sp` register is going to store the starting address of our stack. Something not a lot of people know is that the stack in memory grows downwards. Think of it like a stack of plates, but instead of piling them up, you pile them downwards into the table.

### Interacting with the Screen

Let's dive into how to make something appear on the screen. To do this, we are going to use the BIOS interrupt `0x10`, which handles video services. You can check the documentation [here](http://employees.oneonta.edu/higgindm/assembly/DOS_AND_ROM_BIOS_INTS.htm). Let's write some code to set up a subroutine to clear the screen:

```nasm
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
    
    popa
    mov sp, bp 
    pop bp 
    ret
```

Before explaining this snippet, I need to introduce the registers we are using. In a 16-bit system, the registers are 16 bits (2 bytes) long. We can split these registers into two halves of 1 byte each: a High half and a Low half. Here is a list of the register halves we are about to use:

- `ax` (Accumulator) splits into `ah` (high) and `al` (low)
- `bx` (Base register) splits into `bh` (high) and `bl` (low)
- `cx` (Count register) splits into `ch` (high) and `cl` (low)
- `dx` (Data register) splits into `dh` (high) and `dl` (low)

Now, let's look at the code. The first line, `push bp`, pushes the base pointer register onto the stack. We do this to save the current state of the pointer. The next line, `mov bp, sp`, moves the current stack pointer into the base pointer. Then, `pusha` means "push all"; it pushes all the general-purpose registers onto the stack to save their values so we don't accidentally overwrite them during our subroutine. We will use these three setup lines at the beginning of almost every subroutine, and we reverse the process at the end using `popa` and `pop bp` to give the registers back.

After the setup, we use the register halves. The BIOS interrupt `0x10` has a list of "functions" we can call. By passing specific values into the `ah` register, we tell the BIOS what we want to do. By putting `0x07` into `ah`, we are telling the window to scroll down/initialize. You can see the full specs for these values in this [link](https://www.ctyme.com/intr/rb-0097.htm). 

Now, how do we move the cursor inside the screen? The following snippet handles that:

```nasm
movecursor:
    push bp 
    mov bp, sp 
    pusha 

    mov dx, [bp+4] 
    mov ah, 0x02 
    mov bh, 0x00 
    int 0x10 

    popa 
    mov sp, bp 
    pop bp 
    ret
```

The interesting part here is `mov dx, [bp+4]`. What does that mean? Since `bp` is pointing to the top of our current stack frame, adding `4` allows us to reach the argument we passed into the stack before calling the function. We use brackets `[]` to get the *value* stored at that address (dereferencing it). If we just wrote `bp+4`, we would be passing the memory address itself, not the data inside it. The values `0x02` and `0x00` tell the BIOS to set the cursor position on video page 0. You can check the specs [here](https://www.ctyme.com/intr/rb-0087.htm).

### Printing the Message

Before explaining the print function, you need to understand how strings are stored in assembly:

```nasm
msg:    db "Hello world", 0
```

Here we are defining a variable called `msg`. The `db` stands for "define bytes", meaning the following string characters will be stored byte by byte in memory. At the very end, we write `0`. This is a null-terminator. Because our print function uses a loop, it needs to know when to stop reading memory. It will read characters until it hits this `0` byte. 

Now, let's look at the print subroutine:

```nasm
print:
    push bp
    mov bp, sp
    pusha      

    mov si, [bp+4] 
    mov bh, 0x00   
    mov bl, 0x00   
    mov ah, 0x0E 

.char:
    mov al, [si] 
    add si, 1 
    or al, al 
    je .return 
    int 0x10 
    jmp .char 

.return:
    popa
    mov sp, bp
    pop bp
    ret
```

Here we have the main `print` routine and two inner subroutines (`.char` and `.return`). We get the address of our string from `[bp+4]` and store it in `si` (Source Index). We set `ah` to `0x0E`, which is the BIOS teletype output function (check the specs [here](https://www.ctyme.com/intr/rb-0106.htm)).

Inside the `.char` loop, we grab the current character `[si]` and put it into `al`. Then we add `1` to `si` to move to the next character for the next loop iteration. The `or al, al` operation is very important: it checks if the value in `al` is zero. If it is `0` (meaning we hit the null-terminator at the end of our string), it activates the CPU's Zero Flag. The next line, `je .return` (Jump if Equals), will jump to the `.return` tag if the Zero Flag is active, successfully breaking the loop. Otherwise, we call `int 0x10` to print the character, and then `jmp .char` to loop back and print the next one!

### The Magic Boot Signature

Finally, the last two lines of our bootloader:

```nasm
times 510-($-$$) db 0 
dw 0xAA55
```

The `times` instruction repeats a command a certain number of times. The `$` represents the current memory address, and `$$` represents the start address of the segment. So, `($-$$)` calculates exactly how many bytes of code we have written so far. We subtract that size from `510` bytes, and fill the remaining space with zeroes (`db 0`). 

Why 510? Because a bootloader must be exactly 512 bytes long to be recognized by the BIOS. The final `dw 0xAA55` takes up the last 2 bytes. This specific hex value is the "boot signature". If the BIOS doesn't find `0xAA55` at the very end of the 512-byte sector, it won't execute our code.

### Putting It All Together

Here is the code that actually calls all the subroutines we just made:

```nasm
call clearscreen 
push 0x0000 
call movecursor 
add sp, 2 

push msg 
call print 
add sp, 2 

cli 
hlt
```

We execute this right after we set up our memory segment. First, we clear the screen. Then we push `0x0000` to the stack (which represents the top-left corner of the screen) and call `movecursor`. Afterward, we add `2` to `sp`. Why? Because we pushed a 2-byte argument to the stack. To "clean up" the stack and put the pointer back where it belongs, we add 2. Then we push the address of our `msg` to the stack, call `print`, and clean the stack again. Finally, we clear interrupts (`cli`) and halt the CPU (`hlt`) to stop execution safely.

## How to Run It

To run this code and see the printed message, follow these steps:

1. Compile the assembly code into a raw binary format using NASM in your terminal:
```bash
nasm -f bin boot.asm -o boot.bin
```

2. Create a text file named `bochsrc.txt` in the same directory to configure Bochs. If you are on Windows, the setup looks like this:
```ini
megs: 32
romimage: file=BIOS-bochs-latest, address=0xfffe0000
vgaromimage: file=VGABIOS-lgpl-latest.bin
floppya: 1_44=boot.bin, status=inserted
boot: a
log: bochsout.txt
mouse: enabled=0
display_library: win32, options="gui_debug"
```

*Note: Before running, make sure the `BIOS-bochs-latest` and `VGABIOS-lgpl-latest.bin` files are in your VS Code folder. If you don't know where Bochs installed them, run `where bochs` in your terminal to find the installation path, and copy those two files into your project folder.*

3. Once everything is set up, run the emulator from your terminal:
```bash
bochs -f bochsrc.txt
```

And that's it! Thank you for reading this long README, I hope you enjoyed writing some assembly. I'll probably try writing an OS from scratch next, and maybe even build an 8-bit computer from scratch. If you want to check out more of my projects, visit my [GitHub](https://github.com/LucaLaatigano). Thank you all!