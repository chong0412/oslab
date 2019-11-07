
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 82 31 00 00       	call   f01031df <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 36 10 f0       	push   $0xf0103680
f010006f:	e8 82 26 00 00       	call   f01026f6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 84 0f 00 00       	call   f0100ffd <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 89 06 00 00       	call   f010070f <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 9b 36 10 f0       	push   $0xf010369b
f01000b5:	e8 3c 26 00 00       	call   f01026f6 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 0c 26 00 00       	call   f01026d0 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 86 43 10 f0 	movl   $0xf0104386,(%esp)
f01000cb:	e8 26 26 00 00       	call   f01026f6 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 32 06 00 00       	call   f010070f <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 b3 36 10 f0       	push   $0xf01036b3
f01000f7:	e8 fa 25 00 00       	call   f01026f6 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 c8 25 00 00       	call   f01026d0 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 86 43 10 f0 	movl   $0xf0104386,(%esp)
f010010f:	e8 e2 25 00 00       	call   f01026f6 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 20 38 10 f0 	movzbl -0xfefc7e0(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 20 38 10 f0 	movzbl -0xfefc7e0(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 20 37 10 f0 	movzbl -0xfefc8e0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 00 37 10 f0 	mov    -0xfefc900(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 cd 36 10 f0       	push   $0xf01036cd
f0100265:	e8 8c 24 00 00       	call   f01026f6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 19 2e 00 00       	call   f010322c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004b5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004c6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 d9 36 10 f0       	push   $0xf01036d9
f01005e2:	e8 0f 21 00 00       	call   f01026f6 <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 20 39 10 f0       	push   $0xf0103920
f0100628:	68 3e 39 10 f0       	push   $0xf010393e
f010062d:	68 43 39 10 f0       	push   $0xf0103943
f0100632:	e8 bf 20 00 00       	call   f01026f6 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 ac 39 10 f0       	push   $0xf01039ac
f010063f:	68 4c 39 10 f0       	push   $0xf010394c
f0100644:	68 43 39 10 f0       	push   $0xf0103943
f0100649:	e8 a8 20 00 00       	call   f01026f6 <cprintf>
	return 0;
}
f010064e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100653:	c9                   	leave  
f0100654:	c3                   	ret    

f0100655 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010065b:	68 55 39 10 f0       	push   $0xf0103955
f0100660:	e8 91 20 00 00       	call   f01026f6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100665:	83 c4 08             	add    $0x8,%esp
f0100668:	68 0c 00 10 00       	push   $0x10000c
f010066d:	68 d4 39 10 f0       	push   $0xf01039d4
f0100672:	e8 7f 20 00 00       	call   f01026f6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100677:	83 c4 0c             	add    $0xc,%esp
f010067a:	68 0c 00 10 00       	push   $0x10000c
f010067f:	68 0c 00 10 f0       	push   $0xf010000c
f0100684:	68 fc 39 10 f0       	push   $0xf01039fc
f0100689:	e8 68 20 00 00       	call   f01026f6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 71 36 10 00       	push   $0x103671
f0100696:	68 71 36 10 f0       	push   $0xf0103671
f010069b:	68 20 3a 10 f0       	push   $0xf0103a20
f01006a0:	e8 51 20 00 00       	call   f01026f6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 00 63 11 00       	push   $0x116300
f01006ad:	68 00 63 11 f0       	push   $0xf0116300
f01006b2:	68 44 3a 10 f0       	push   $0xf0103a44
f01006b7:	e8 3a 20 00 00       	call   f01026f6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 70 69 11 00       	push   $0x116970
f01006c4:	68 70 69 11 f0       	push   $0xf0116970
f01006c9:	68 68 3a 10 f0       	push   $0xf0103a68
f01006ce:	e8 23 20 00 00       	call   f01026f6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d3:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006d8:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dd:	83 c4 08             	add    $0x8,%esp
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	50                   	push   %eax
f01006f4:	68 8c 3a 10 f0       	push   $0xf0103a8c
f01006f9:	e8 f8 1f 00 00       	call   f01026f6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100705:	55                   	push   %ebp
f0100706:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100708:	b8 00 00 00 00       	mov    $0x0,%eax
f010070d:	5d                   	pop    %ebp
f010070e:	c3                   	ret    

f010070f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010070f:	55                   	push   %ebp
f0100710:	89 e5                	mov    %esp,%ebp
f0100712:	57                   	push   %edi
f0100713:	56                   	push   %esi
f0100714:	53                   	push   %ebx
f0100715:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100718:	68 b8 3a 10 f0       	push   $0xf0103ab8
f010071d:	e8 d4 1f 00 00       	call   f01026f6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100722:	c7 04 24 dc 3a 10 f0 	movl   $0xf0103adc,(%esp)
f0100729:	e8 c8 1f 00 00       	call   f01026f6 <cprintf>
f010072e:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100731:	83 ec 0c             	sub    $0xc,%esp
f0100734:	68 6e 39 10 f0       	push   $0xf010396e
f0100739:	e8 4a 28 00 00       	call   f0102f88 <readline>
f010073e:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100740:	83 c4 10             	add    $0x10,%esp
f0100743:	85 c0                	test   %eax,%eax
f0100745:	74 ea                	je     f0100731 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100747:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010074e:	be 00 00 00 00       	mov    $0x0,%esi
f0100753:	eb 0a                	jmp    f010075f <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100755:	c6 03 00             	movb   $0x0,(%ebx)
f0100758:	89 f7                	mov    %esi,%edi
f010075a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010075d:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010075f:	0f b6 03             	movzbl (%ebx),%eax
f0100762:	84 c0                	test   %al,%al
f0100764:	74 63                	je     f01007c9 <monitor+0xba>
f0100766:	83 ec 08             	sub    $0x8,%esp
f0100769:	0f be c0             	movsbl %al,%eax
f010076c:	50                   	push   %eax
f010076d:	68 72 39 10 f0       	push   $0xf0103972
f0100772:	e8 2b 2a 00 00       	call   f01031a2 <strchr>
f0100777:	83 c4 10             	add    $0x10,%esp
f010077a:	85 c0                	test   %eax,%eax
f010077c:	75 d7                	jne    f0100755 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010077e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100781:	74 46                	je     f01007c9 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100783:	83 fe 0f             	cmp    $0xf,%esi
f0100786:	75 14                	jne    f010079c <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100788:	83 ec 08             	sub    $0x8,%esp
f010078b:	6a 10                	push   $0x10
f010078d:	68 77 39 10 f0       	push   $0xf0103977
f0100792:	e8 5f 1f 00 00       	call   f01026f6 <cprintf>
f0100797:	83 c4 10             	add    $0x10,%esp
f010079a:	eb 95                	jmp    f0100731 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010079c:	8d 7e 01             	lea    0x1(%esi),%edi
f010079f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007a3:	eb 03                	jmp    f01007a8 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007a5:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007a8:	0f b6 03             	movzbl (%ebx),%eax
f01007ab:	84 c0                	test   %al,%al
f01007ad:	74 ae                	je     f010075d <monitor+0x4e>
f01007af:	83 ec 08             	sub    $0x8,%esp
f01007b2:	0f be c0             	movsbl %al,%eax
f01007b5:	50                   	push   %eax
f01007b6:	68 72 39 10 f0       	push   $0xf0103972
f01007bb:	e8 e2 29 00 00       	call   f01031a2 <strchr>
f01007c0:	83 c4 10             	add    $0x10,%esp
f01007c3:	85 c0                	test   %eax,%eax
f01007c5:	74 de                	je     f01007a5 <monitor+0x96>
f01007c7:	eb 94                	jmp    f010075d <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01007c9:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007d0:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007d1:	85 f6                	test   %esi,%esi
f01007d3:	0f 84 58 ff ff ff    	je     f0100731 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007d9:	83 ec 08             	sub    $0x8,%esp
f01007dc:	68 3e 39 10 f0       	push   $0xf010393e
f01007e1:	ff 75 a8             	pushl  -0x58(%ebp)
f01007e4:	e8 5b 29 00 00       	call   f0103144 <strcmp>
f01007e9:	83 c4 10             	add    $0x10,%esp
f01007ec:	85 c0                	test   %eax,%eax
f01007ee:	74 1e                	je     f010080e <monitor+0xff>
f01007f0:	83 ec 08             	sub    $0x8,%esp
f01007f3:	68 4c 39 10 f0       	push   $0xf010394c
f01007f8:	ff 75 a8             	pushl  -0x58(%ebp)
f01007fb:	e8 44 29 00 00       	call   f0103144 <strcmp>
f0100800:	83 c4 10             	add    $0x10,%esp
f0100803:	85 c0                	test   %eax,%eax
f0100805:	75 2f                	jne    f0100836 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100807:	b8 01 00 00 00       	mov    $0x1,%eax
f010080c:	eb 05                	jmp    f0100813 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010080e:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100813:	83 ec 04             	sub    $0x4,%esp
f0100816:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100819:	01 d0                	add    %edx,%eax
f010081b:	ff 75 08             	pushl  0x8(%ebp)
f010081e:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100821:	51                   	push   %ecx
f0100822:	56                   	push   %esi
f0100823:	ff 14 85 0c 3b 10 f0 	call   *-0xfefc4f4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010082a:	83 c4 10             	add    $0x10,%esp
f010082d:	85 c0                	test   %eax,%eax
f010082f:	78 1d                	js     f010084e <monitor+0x13f>
f0100831:	e9 fb fe ff ff       	jmp    f0100731 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100836:	83 ec 08             	sub    $0x8,%esp
f0100839:	ff 75 a8             	pushl  -0x58(%ebp)
f010083c:	68 94 39 10 f0       	push   $0xf0103994
f0100841:	e8 b0 1e 00 00       	call   f01026f6 <cprintf>
f0100846:	83 c4 10             	add    $0x10,%esp
f0100849:	e9 e3 fe ff ff       	jmp    f0100731 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010084e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100851:	5b                   	pop    %ebx
f0100852:	5e                   	pop    %esi
f0100853:	5f                   	pop    %edi
f0100854:	5d                   	pop    %ebp
f0100855:	c3                   	ret    

f0100856 <boot_alloc>:
//Returns a kernel virtual address.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100856:	55                   	push   %ebp
f0100857:	89 e5                	mov    %esp,%ebp
	static char *nextfree;	// virtual address of next byte of free memory
	char *result;  	
	// 初始化nextfree。'end'由链接器自动生成
	// 指向内核的bss段的末尾：第一个虚拟地址。
	if (!nextfree) {
f0100859:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f0100860:	75 11                	jne    f0100873 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100862:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f0100867:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010086d:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	}

	// 设置nextfree为n字节大小，并保证和页大小对齐
	// LAB 2: Your code here.
	//cprintf("boot_alloc, nextfree:%x\n", nextfree);
    result = nextfree;
f0100873:	8b 15 38 65 11 f0    	mov    0xf0116538,%edx
    if (n != 0) {
f0100879:	85 c0                	test   %eax,%eax
f010087b:	74 11                	je     f010088e <boot_alloc+0x38>
        nextfree = ROUNDUP(nextfree + n, PGSIZE);
f010087d:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100884:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100889:	a3 38 65 11 f0       	mov    %eax,0xf0116538
    }

	return result;
}
f010088e:	89 d0                	mov    %edx,%eax
f0100890:	5d                   	pop    %ebp
f0100891:	c3                   	ret    

f0100892 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100892:	89 d1                	mov    %edx,%ecx
f0100894:	c1 e9 16             	shr    $0x16,%ecx
f0100897:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010089a:	a8 01                	test   $0x1,%al
f010089c:	74 52                	je     f01008f0 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010089e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008a3:	89 c1                	mov    %eax,%ecx
f01008a5:	c1 e9 0c             	shr    $0xc,%ecx
f01008a8:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f01008ae:	72 1b                	jb     f01008cb <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008b0:	55                   	push   %ebp
f01008b1:	89 e5                	mov    %esp,%ebp
f01008b3:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008b6:	50                   	push   %eax
f01008b7:	68 1c 3b 10 f0       	push   $0xf0103b1c
f01008bc:	68 cc 02 00 00       	push   $0x2cc
f01008c1:	68 c8 42 10 f0       	push   $0xf01042c8
f01008c6:	e8 c0 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01008cb:	c1 ea 0c             	shr    $0xc,%edx
f01008ce:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01008d4:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01008db:	89 c2                	mov    %eax,%edx
f01008dd:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01008e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008e5:	85 d2                	test   %edx,%edx
f01008e7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01008ec:	0f 44 c2             	cmove  %edx,%eax
f01008ef:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01008f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01008f5:	c3                   	ret    

f01008f6 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01008f6:	55                   	push   %ebp
f01008f7:	89 e5                	mov    %esp,%ebp
f01008f9:	57                   	push   %edi
f01008fa:	56                   	push   %esi
f01008fb:	53                   	push   %ebx
f01008fc:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01008ff:	84 c0                	test   %al,%al
f0100901:	0f 85 72 02 00 00    	jne    f0100b79 <check_page_free_list+0x283>
f0100907:	e9 7f 02 00 00       	jmp    f0100b8b <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f010090c:	83 ec 04             	sub    $0x4,%esp
f010090f:	68 40 3b 10 f0       	push   $0xf0103b40
f0100914:	68 0f 02 00 00       	push   $0x20f
f0100919:	68 c8 42 10 f0       	push   $0xf01042c8
f010091e:	e8 68 f7 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100923:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100926:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100929:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010092c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010092f:	89 c2                	mov    %eax,%edx
f0100931:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0100937:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f010093d:	0f 95 c2             	setne  %dl
f0100940:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100943:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100947:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100949:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010094d:	8b 00                	mov    (%eax),%eax
f010094f:	85 c0                	test   %eax,%eax
f0100951:	75 dc                	jne    f010092f <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100953:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100956:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010095c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010095f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100962:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100964:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100967:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010096c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100971:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100977:	eb 53                	jmp    f01009cc <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100979:	89 d8                	mov    %ebx,%eax
f010097b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100981:	c1 f8 03             	sar    $0x3,%eax
f0100984:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100987:	89 c2                	mov    %eax,%edx
f0100989:	c1 ea 16             	shr    $0x16,%edx
f010098c:	39 f2                	cmp    %esi,%edx
f010098e:	73 3a                	jae    f01009ca <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100990:	89 c2                	mov    %eax,%edx
f0100992:	c1 ea 0c             	shr    $0xc,%edx
f0100995:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010099b:	72 12                	jb     f01009af <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010099d:	50                   	push   %eax
f010099e:	68 1c 3b 10 f0       	push   $0xf0103b1c
f01009a3:	6a 52                	push   $0x52
f01009a5:	68 d4 42 10 f0       	push   $0xf01042d4
f01009aa:	e8 dc f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f01009af:	83 ec 04             	sub    $0x4,%esp
f01009b2:	68 80 00 00 00       	push   $0x80
f01009b7:	68 97 00 00 00       	push   $0x97
f01009bc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009c1:	50                   	push   %eax
f01009c2:	e8 18 28 00 00       	call   f01031df <memset>
f01009c7:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009ca:	8b 1b                	mov    (%ebx),%ebx
f01009cc:	85 db                	test   %ebx,%ebx
f01009ce:	75 a9                	jne    f0100979 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f01009d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01009d5:	e8 7c fe ff ff       	call   f0100856 <boot_alloc>
f01009da:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009dd:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01009e3:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f01009e9:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01009ee:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01009f1:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01009f4:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f01009f7:	be 00 00 00 00       	mov    $0x0,%esi
f01009fc:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009ff:	e9 30 01 00 00       	jmp    f0100b34 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a04:	39 ca                	cmp    %ecx,%edx
f0100a06:	73 19                	jae    f0100a21 <check_page_free_list+0x12b>
f0100a08:	68 e2 42 10 f0       	push   $0xf01042e2
f0100a0d:	68 ee 42 10 f0       	push   $0xf01042ee
f0100a12:	68 29 02 00 00       	push   $0x229
f0100a17:	68 c8 42 10 f0       	push   $0xf01042c8
f0100a1c:	e8 6a f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a21:	39 fa                	cmp    %edi,%edx
f0100a23:	72 19                	jb     f0100a3e <check_page_free_list+0x148>
f0100a25:	68 03 43 10 f0       	push   $0xf0104303
f0100a2a:	68 ee 42 10 f0       	push   $0xf01042ee
f0100a2f:	68 2a 02 00 00       	push   $0x22a
f0100a34:	68 c8 42 10 f0       	push   $0xf01042c8
f0100a39:	e8 4d f6 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a3e:	89 d0                	mov    %edx,%eax
f0100a40:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a43:	a8 07                	test   $0x7,%al
f0100a45:	74 19                	je     f0100a60 <check_page_free_list+0x16a>
f0100a47:	68 64 3b 10 f0       	push   $0xf0103b64
f0100a4c:	68 ee 42 10 f0       	push   $0xf01042ee
f0100a51:	68 2b 02 00 00       	push   $0x22b
f0100a56:	68 c8 42 10 f0       	push   $0xf01042c8
f0100a5b:	e8 2b f6 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a60:	c1 f8 03             	sar    $0x3,%eax
f0100a63:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100a66:	85 c0                	test   %eax,%eax
f0100a68:	75 19                	jne    f0100a83 <check_page_free_list+0x18d>
f0100a6a:	68 17 43 10 f0       	push   $0xf0104317
f0100a6f:	68 ee 42 10 f0       	push   $0xf01042ee
f0100a74:	68 2e 02 00 00       	push   $0x22e
f0100a79:	68 c8 42 10 f0       	push   $0xf01042c8
f0100a7e:	e8 08 f6 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100a83:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100a88:	75 19                	jne    f0100aa3 <check_page_free_list+0x1ad>
f0100a8a:	68 28 43 10 f0       	push   $0xf0104328
f0100a8f:	68 ee 42 10 f0       	push   $0xf01042ee
f0100a94:	68 2f 02 00 00       	push   $0x22f
f0100a99:	68 c8 42 10 f0       	push   $0xf01042c8
f0100a9e:	e8 e8 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100aa3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100aa8:	75 19                	jne    f0100ac3 <check_page_free_list+0x1cd>
f0100aaa:	68 98 3b 10 f0       	push   $0xf0103b98
f0100aaf:	68 ee 42 10 f0       	push   $0xf01042ee
f0100ab4:	68 30 02 00 00       	push   $0x230
f0100ab9:	68 c8 42 10 f0       	push   $0xf01042c8
f0100abe:	e8 c8 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ac3:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ac8:	75 19                	jne    f0100ae3 <check_page_free_list+0x1ed>
f0100aca:	68 41 43 10 f0       	push   $0xf0104341
f0100acf:	68 ee 42 10 f0       	push   $0xf01042ee
f0100ad4:	68 31 02 00 00       	push   $0x231
f0100ad9:	68 c8 42 10 f0       	push   $0xf01042c8
f0100ade:	e8 a8 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ae3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ae8:	76 3f                	jbe    f0100b29 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aea:	89 c3                	mov    %eax,%ebx
f0100aec:	c1 eb 0c             	shr    $0xc,%ebx
f0100aef:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100af2:	77 12                	ja     f0100b06 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100af4:	50                   	push   %eax
f0100af5:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0100afa:	6a 52                	push   $0x52
f0100afc:	68 d4 42 10 f0       	push   $0xf01042d4
f0100b01:	e8 85 f5 ff ff       	call   f010008b <_panic>
f0100b06:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b0b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b0e:	76 1e                	jbe    f0100b2e <check_page_free_list+0x238>
f0100b10:	68 bc 3b 10 f0       	push   $0xf0103bbc
f0100b15:	68 ee 42 10 f0       	push   $0xf01042ee
f0100b1a:	68 32 02 00 00       	push   $0x232
f0100b1f:	68 c8 42 10 f0       	push   $0xf01042c8
f0100b24:	e8 62 f5 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b29:	83 c6 01             	add    $0x1,%esi
f0100b2c:	eb 04                	jmp    f0100b32 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100b2e:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b32:	8b 12                	mov    (%edx),%edx
f0100b34:	85 d2                	test   %edx,%edx
f0100b36:	0f 85 c8 fe ff ff    	jne    f0100a04 <check_page_free_list+0x10e>
f0100b3c:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100b3f:	85 f6                	test   %esi,%esi
f0100b41:	7f 19                	jg     f0100b5c <check_page_free_list+0x266>
f0100b43:	68 5b 43 10 f0       	push   $0xf010435b
f0100b48:	68 ee 42 10 f0       	push   $0xf01042ee
f0100b4d:	68 3a 02 00 00       	push   $0x23a
f0100b52:	68 c8 42 10 f0       	push   $0xf01042c8
f0100b57:	e8 2f f5 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100b5c:	85 db                	test   %ebx,%ebx
f0100b5e:	7f 42                	jg     f0100ba2 <check_page_free_list+0x2ac>
f0100b60:	68 6d 43 10 f0       	push   $0xf010436d
f0100b65:	68 ee 42 10 f0       	push   $0xf01042ee
f0100b6a:	68 3b 02 00 00       	push   $0x23b
f0100b6f:	68 c8 42 10 f0       	push   $0xf01042c8
f0100b74:	e8 12 f5 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100b79:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100b7e:	85 c0                	test   %eax,%eax
f0100b80:	0f 85 9d fd ff ff    	jne    f0100923 <check_page_free_list+0x2d>
f0100b86:	e9 81 fd ff ff       	jmp    f010090c <check_page_free_list+0x16>
f0100b8b:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100b92:	0f 84 74 fd ff ff    	je     f010090c <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b98:	be 00 04 00 00       	mov    $0x400,%esi
f0100b9d:	e9 cf fd ff ff       	jmp    f0100971 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100ba2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ba5:	5b                   	pop    %ebx
f0100ba6:	5e                   	pop    %esi
f0100ba7:	5f                   	pop    %edi
f0100ba8:	5d                   	pop    %ebp
f0100ba9:	c3                   	ret    

f0100baa <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100baa:	55                   	push   %ebp
f0100bab:	89 e5                	mov    %esp,%ebp
f0100bad:	56                   	push   %esi
f0100bae:	53                   	push   %ebx
    // 1）第0页不用，留给中断描述符表
    // 2）[The rest of base memory]  第1-159页可以使用，加入空闲链表（npages_basemem为160，即640K以下内存)
    // 3）[IO hole and kernel]       640K-1M空间保留给BIOS和显存，不能加入空闲链表
    // 4）[extended memory]	1M以上空间部分可用
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100baf:	8b 35 40 65 11 f0    	mov    0xf0116540,%esi
f0100bb5:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100bbb:	ba 00 00 00 00       	mov    $0x0,%edx
f0100bc0:	b8 01 00 00 00       	mov    $0x1,%eax
f0100bc5:	eb 27                	jmp    f0100bee <page_init+0x44>
		pages[i].pp_ref = 0;
f0100bc7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100bce:	89 d1                	mov    %edx,%ecx
f0100bd0:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100bd6:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100bdc:	89 19                	mov    %ebx,(%ecx)
    // 1）第0页不用，留给中断描述符表
    // 2）[The rest of base memory]  第1-159页可以使用，加入空闲链表（npages_basemem为160，即640K以下内存)
    // 3）[IO hole and kernel]       640K-1M空间保留给BIOS和显存，不能加入空闲链表
    // 4）[extended memory]	1M以上空间部分可用
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100bde:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100be1:	89 d3                	mov    %edx,%ebx
f0100be3:	03 1d 6c 69 11 f0    	add    0xf011696c,%ebx
f0100be9:	ba 01 00 00 00       	mov    $0x1,%edx
    // 1）第0页不用，留给中断描述符表
    // 2）[The rest of base memory]  第1-159页可以使用，加入空闲链表（npages_basemem为160，即640K以下内存)
    // 3）[IO hole and kernel]       640K-1M空间保留给BIOS和显存，不能加入空闲链表
    // 4）[extended memory]	1M以上空间部分可用
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100bee:	39 f0                	cmp    %esi,%eax
f0100bf0:	72 d5                	jb     f0100bc7 <page_init+0x1d>
f0100bf2:	84 d2                	test   %dl,%dl
f0100bf4:	74 06                	je     f0100bfc <page_init+0x52>
f0100bf6:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	int kern_end = (int)ROUNDUP(((char*)pages) + (sizeof(struct PageInfo) * npages) - 0xf0000000, PGSIZE)/PGSIZE;
f0100bfc:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100c01:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0100c07:	8d 84 d0 ff 0f 00 10 	lea    0x10000fff(%eax,%edx,8),%eax
	for (i = kern_end; i < npages; i++) {
f0100c0e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c13:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100c19:	85 c0                	test   %eax,%eax
f0100c1b:	0f 48 c2             	cmovs  %edx,%eax
f0100c1e:	c1 f8 0c             	sar    $0xc,%eax
f0100c21:	89 c2                	mov    %eax,%edx
f0100c23:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100c29:	c1 e0 03             	shl    $0x3,%eax
f0100c2c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c31:	eb 23                	jmp    f0100c56 <page_init+0xac>
		pages[i].pp_ref = 0;
f0100c33:	89 c1                	mov    %eax,%ecx
f0100c35:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100c3b:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100c41:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100c43:	89 c3                	mov    %eax,%ebx
f0100c45:	03 1d 6c 69 11 f0    	add    0xf011696c,%ebx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	int kern_end = (int)ROUNDUP(((char*)pages) + (sizeof(struct PageInfo) * npages) - 0xf0000000, PGSIZE)/PGSIZE;
	for (i = kern_end; i < npages; i++) {
f0100c4b:	83 c2 01             	add    $0x1,%edx
f0100c4e:	83 c0 08             	add    $0x8,%eax
f0100c51:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100c56:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100c5c:	72 d5                	jb     f0100c33 <page_init+0x89>
f0100c5e:	84 c9                	test   %cl,%cl
f0100c60:	74 06                	je     f0100c68 <page_init+0xbe>
f0100c62:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100c68:	5b                   	pop    %ebx
f0100c69:	5e                   	pop    %esi
f0100c6a:	5d                   	pop    %ebp
f0100c6b:	c3                   	ret    

f0100c6c <page_alloc>:
// Returns NULL if out of free memory.
// Hint: use page2kva and memset
// page2kva()将物理地址转化为虚拟地址
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100c6c:	55                   	push   %ebp
f0100c6d:	89 e5                	mov    %esp,%ebp
f0100c6f:	53                   	push   %ebx
f0100c70:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
    if (page_free_list) {
f0100c73:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100c79:	85 db                	test   %ebx,%ebx
f0100c7b:	74 52                	je     f0100ccf <page_alloc+0x63>
        struct PageInfo *result = page_free_list;
        page_free_list = page_free_list->pp_link;
f0100c7d:	8b 03                	mov    (%ebx),%eax
f0100c7f:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
        if (alloc_flags & ALLOC_ZERO) {
f0100c84:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100c88:	74 45                	je     f0100ccf <page_alloc+0x63>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c8a:	89 d8                	mov    %ebx,%eax
f0100c8c:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100c92:	c1 f8 03             	sar    $0x3,%eax
f0100c95:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c98:	89 c2                	mov    %eax,%edx
f0100c9a:	c1 ea 0c             	shr    $0xc,%edx
f0100c9d:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100ca3:	72 12                	jb     f0100cb7 <page_alloc+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca5:	50                   	push   %eax
f0100ca6:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0100cab:	6a 52                	push   $0x52
f0100cad:	68 d4 42 10 f0       	push   $0xf01042d4
f0100cb2:	e8 d4 f3 ff ff       	call   f010008b <_panic>
            memset(page2kva(result), 0, PGSIZE);
f0100cb7:	83 ec 04             	sub    $0x4,%esp
f0100cba:	68 00 10 00 00       	push   $0x1000
f0100cbf:	6a 00                	push   $0x0
f0100cc1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cc6:	50                   	push   %eax
f0100cc7:	e8 13 25 00 00       	call   f01031df <memset>
f0100ccc:	83 c4 10             	add    $0x10,%esp
        return result;
    }
	else
		return NULL;

}
f0100ccf:	89 d8                	mov    %ebx,%eax
f0100cd1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100cd4:	c9                   	leave  
f0100cd5:	c3                   	ret    

f0100cd6 <page_free>:

// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
void
page_free(struct PageInfo *pp)
{
f0100cd6:	55                   	push   %ebp
f0100cd7:	89 e5                	mov    %esp,%ebp
f0100cd9:	83 ec 08             	sub    $0x8,%esp
f0100cdc:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	// 即要求free的时候，这个页没有被使用，也没有和其他页相关联
	assert(pp->pp_ref == 0 || pp->pp_link == NULL); 
f0100cdf:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ce4:	74 1e                	je     f0100d04 <page_free+0x2e>
f0100ce6:	83 38 00             	cmpl   $0x0,(%eax)
f0100ce9:	74 19                	je     f0100d04 <page_free+0x2e>
f0100ceb:	68 04 3c 10 f0       	push   $0xf0103c04
f0100cf0:	68 ee 42 10 f0       	push   $0xf01042ee
f0100cf5:	68 20 01 00 00       	push   $0x120
f0100cfa:	68 c8 42 10 f0       	push   $0xf01042c8
f0100cff:	e8 87 f3 ff ff       	call   f010008b <_panic>
	
    pp->pp_link = page_free_list;
f0100d04:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100d0a:	89 10                	mov    %edx,(%eax)
    page_free_list = pp; 
f0100d0c:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100d11:	c9                   	leave  
f0100d12:	c3                   	ret    

f0100d13 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d13:	55                   	push   %ebp
f0100d14:	89 e5                	mov    %esp,%ebp
f0100d16:	83 ec 08             	sub    $0x8,%esp
f0100d19:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d1c:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d20:	83 e8 01             	sub    $0x1,%eax
f0100d23:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d27:	66 85 c0             	test   %ax,%ax
f0100d2a:	75 0c                	jne    f0100d38 <page_decref+0x25>
		page_free(pp);
f0100d2c:	83 ec 0c             	sub    $0xc,%esp
f0100d2f:	52                   	push   %edx
f0100d30:	e8 a1 ff ff ff       	call   f0100cd6 <page_free>
f0100d35:	83 c4 10             	add    $0x10,%esp
}
f0100d38:	c9                   	leave  
f0100d39:	c3                   	ret    

f0100d3a <pgdir_walk>:
//PADDR:虚拟地址->物理地址
//page2kva(struct PageInfo *):物理页->虚拟页
//PTX:得到页表内索引
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d3a:	55                   	push   %ebp
f0100d3b:	89 e5                	mov    %esp,%ebp
f0100d3d:	57                   	push   %edi
f0100d3e:	56                   	push   %esi
f0100d3f:	53                   	push   %ebx
f0100d40:	83 ec 0c             	sub    $0xc,%esp
f0100d43:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	//pgdir 本身是虚拟地址
	pde_t *pde = NULL;
	pte_t *pgtable = NULL;
	struct PageInfo *pp;

	pde = &pgdir[PDX(va)];
f0100d46:	89 de                	mov    %ebx,%esi
f0100d48:	c1 ee 16             	shr    $0x16,%esi
f0100d4b:	c1 e6 02             	shl    $0x2,%esi
f0100d4e:	03 75 08             	add    0x8(%ebp),%esi
	if(*pde & PTE_P)//对应物理页存在
f0100d51:	8b 06                	mov    (%esi),%eax
f0100d53:	a8 01                	test   $0x1,%al
f0100d55:	74 2f                	je     f0100d86 <pgdir_walk+0x4c>
	{
		pgtable = (KADDR(PTE_ADDR(*pde)));
f0100d57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d5c:	89 c2                	mov    %eax,%edx
f0100d5e:	c1 ea 0c             	shr    $0xc,%edx
f0100d61:	39 15 64 69 11 f0    	cmp    %edx,0xf0116964
f0100d67:	77 15                	ja     f0100d7e <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d69:	50                   	push   %eax
f0100d6a:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0100d6f:	68 4b 01 00 00       	push   $0x14b
f0100d74:	68 c8 42 10 f0       	push   $0xf01042c8
f0100d79:	e8 0d f3 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100d7e:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100d84:	eb 77                	jmp    f0100dfd <pgdir_walk+0xc3>
	}
	// 对应物理页不存在
	else 
	{
		if(!create ||
f0100d86:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d8a:	74 7f                	je     f0100e0b <pgdir_walk+0xd1>
f0100d8c:	83 ec 0c             	sub    $0xc,%esp
f0100d8f:	6a 01                	push   $0x1
f0100d91:	e8 d6 fe ff ff       	call   f0100c6c <page_alloc>
f0100d96:	83 c4 10             	add    $0x10,%esp
f0100d99:	85 c0                	test   %eax,%eax
f0100d9b:	74 75                	je     f0100e12 <pgdir_walk+0xd8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d9d:	89 c1                	mov    %eax,%ecx
f0100d9f:	2b 0d 6c 69 11 f0    	sub    0xf011696c,%ecx
f0100da5:	c1 f9 03             	sar    $0x3,%ecx
f0100da8:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dab:	89 ca                	mov    %ecx,%edx
f0100dad:	c1 ea 0c             	shr    $0xc,%edx
f0100db0:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100db6:	72 12                	jb     f0100dca <pgdir_walk+0x90>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db8:	51                   	push   %ecx
f0100db9:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0100dbe:	6a 52                	push   $0x52
f0100dc0:	68 d4 42 10 f0       	push   $0xf01042d4
f0100dc5:	e8 c1 f2 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100dca:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100dd0:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f0100dd2:	85 ff                	test   %edi,%edi
f0100dd4:	74 43                	je     f0100e19 <pgdir_walk+0xdf>
		   !(pgtable = (pte_t*)page2kva(pp)))
		{
			return NULL;
		}

		pp->pp_ref++;
f0100dd6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ddb:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100de1:	77 15                	ja     f0100df8 <pgdir_walk+0xbe>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100de3:	57                   	push   %edi
f0100de4:	68 2c 3c 10 f0       	push   $0xf0103c2c
f0100de9:	68 58 01 00 00       	push   $0x158
f0100dee:	68 c8 42 10 f0       	push   $0xf01042c8
f0100df3:	e8 93 f2 ff ff       	call   f010008b <_panic>
		*pde = PADDR(pgtable) | PTE_P |PTE_W | PTE_U;
f0100df8:	83 c9 07             	or     $0x7,%ecx
f0100dfb:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f0100dfd:	c1 eb 0a             	shr    $0xa,%ebx
f0100e00:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100e06:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100e09:	eb 13                	jmp    f0100e1e <pgdir_walk+0xe4>
	{
		if(!create ||
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp)))
		{
			return NULL;
f0100e0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e10:	eb 0c                	jmp    f0100e1e <pgdir_walk+0xe4>
f0100e12:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e17:	eb 05                	jmp    f0100e1e <pgdir_walk+0xe4>
f0100e19:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P |PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];
}
f0100e1e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e21:	5b                   	pop    %ebx
f0100e22:	5e                   	pop    %esi
f0100e23:	5f                   	pop    %edi
f0100e24:	5d                   	pop    %ebp
f0100e25:	c3                   	ret    

f0100e26 <boot_map_region>:
// mapped pages.
// 
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e26:	55                   	push   %ebp
f0100e27:	89 e5                	mov    %esp,%ebp
f0100e29:	57                   	push   %edi
f0100e2a:	56                   	push   %esi
f0100e2b:	53                   	push   %ebx
f0100e2c:	83 ec 1c             	sub    $0x1c,%esp
f0100e2f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e32:	89 d7                	mov    %edx,%edi
f0100e34:	89 cb                	mov    %ecx,%ebx
	physaddr_t pa_next = pa;
	pte_t *    pte = NULL;//page table entrance

	ROUNDUP(size,PGSIZE);//page align

	assert(size%PGSIZE == 0 || cprintf("size:%x \n",size));
f0100e36:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f0100e3c:	75 1b                	jne    f0100e59 <boot_map_region+0x33>
f0100e3e:	c1 eb 0c             	shr    $0xc,%ebx
f0100e41:	89 5d e4             	mov    %ebx,-0x1c(%ebp)

	int temp = 0;
	for(temp = 0;temp < size/PGSIZE;temp++)
f0100e44:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100e47:	be 00 00 00 00       	mov    $0x0,%esi
	{
		pte = pgdir_walk(pgdir,(void *)va_next,1);
f0100e4c:	29 df                	sub    %ebx,%edi
		if(!pte)
		{
			return;
		}
		
		*pte = PTE_ADDR(pa_next) | perm | PTE_P;
f0100e4e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e51:	83 c8 01             	or     $0x1,%eax
f0100e54:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100e57:	eb 5c                	jmp    f0100eb5 <boot_map_region+0x8f>
	physaddr_t pa_next = pa;
	pte_t *    pte = NULL;//page table entrance

	ROUNDUP(size,PGSIZE);//page align

	assert(size%PGSIZE == 0 || cprintf("size:%x \n",size));
f0100e59:	83 ec 08             	sub    $0x8,%esp
f0100e5c:	51                   	push   %ecx
f0100e5d:	68 7e 43 10 f0       	push   $0xf010437e
f0100e62:	e8 8f 18 00 00       	call   f01026f6 <cprintf>
f0100e67:	83 c4 10             	add    $0x10,%esp
f0100e6a:	85 c0                	test   %eax,%eax
f0100e6c:	75 d0                	jne    f0100e3e <boot_map_region+0x18>
f0100e6e:	68 50 3c 10 f0       	push   $0xf0103c50
f0100e73:	68 ee 42 10 f0       	push   $0xf01042ee
f0100e78:	68 72 01 00 00       	push   $0x172
f0100e7d:	68 c8 42 10 f0       	push   $0xf01042c8
f0100e82:	e8 04 f2 ff ff       	call   f010008b <_panic>

	int temp = 0;
	for(temp = 0;temp < size/PGSIZE;temp++)
	{
		pte = pgdir_walk(pgdir,(void *)va_next,1);
f0100e87:	83 ec 04             	sub    $0x4,%esp
f0100e8a:	6a 01                	push   $0x1
f0100e8c:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100e8f:	50                   	push   %eax
f0100e90:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e93:	e8 a2 fe ff ff       	call   f0100d3a <pgdir_walk>

		if(!pte)
f0100e98:	83 c4 10             	add    $0x10,%esp
f0100e9b:	85 c0                	test   %eax,%eax
f0100e9d:	74 1b                	je     f0100eba <boot_map_region+0x94>
		{
			return;
		}
		
		*pte = PTE_ADDR(pa_next) | perm | PTE_P;
f0100e9f:	89 da                	mov    %ebx,%edx
f0100ea1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ea7:	0b 55 dc             	or     -0x24(%ebp),%edx
f0100eaa:	89 10                	mov    %edx,(%eax)
		pa_next += PGSIZE;
f0100eac:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	ROUNDUP(size,PGSIZE);//page align

	assert(size%PGSIZE == 0 || cprintf("size:%x \n",size));

	int temp = 0;
	for(temp = 0;temp < size/PGSIZE;temp++)
f0100eb2:	83 c6 01             	add    $0x1,%esi
f0100eb5:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100eb8:	75 cd                	jne    f0100e87 <boot_map_region+0x61>
		
		*pte = PTE_ADDR(pa_next) | perm | PTE_P;
		pa_next += PGSIZE;
		va_next += PGSIZE;
	}
}
f0100eba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ebd:	5b                   	pop    %ebx
f0100ebe:	5e                   	pop    %esi
f0100ebf:	5f                   	pop    %edi
f0100ec0:	5d                   	pop    %ebp
f0100ec1:	c3                   	ret    

f0100ec2 <page_lookup>:
//
// 检测va虚拟地址对应的物理页是否存在，不存在返回NULL
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ec2:	55                   	push   %ebp
f0100ec3:	89 e5                	mov    %esp,%ebp
f0100ec5:	53                   	push   %ebx
f0100ec6:	83 ec 08             	sub    $0x8,%esp
f0100ec9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir,va,0);
f0100ecc:	6a 00                	push   $0x0
f0100ece:	ff 75 0c             	pushl  0xc(%ebp)
f0100ed1:	ff 75 08             	pushl  0x8(%ebp)
f0100ed4:	e8 61 fe ff ff       	call   f0100d3a <pgdir_walk>

	if(!pte)
f0100ed9:	83 c4 10             	add    $0x10,%esp
f0100edc:	85 c0                	test   %eax,%eax
f0100ede:	74 32                	je     f0100f12 <page_lookup+0x50>
	{
		return NULL;
	}
	else if(pte_store)
f0100ee0:	85 db                	test   %ebx,%ebx
f0100ee2:	74 02                	je     f0100ee6 <page_lookup+0x24>
	{
		*pte_store = pte;
f0100ee4:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ee6:	8b 00                	mov    (%eax),%eax
f0100ee8:	c1 e8 0c             	shr    $0xc,%eax
f0100eeb:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100ef1:	72 14                	jb     f0100f07 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100ef3:	83 ec 04             	sub    $0x4,%esp
f0100ef6:	68 80 3c 10 f0       	push   $0xf0103c80
f0100efb:	6a 4b                	push   $0x4b
f0100efd:	68 d4 42 10 f0       	push   $0xf01042d4
f0100f02:	e8 84 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f07:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100f0d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	return pa2page(PTE_ADDR(*pte)); //用于remove
f0100f10:	eb 05                	jmp    f0100f17 <page_lookup+0x55>
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir,va,0);

	if(!pte)
	{
		return NULL;
f0100f12:	b8 00 00 00 00       	mov    $0x0,%eax
	else if(pte_store)
	{
		*pte_store = pte;
	}
	return pa2page(PTE_ADDR(*pte)); //用于remove
}
f0100f17:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f1a:	c9                   	leave  
f0100f1b:	c3                   	ret    

f0100f1c <page_remove>:
//   - remove页表的时候也要相应的在快表中remove掉
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
void
page_remove(pde_t *pgdir, void *va)
{
f0100f1c:	55                   	push   %ebp
f0100f1d:	89 e5                	mov    %esp,%ebp
f0100f1f:	56                   	push   %esi
f0100f20:	53                   	push   %ebx
f0100f21:	83 ec 14             	sub    $0x14,%esp
f0100f24:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t*  pte = pgdir_walk(pgdir,va,0);
f0100f2a:	6a 00                	push   $0x0
f0100f2c:	53                   	push   %ebx
f0100f2d:	56                   	push   %esi
f0100f2e:	e8 07 fe ff ff       	call   f0100d3a <pgdir_walk>
f0100f33:	89 45 f4             	mov    %eax,-0xc(%ebp)
	pte_t** pte_store = &pte;
	struct PageInfo* pp = page_lookup(pgdir,va,pte_store);
f0100f36:	83 c4 0c             	add    $0xc,%esp
f0100f39:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f3c:	50                   	push   %eax
f0100f3d:	53                   	push   %ebx
f0100f3e:	56                   	push   %esi
f0100f3f:	e8 7e ff ff ff       	call   f0100ec2 <page_lookup>

	if(!pp)
f0100f44:	83 c4 10             	add    $0x10,%esp
f0100f47:	85 c0                	test   %eax,%eax
f0100f49:	74 18                	je     f0100f63 <page_remove+0x47>
	{
		return ;
	}
	page_decref(pp); //将物理页的ref--
f0100f4b:	83 ec 0c             	sub    $0xc,%esp
f0100f4e:	50                   	push   %eax
f0100f4f:	e8 bf fd ff ff       	call   f0100d13 <page_decref>
					 //为什么不直接ref--呢？
					 //因为page_decref（pp）中不但进行ref--，当ref=0时会对物理页清除
	**pte_store = 0; //即把*pte置为0
f0100f54:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f57:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f5d:	0f 01 3b             	invlpg (%ebx)
f0100f60:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);//函数作用在快表中把va对应的项invalidate掉
}
f0100f63:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f66:	5b                   	pop    %ebx
f0100f67:	5e                   	pop    %esi
f0100f68:	5d                   	pop    %ebp
f0100f69:	c3                   	ret    

f0100f6a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f6a:	55                   	push   %ebp
f0100f6b:	89 e5                	mov    %esp,%ebp
f0100f6d:	57                   	push   %edi
f0100f6e:	56                   	push   %esi
f0100f6f:	53                   	push   %ebx
f0100f70:	83 ec 10             	sub    $0x10,%esp
f0100f73:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f76:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* pte = pgdir_walk(pgdir,va,0);
f0100f79:	6a 00                	push   $0x0
f0100f7b:	57                   	push   %edi
f0100f7c:	ff 75 08             	pushl  0x8(%ebp)
f0100f7f:	e8 b6 fd ff ff       	call   f0100d3a <pgdir_walk>
	physaddr_t ppa = page2pa(pp);

	if(pte)//如果pte已被占
f0100f84:	83 c4 10             	add    $0x10,%esp
f0100f87:	85 c0                	test   %eax,%eax
f0100f89:	74 27                	je     f0100fb2 <page_insert+0x48>
f0100f8b:	89 c6                	mov    %eax,%esi
	{
		if(*pte & PTE_P)
f0100f8d:	f6 00 01             	testb  $0x1,(%eax)
f0100f90:	74 0f                	je     f0100fa1 <page_insert+0x37>
		{
			page_remove(pgdir,va);//取消va与之物理页之间的关联
f0100f92:	83 ec 08             	sub    $0x8,%esp
f0100f95:	57                   	push   %edi
f0100f96:	ff 75 08             	pushl  0x8(%ebp)
f0100f99:	e8 7e ff ff ff       	call   f0100f1c <page_remove>
f0100f9e:	83 c4 10             	add    $0x10,%esp
		}	

		if(page_free_list == pp) //此处是特殊情况，即va再次映射到pp的时候，上面已经remove了，现在应该恢复！
f0100fa1:	3b 1d 3c 65 11 f0    	cmp    0xf011653c,%ebx
f0100fa7:	75 20                	jne    f0100fc9 <page_insert+0x5f>
		{
			page_free_list = page_free_list->pp_link; //更新page_free_list的head
f0100fa9:	8b 03                	mov    (%ebx),%eax
f0100fab:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
f0100fb0:	eb 17                	jmp    f0100fc9 <page_insert+0x5f>
		}
	}
	else
	{
		pte = pgdir_walk(pgdir,va,1);//creat=1
f0100fb2:	83 ec 04             	sub    $0x4,%esp
f0100fb5:	6a 01                	push   $0x1
f0100fb7:	57                   	push   %edi
f0100fb8:	ff 75 08             	pushl  0x8(%ebp)
f0100fbb:	e8 7a fd ff ff       	call   f0100d3a <pgdir_walk>
f0100fc0:	89 c6                	mov    %eax,%esi
		if(!pte)
f0100fc2:	83 c4 10             	add    $0x10,%esp
f0100fc5:	85 c0                	test   %eax,%eax
f0100fc7:	74 27                	je     f0100ff0 <page_insert+0x86>
		{
			return -E_NO_MEM;
		}	
	}

	*pte = page2pa(pp) | PTE_P | perm; //建立va与pp描写叙述物理页的联系
f0100fc9:	89 d8                	mov    %ebx,%eax
f0100fcb:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100fd1:	c1 f8 03             	sar    $0x3,%eax
f0100fd4:	c1 e0 0c             	shl    $0xc,%eax
f0100fd7:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fda:	83 ca 01             	or     $0x1,%edx
f0100fdd:	09 d0                	or     %edx,%eax
f0100fdf:	89 06                	mov    %eax,(%esi)

	pp->pp_ref++;
f0100fe1:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
f0100fe6:	0f 01 3f             	invlpg (%edi)
	tlb_invalidate(pgdir,va);
	return 0;
f0100fe9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fee:	eb 05                	jmp    f0100ff5 <page_insert+0x8b>
	else
	{
		pte = pgdir_walk(pgdir,va,1);//creat=1
		if(!pte)
		{
			return -E_NO_MEM;
f0100ff0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = page2pa(pp) | PTE_P | perm; //建立va与pp描写叙述物理页的联系

	pp->pp_ref++;
	tlb_invalidate(pgdir,va);
	return 0;
}
f0100ff5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ff8:	5b                   	pop    %ebx
f0100ff9:	5e                   	pop    %esi
f0100ffa:	5f                   	pop    %edi
f0100ffb:	5d                   	pop    %ebp
f0100ffc:	c3                   	ret    

f0100ffd <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100ffd:	55                   	push   %ebp
f0100ffe:	89 e5                	mov    %esp,%ebp
f0101000:	57                   	push   %edi
f0101001:	56                   	push   %esi
f0101002:	53                   	push   %ebx
f0101003:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101006:	6a 15                	push   $0x15
f0101008:	e8 82 16 00 00       	call   f010268f <mc146818_read>
f010100d:	89 c3                	mov    %eax,%ebx
f010100f:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101016:	e8 74 16 00 00       	call   f010268f <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010101b:	c1 e0 08             	shl    $0x8,%eax
f010101e:	09 d8                	or     %ebx,%eax
f0101020:	c1 e0 0a             	shl    $0xa,%eax
f0101023:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101029:	85 c0                	test   %eax,%eax
f010102b:	0f 48 c2             	cmovs  %edx,%eax
f010102e:	c1 f8 0c             	sar    $0xc,%eax
f0101031:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101036:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010103d:	e8 4d 16 00 00       	call   f010268f <mc146818_read>
f0101042:	89 c3                	mov    %eax,%ebx
f0101044:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010104b:	e8 3f 16 00 00       	call   f010268f <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101050:	c1 e0 08             	shl    $0x8,%eax
f0101053:	09 d8                	or     %ebx,%eax
f0101055:	c1 e0 0a             	shl    $0xa,%eax
f0101058:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010105e:	83 c4 10             	add    $0x10,%esp
f0101061:	85 c0                	test   %eax,%eax
f0101063:	0f 48 c2             	cmovs  %edx,%eax
f0101066:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101069:	85 c0                	test   %eax,%eax
f010106b:	74 0e                	je     f010107b <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010106d:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101073:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f0101079:	eb 0c                	jmp    f0101087 <mem_init+0x8a>
	else
		npages = npages_basemem;
f010107b:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f0101081:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101087:	c1 e0 0c             	shl    $0xc,%eax
f010108a:	c1 e8 0a             	shr    $0xa,%eax
f010108d:	50                   	push   %eax
f010108e:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f0101093:	c1 e0 0c             	shl    $0xc,%eax
f0101096:	c1 e8 0a             	shr    $0xa,%eax
f0101099:	50                   	push   %eax
f010109a:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010109f:	c1 e0 0c             	shl    $0xc,%eax
f01010a2:	c1 e8 0a             	shr    $0xa,%eax
f01010a5:	50                   	push   %eax
f01010a6:	68 a0 3c 10 f0       	push   $0xf0103ca0
f01010ab:	e8 46 16 00 00       	call   f01026f6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// 初始化页目录
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010b0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010b5:	e8 9c f7 ff ff       	call   f0100856 <boot_alloc>
f01010ba:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f01010bf:	83 c4 0c             	add    $0xc,%esp
f01010c2:	68 00 10 00 00       	push   $0x1000
f01010c7:	6a 00                	push   $0x0
f01010c9:	50                   	push   %eax
f01010ca:	e8 10 21 00 00       	call   f01031df <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010cf:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010d4:	83 c4 10             	add    $0x10,%esp
f01010d7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010dc:	77 15                	ja     f01010f3 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010de:	50                   	push   %eax
f01010df:	68 2c 3c 10 f0       	push   $0xf0103c2c
f01010e4:	68 80 00 00 00       	push   $0x80
f01010e9:	68 c8 42 10 f0       	push   $0xf01042c8
f01010ee:	e8 98 ef ff ff       	call   f010008b <_panic>
f01010f3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010f9:	83 ca 05             	or     $0x5,%edx
f01010fc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)

	//////////////////////////////////////////////////////////////////////
	// 定义一个pages数组，对于每个物理页都有相应的
	// PageInfo在pages数组里
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(sizeof(struct PageInfo) * npages);
f0101102:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101107:	c1 e0 03             	shl    $0x3,%eax
f010110a:	e8 47 f7 ff ff       	call   f0100856 <boot_alloc>
f010110f:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages,0,sizeof(struct PageInfo)*npages);
f0101114:	83 ec 04             	sub    $0x4,%esp
f0101117:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f010111d:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101124:	52                   	push   %edx
f0101125:	6a 00                	push   $0x0
f0101127:	50                   	push   %eax
f0101128:	e8 b2 20 00 00       	call   f01031df <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010112d:	e8 78 fa ff ff       	call   f0100baa <page_init>

	check_page_free_list(1);
f0101132:	b8 01 00 00 00       	mov    $0x1,%eax
f0101137:	e8 ba f7 ff ff       	call   f01008f6 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010113c:	83 c4 10             	add    $0x10,%esp
f010113f:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f0101146:	75 17                	jne    f010115f <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0101148:	83 ec 04             	sub    $0x4,%esp
f010114b:	68 88 43 10 f0       	push   $0xf0104388
f0101150:	68 4c 02 00 00       	push   $0x24c
f0101155:	68 c8 42 10 f0       	push   $0xf01042c8
f010115a:	e8 2c ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010115f:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101164:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101169:	eb 05                	jmp    f0101170 <mem_init+0x173>
		++nfree;
f010116b:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010116e:	8b 00                	mov    (%eax),%eax
f0101170:	85 c0                	test   %eax,%eax
f0101172:	75 f7                	jne    f010116b <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101174:	83 ec 0c             	sub    $0xc,%esp
f0101177:	6a 00                	push   $0x0
f0101179:	e8 ee fa ff ff       	call   f0100c6c <page_alloc>
f010117e:	89 c7                	mov    %eax,%edi
f0101180:	83 c4 10             	add    $0x10,%esp
f0101183:	85 c0                	test   %eax,%eax
f0101185:	75 19                	jne    f01011a0 <mem_init+0x1a3>
f0101187:	68 a3 43 10 f0       	push   $0xf01043a3
f010118c:	68 ee 42 10 f0       	push   $0xf01042ee
f0101191:	68 54 02 00 00       	push   $0x254
f0101196:	68 c8 42 10 f0       	push   $0xf01042c8
f010119b:	e8 eb ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011a0:	83 ec 0c             	sub    $0xc,%esp
f01011a3:	6a 00                	push   $0x0
f01011a5:	e8 c2 fa ff ff       	call   f0100c6c <page_alloc>
f01011aa:	89 c6                	mov    %eax,%esi
f01011ac:	83 c4 10             	add    $0x10,%esp
f01011af:	85 c0                	test   %eax,%eax
f01011b1:	75 19                	jne    f01011cc <mem_init+0x1cf>
f01011b3:	68 b9 43 10 f0       	push   $0xf01043b9
f01011b8:	68 ee 42 10 f0       	push   $0xf01042ee
f01011bd:	68 55 02 00 00       	push   $0x255
f01011c2:	68 c8 42 10 f0       	push   $0xf01042c8
f01011c7:	e8 bf ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011cc:	83 ec 0c             	sub    $0xc,%esp
f01011cf:	6a 00                	push   $0x0
f01011d1:	e8 96 fa ff ff       	call   f0100c6c <page_alloc>
f01011d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011d9:	83 c4 10             	add    $0x10,%esp
f01011dc:	85 c0                	test   %eax,%eax
f01011de:	75 19                	jne    f01011f9 <mem_init+0x1fc>
f01011e0:	68 cf 43 10 f0       	push   $0xf01043cf
f01011e5:	68 ee 42 10 f0       	push   $0xf01042ee
f01011ea:	68 56 02 00 00       	push   $0x256
f01011ef:	68 c8 42 10 f0       	push   $0xf01042c8
f01011f4:	e8 92 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011f9:	39 f7                	cmp    %esi,%edi
f01011fb:	75 19                	jne    f0101216 <mem_init+0x219>
f01011fd:	68 e5 43 10 f0       	push   $0xf01043e5
f0101202:	68 ee 42 10 f0       	push   $0xf01042ee
f0101207:	68 59 02 00 00       	push   $0x259
f010120c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101211:	e8 75 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101216:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101219:	39 c6                	cmp    %eax,%esi
f010121b:	74 04                	je     f0101221 <mem_init+0x224>
f010121d:	39 c7                	cmp    %eax,%edi
f010121f:	75 19                	jne    f010123a <mem_init+0x23d>
f0101221:	68 dc 3c 10 f0       	push   $0xf0103cdc
f0101226:	68 ee 42 10 f0       	push   $0xf01042ee
f010122b:	68 5a 02 00 00       	push   $0x25a
f0101230:	68 c8 42 10 f0       	push   $0xf01042c8
f0101235:	e8 51 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010123a:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101240:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0101246:	c1 e2 0c             	shl    $0xc,%edx
f0101249:	89 f8                	mov    %edi,%eax
f010124b:	29 c8                	sub    %ecx,%eax
f010124d:	c1 f8 03             	sar    $0x3,%eax
f0101250:	c1 e0 0c             	shl    $0xc,%eax
f0101253:	39 d0                	cmp    %edx,%eax
f0101255:	72 19                	jb     f0101270 <mem_init+0x273>
f0101257:	68 f7 43 10 f0       	push   $0xf01043f7
f010125c:	68 ee 42 10 f0       	push   $0xf01042ee
f0101261:	68 5b 02 00 00       	push   $0x25b
f0101266:	68 c8 42 10 f0       	push   $0xf01042c8
f010126b:	e8 1b ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101270:	89 f0                	mov    %esi,%eax
f0101272:	29 c8                	sub    %ecx,%eax
f0101274:	c1 f8 03             	sar    $0x3,%eax
f0101277:	c1 e0 0c             	shl    $0xc,%eax
f010127a:	39 c2                	cmp    %eax,%edx
f010127c:	77 19                	ja     f0101297 <mem_init+0x29a>
f010127e:	68 14 44 10 f0       	push   $0xf0104414
f0101283:	68 ee 42 10 f0       	push   $0xf01042ee
f0101288:	68 5c 02 00 00       	push   $0x25c
f010128d:	68 c8 42 10 f0       	push   $0xf01042c8
f0101292:	e8 f4 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101297:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010129a:	29 c8                	sub    %ecx,%eax
f010129c:	c1 f8 03             	sar    $0x3,%eax
f010129f:	c1 e0 0c             	shl    $0xc,%eax
f01012a2:	39 c2                	cmp    %eax,%edx
f01012a4:	77 19                	ja     f01012bf <mem_init+0x2c2>
f01012a6:	68 31 44 10 f0       	push   $0xf0104431
f01012ab:	68 ee 42 10 f0       	push   $0xf01042ee
f01012b0:	68 5d 02 00 00       	push   $0x25d
f01012b5:	68 c8 42 10 f0       	push   $0xf01042c8
f01012ba:	e8 cc ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012bf:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012c4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012c7:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012ce:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012d1:	83 ec 0c             	sub    $0xc,%esp
f01012d4:	6a 00                	push   $0x0
f01012d6:	e8 91 f9 ff ff       	call   f0100c6c <page_alloc>
f01012db:	83 c4 10             	add    $0x10,%esp
f01012de:	85 c0                	test   %eax,%eax
f01012e0:	74 19                	je     f01012fb <mem_init+0x2fe>
f01012e2:	68 4e 44 10 f0       	push   $0xf010444e
f01012e7:	68 ee 42 10 f0       	push   $0xf01042ee
f01012ec:	68 64 02 00 00       	push   $0x264
f01012f1:	68 c8 42 10 f0       	push   $0xf01042c8
f01012f6:	e8 90 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012fb:	83 ec 0c             	sub    $0xc,%esp
f01012fe:	57                   	push   %edi
f01012ff:	e8 d2 f9 ff ff       	call   f0100cd6 <page_free>
	page_free(pp1);
f0101304:	89 34 24             	mov    %esi,(%esp)
f0101307:	e8 ca f9 ff ff       	call   f0100cd6 <page_free>
	page_free(pp2);
f010130c:	83 c4 04             	add    $0x4,%esp
f010130f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101312:	e8 bf f9 ff ff       	call   f0100cd6 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101317:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010131e:	e8 49 f9 ff ff       	call   f0100c6c <page_alloc>
f0101323:	89 c6                	mov    %eax,%esi
f0101325:	83 c4 10             	add    $0x10,%esp
f0101328:	85 c0                	test   %eax,%eax
f010132a:	75 19                	jne    f0101345 <mem_init+0x348>
f010132c:	68 a3 43 10 f0       	push   $0xf01043a3
f0101331:	68 ee 42 10 f0       	push   $0xf01042ee
f0101336:	68 6b 02 00 00       	push   $0x26b
f010133b:	68 c8 42 10 f0       	push   $0xf01042c8
f0101340:	e8 46 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101345:	83 ec 0c             	sub    $0xc,%esp
f0101348:	6a 00                	push   $0x0
f010134a:	e8 1d f9 ff ff       	call   f0100c6c <page_alloc>
f010134f:	89 c7                	mov    %eax,%edi
f0101351:	83 c4 10             	add    $0x10,%esp
f0101354:	85 c0                	test   %eax,%eax
f0101356:	75 19                	jne    f0101371 <mem_init+0x374>
f0101358:	68 b9 43 10 f0       	push   $0xf01043b9
f010135d:	68 ee 42 10 f0       	push   $0xf01042ee
f0101362:	68 6c 02 00 00       	push   $0x26c
f0101367:	68 c8 42 10 f0       	push   $0xf01042c8
f010136c:	e8 1a ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101371:	83 ec 0c             	sub    $0xc,%esp
f0101374:	6a 00                	push   $0x0
f0101376:	e8 f1 f8 ff ff       	call   f0100c6c <page_alloc>
f010137b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010137e:	83 c4 10             	add    $0x10,%esp
f0101381:	85 c0                	test   %eax,%eax
f0101383:	75 19                	jne    f010139e <mem_init+0x3a1>
f0101385:	68 cf 43 10 f0       	push   $0xf01043cf
f010138a:	68 ee 42 10 f0       	push   $0xf01042ee
f010138f:	68 6d 02 00 00       	push   $0x26d
f0101394:	68 c8 42 10 f0       	push   $0xf01042c8
f0101399:	e8 ed ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010139e:	39 fe                	cmp    %edi,%esi
f01013a0:	75 19                	jne    f01013bb <mem_init+0x3be>
f01013a2:	68 e5 43 10 f0       	push   $0xf01043e5
f01013a7:	68 ee 42 10 f0       	push   $0xf01042ee
f01013ac:	68 6f 02 00 00       	push   $0x26f
f01013b1:	68 c8 42 10 f0       	push   $0xf01042c8
f01013b6:	e8 d0 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013be:	39 c7                	cmp    %eax,%edi
f01013c0:	74 04                	je     f01013c6 <mem_init+0x3c9>
f01013c2:	39 c6                	cmp    %eax,%esi
f01013c4:	75 19                	jne    f01013df <mem_init+0x3e2>
f01013c6:	68 dc 3c 10 f0       	push   $0xf0103cdc
f01013cb:	68 ee 42 10 f0       	push   $0xf01042ee
f01013d0:	68 70 02 00 00       	push   $0x270
f01013d5:	68 c8 42 10 f0       	push   $0xf01042c8
f01013da:	e8 ac ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013df:	83 ec 0c             	sub    $0xc,%esp
f01013e2:	6a 00                	push   $0x0
f01013e4:	e8 83 f8 ff ff       	call   f0100c6c <page_alloc>
f01013e9:	83 c4 10             	add    $0x10,%esp
f01013ec:	85 c0                	test   %eax,%eax
f01013ee:	74 19                	je     f0101409 <mem_init+0x40c>
f01013f0:	68 4e 44 10 f0       	push   $0xf010444e
f01013f5:	68 ee 42 10 f0       	push   $0xf01042ee
f01013fa:	68 71 02 00 00       	push   $0x271
f01013ff:	68 c8 42 10 f0       	push   $0xf01042c8
f0101404:	e8 82 ec ff ff       	call   f010008b <_panic>
f0101409:	89 f0                	mov    %esi,%eax
f010140b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101411:	c1 f8 03             	sar    $0x3,%eax
f0101414:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101417:	89 c2                	mov    %eax,%edx
f0101419:	c1 ea 0c             	shr    $0xc,%edx
f010141c:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101422:	72 12                	jb     f0101436 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101424:	50                   	push   %eax
f0101425:	68 1c 3b 10 f0       	push   $0xf0103b1c
f010142a:	6a 52                	push   $0x52
f010142c:	68 d4 42 10 f0       	push   $0xf01042d4
f0101431:	e8 55 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101436:	83 ec 04             	sub    $0x4,%esp
f0101439:	68 00 10 00 00       	push   $0x1000
f010143e:	6a 01                	push   $0x1
f0101440:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101445:	50                   	push   %eax
f0101446:	e8 94 1d 00 00       	call   f01031df <memset>
	page_free(pp0);
f010144b:	89 34 24             	mov    %esi,(%esp)
f010144e:	e8 83 f8 ff ff       	call   f0100cd6 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101453:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010145a:	e8 0d f8 ff ff       	call   f0100c6c <page_alloc>
f010145f:	83 c4 10             	add    $0x10,%esp
f0101462:	85 c0                	test   %eax,%eax
f0101464:	75 19                	jne    f010147f <mem_init+0x482>
f0101466:	68 5d 44 10 f0       	push   $0xf010445d
f010146b:	68 ee 42 10 f0       	push   $0xf01042ee
f0101470:	68 76 02 00 00       	push   $0x276
f0101475:	68 c8 42 10 f0       	push   $0xf01042c8
f010147a:	e8 0c ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010147f:	39 c6                	cmp    %eax,%esi
f0101481:	74 19                	je     f010149c <mem_init+0x49f>
f0101483:	68 7b 44 10 f0       	push   $0xf010447b
f0101488:	68 ee 42 10 f0       	push   $0xf01042ee
f010148d:	68 77 02 00 00       	push   $0x277
f0101492:	68 c8 42 10 f0       	push   $0xf01042c8
f0101497:	e8 ef eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010149c:	89 f0                	mov    %esi,%eax
f010149e:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01014a4:	c1 f8 03             	sar    $0x3,%eax
f01014a7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014aa:	89 c2                	mov    %eax,%edx
f01014ac:	c1 ea 0c             	shr    $0xc,%edx
f01014af:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014b5:	72 12                	jb     f01014c9 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014b7:	50                   	push   %eax
f01014b8:	68 1c 3b 10 f0       	push   $0xf0103b1c
f01014bd:	6a 52                	push   $0x52
f01014bf:	68 d4 42 10 f0       	push   $0xf01042d4
f01014c4:	e8 c2 eb ff ff       	call   f010008b <_panic>
f01014c9:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014cf:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014d5:	80 38 00             	cmpb   $0x0,(%eax)
f01014d8:	74 19                	je     f01014f3 <mem_init+0x4f6>
f01014da:	68 8b 44 10 f0       	push   $0xf010448b
f01014df:	68 ee 42 10 f0       	push   $0xf01042ee
f01014e4:	68 7a 02 00 00       	push   $0x27a
f01014e9:	68 c8 42 10 f0       	push   $0xf01042c8
f01014ee:	e8 98 eb ff ff       	call   f010008b <_panic>
f01014f3:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014f6:	39 d0                	cmp    %edx,%eax
f01014f8:	75 db                	jne    f01014d5 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014fa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014fd:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101502:	83 ec 0c             	sub    $0xc,%esp
f0101505:	56                   	push   %esi
f0101506:	e8 cb f7 ff ff       	call   f0100cd6 <page_free>
	page_free(pp1);
f010150b:	89 3c 24             	mov    %edi,(%esp)
f010150e:	e8 c3 f7 ff ff       	call   f0100cd6 <page_free>
	page_free(pp2);
f0101513:	83 c4 04             	add    $0x4,%esp
f0101516:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101519:	e8 b8 f7 ff ff       	call   f0100cd6 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010151e:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101523:	83 c4 10             	add    $0x10,%esp
f0101526:	eb 05                	jmp    f010152d <mem_init+0x530>
		--nfree;
f0101528:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010152b:	8b 00                	mov    (%eax),%eax
f010152d:	85 c0                	test   %eax,%eax
f010152f:	75 f7                	jne    f0101528 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101531:	85 db                	test   %ebx,%ebx
f0101533:	74 19                	je     f010154e <mem_init+0x551>
f0101535:	68 95 44 10 f0       	push   $0xf0104495
f010153a:	68 ee 42 10 f0       	push   $0xf01042ee
f010153f:	68 87 02 00 00       	push   $0x287
f0101544:	68 c8 42 10 f0       	push   $0xf01042c8
f0101549:	e8 3d eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010154e:	83 ec 0c             	sub    $0xc,%esp
f0101551:	68 fc 3c 10 f0       	push   $0xf0103cfc
f0101556:	e8 9b 11 00 00       	call   f01026f6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010155b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101562:	e8 05 f7 ff ff       	call   f0100c6c <page_alloc>
f0101567:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010156a:	83 c4 10             	add    $0x10,%esp
f010156d:	85 c0                	test   %eax,%eax
f010156f:	75 19                	jne    f010158a <mem_init+0x58d>
f0101571:	68 a3 43 10 f0       	push   $0xf01043a3
f0101576:	68 ee 42 10 f0       	push   $0xf01042ee
f010157b:	68 e0 02 00 00       	push   $0x2e0
f0101580:	68 c8 42 10 f0       	push   $0xf01042c8
f0101585:	e8 01 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010158a:	83 ec 0c             	sub    $0xc,%esp
f010158d:	6a 00                	push   $0x0
f010158f:	e8 d8 f6 ff ff       	call   f0100c6c <page_alloc>
f0101594:	89 c3                	mov    %eax,%ebx
f0101596:	83 c4 10             	add    $0x10,%esp
f0101599:	85 c0                	test   %eax,%eax
f010159b:	75 19                	jne    f01015b6 <mem_init+0x5b9>
f010159d:	68 b9 43 10 f0       	push   $0xf01043b9
f01015a2:	68 ee 42 10 f0       	push   $0xf01042ee
f01015a7:	68 e1 02 00 00       	push   $0x2e1
f01015ac:	68 c8 42 10 f0       	push   $0xf01042c8
f01015b1:	e8 d5 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015b6:	83 ec 0c             	sub    $0xc,%esp
f01015b9:	6a 00                	push   $0x0
f01015bb:	e8 ac f6 ff ff       	call   f0100c6c <page_alloc>
f01015c0:	89 c6                	mov    %eax,%esi
f01015c2:	83 c4 10             	add    $0x10,%esp
f01015c5:	85 c0                	test   %eax,%eax
f01015c7:	75 19                	jne    f01015e2 <mem_init+0x5e5>
f01015c9:	68 cf 43 10 f0       	push   $0xf01043cf
f01015ce:	68 ee 42 10 f0       	push   $0xf01042ee
f01015d3:	68 e2 02 00 00       	push   $0x2e2
f01015d8:	68 c8 42 10 f0       	push   $0xf01042c8
f01015dd:	e8 a9 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015e2:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015e5:	75 19                	jne    f0101600 <mem_init+0x603>
f01015e7:	68 e5 43 10 f0       	push   $0xf01043e5
f01015ec:	68 ee 42 10 f0       	push   $0xf01042ee
f01015f1:	68 e5 02 00 00       	push   $0x2e5
f01015f6:	68 c8 42 10 f0       	push   $0xf01042c8
f01015fb:	e8 8b ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101600:	39 c3                	cmp    %eax,%ebx
f0101602:	74 05                	je     f0101609 <mem_init+0x60c>
f0101604:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101607:	75 19                	jne    f0101622 <mem_init+0x625>
f0101609:	68 dc 3c 10 f0       	push   $0xf0103cdc
f010160e:	68 ee 42 10 f0       	push   $0xf01042ee
f0101613:	68 e6 02 00 00       	push   $0x2e6
f0101618:	68 c8 42 10 f0       	push   $0xf01042c8
f010161d:	e8 69 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101622:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101627:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010162a:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101631:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101634:	83 ec 0c             	sub    $0xc,%esp
f0101637:	6a 00                	push   $0x0
f0101639:	e8 2e f6 ff ff       	call   f0100c6c <page_alloc>
f010163e:	83 c4 10             	add    $0x10,%esp
f0101641:	85 c0                	test   %eax,%eax
f0101643:	74 19                	je     f010165e <mem_init+0x661>
f0101645:	68 4e 44 10 f0       	push   $0xf010444e
f010164a:	68 ee 42 10 f0       	push   $0xf01042ee
f010164f:	68 ed 02 00 00       	push   $0x2ed
f0101654:	68 c8 42 10 f0       	push   $0xf01042c8
f0101659:	e8 2d ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010165e:	83 ec 04             	sub    $0x4,%esp
f0101661:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101664:	50                   	push   %eax
f0101665:	6a 00                	push   $0x0
f0101667:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010166d:	e8 50 f8 ff ff       	call   f0100ec2 <page_lookup>
f0101672:	83 c4 10             	add    $0x10,%esp
f0101675:	85 c0                	test   %eax,%eax
f0101677:	74 19                	je     f0101692 <mem_init+0x695>
f0101679:	68 1c 3d 10 f0       	push   $0xf0103d1c
f010167e:	68 ee 42 10 f0       	push   $0xf01042ee
f0101683:	68 f0 02 00 00       	push   $0x2f0
f0101688:	68 c8 42 10 f0       	push   $0xf01042c8
f010168d:	e8 f9 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101692:	6a 02                	push   $0x2
f0101694:	6a 00                	push   $0x0
f0101696:	53                   	push   %ebx
f0101697:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010169d:	e8 c8 f8 ff ff       	call   f0100f6a <page_insert>
f01016a2:	83 c4 10             	add    $0x10,%esp
f01016a5:	85 c0                	test   %eax,%eax
f01016a7:	78 19                	js     f01016c2 <mem_init+0x6c5>
f01016a9:	68 54 3d 10 f0       	push   $0xf0103d54
f01016ae:	68 ee 42 10 f0       	push   $0xf01042ee
f01016b3:	68 f3 02 00 00       	push   $0x2f3
f01016b8:	68 c8 42 10 f0       	push   $0xf01042c8
f01016bd:	e8 c9 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016c2:	83 ec 0c             	sub    $0xc,%esp
f01016c5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016c8:	e8 09 f6 ff ff       	call   f0100cd6 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016cd:	6a 02                	push   $0x2
f01016cf:	6a 00                	push   $0x0
f01016d1:	53                   	push   %ebx
f01016d2:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016d8:	e8 8d f8 ff ff       	call   f0100f6a <page_insert>
f01016dd:	83 c4 20             	add    $0x20,%esp
f01016e0:	85 c0                	test   %eax,%eax
f01016e2:	74 19                	je     f01016fd <mem_init+0x700>
f01016e4:	68 84 3d 10 f0       	push   $0xf0103d84
f01016e9:	68 ee 42 10 f0       	push   $0xf01042ee
f01016ee:	68 f7 02 00 00       	push   $0x2f7
f01016f3:	68 c8 42 10 f0       	push   $0xf01042c8
f01016f8:	e8 8e e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016fd:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101703:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101708:	89 c1                	mov    %eax,%ecx
f010170a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010170d:	8b 17                	mov    (%edi),%edx
f010170f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101715:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101718:	29 c8                	sub    %ecx,%eax
f010171a:	c1 f8 03             	sar    $0x3,%eax
f010171d:	c1 e0 0c             	shl    $0xc,%eax
f0101720:	39 c2                	cmp    %eax,%edx
f0101722:	74 19                	je     f010173d <mem_init+0x740>
f0101724:	68 b4 3d 10 f0       	push   $0xf0103db4
f0101729:	68 ee 42 10 f0       	push   $0xf01042ee
f010172e:	68 f8 02 00 00       	push   $0x2f8
f0101733:	68 c8 42 10 f0       	push   $0xf01042c8
f0101738:	e8 4e e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010173d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101742:	89 f8                	mov    %edi,%eax
f0101744:	e8 49 f1 ff ff       	call   f0100892 <check_va2pa>
f0101749:	89 da                	mov    %ebx,%edx
f010174b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010174e:	c1 fa 03             	sar    $0x3,%edx
f0101751:	c1 e2 0c             	shl    $0xc,%edx
f0101754:	39 d0                	cmp    %edx,%eax
f0101756:	74 19                	je     f0101771 <mem_init+0x774>
f0101758:	68 dc 3d 10 f0       	push   $0xf0103ddc
f010175d:	68 ee 42 10 f0       	push   $0xf01042ee
f0101762:	68 f9 02 00 00       	push   $0x2f9
f0101767:	68 c8 42 10 f0       	push   $0xf01042c8
f010176c:	e8 1a e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101771:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101776:	74 19                	je     f0101791 <mem_init+0x794>
f0101778:	68 a0 44 10 f0       	push   $0xf01044a0
f010177d:	68 ee 42 10 f0       	push   $0xf01042ee
f0101782:	68 fa 02 00 00       	push   $0x2fa
f0101787:	68 c8 42 10 f0       	push   $0xf01042c8
f010178c:	e8 fa e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101791:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101794:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101799:	74 19                	je     f01017b4 <mem_init+0x7b7>
f010179b:	68 b1 44 10 f0       	push   $0xf01044b1
f01017a0:	68 ee 42 10 f0       	push   $0xf01042ee
f01017a5:	68 fb 02 00 00       	push   $0x2fb
f01017aa:	68 c8 42 10 f0       	push   $0xf01042c8
f01017af:	e8 d7 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017b4:	6a 02                	push   $0x2
f01017b6:	68 00 10 00 00       	push   $0x1000
f01017bb:	56                   	push   %esi
f01017bc:	57                   	push   %edi
f01017bd:	e8 a8 f7 ff ff       	call   f0100f6a <page_insert>
f01017c2:	83 c4 10             	add    $0x10,%esp
f01017c5:	85 c0                	test   %eax,%eax
f01017c7:	74 19                	je     f01017e2 <mem_init+0x7e5>
f01017c9:	68 0c 3e 10 f0       	push   $0xf0103e0c
f01017ce:	68 ee 42 10 f0       	push   $0xf01042ee
f01017d3:	68 fe 02 00 00       	push   $0x2fe
f01017d8:	68 c8 42 10 f0       	push   $0xf01042c8
f01017dd:	e8 a9 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017e2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017e7:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01017ec:	e8 a1 f0 ff ff       	call   f0100892 <check_va2pa>
f01017f1:	89 f2                	mov    %esi,%edx
f01017f3:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01017f9:	c1 fa 03             	sar    $0x3,%edx
f01017fc:	c1 e2 0c             	shl    $0xc,%edx
f01017ff:	39 d0                	cmp    %edx,%eax
f0101801:	74 19                	je     f010181c <mem_init+0x81f>
f0101803:	68 48 3e 10 f0       	push   $0xf0103e48
f0101808:	68 ee 42 10 f0       	push   $0xf01042ee
f010180d:	68 ff 02 00 00       	push   $0x2ff
f0101812:	68 c8 42 10 f0       	push   $0xf01042c8
f0101817:	e8 6f e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010181c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101821:	74 19                	je     f010183c <mem_init+0x83f>
f0101823:	68 c2 44 10 f0       	push   $0xf01044c2
f0101828:	68 ee 42 10 f0       	push   $0xf01042ee
f010182d:	68 00 03 00 00       	push   $0x300
f0101832:	68 c8 42 10 f0       	push   $0xf01042c8
f0101837:	e8 4f e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010183c:	83 ec 0c             	sub    $0xc,%esp
f010183f:	6a 00                	push   $0x0
f0101841:	e8 26 f4 ff ff       	call   f0100c6c <page_alloc>
f0101846:	83 c4 10             	add    $0x10,%esp
f0101849:	85 c0                	test   %eax,%eax
f010184b:	74 19                	je     f0101866 <mem_init+0x869>
f010184d:	68 4e 44 10 f0       	push   $0xf010444e
f0101852:	68 ee 42 10 f0       	push   $0xf01042ee
f0101857:	68 03 03 00 00       	push   $0x303
f010185c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101861:	e8 25 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101866:	6a 02                	push   $0x2
f0101868:	68 00 10 00 00       	push   $0x1000
f010186d:	56                   	push   %esi
f010186e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101874:	e8 f1 f6 ff ff       	call   f0100f6a <page_insert>
f0101879:	83 c4 10             	add    $0x10,%esp
f010187c:	85 c0                	test   %eax,%eax
f010187e:	74 19                	je     f0101899 <mem_init+0x89c>
f0101880:	68 0c 3e 10 f0       	push   $0xf0103e0c
f0101885:	68 ee 42 10 f0       	push   $0xf01042ee
f010188a:	68 06 03 00 00       	push   $0x306
f010188f:	68 c8 42 10 f0       	push   $0xf01042c8
f0101894:	e8 f2 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101899:	ba 00 10 00 00       	mov    $0x1000,%edx
f010189e:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01018a3:	e8 ea ef ff ff       	call   f0100892 <check_va2pa>
f01018a8:	89 f2                	mov    %esi,%edx
f01018aa:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01018b0:	c1 fa 03             	sar    $0x3,%edx
f01018b3:	c1 e2 0c             	shl    $0xc,%edx
f01018b6:	39 d0                	cmp    %edx,%eax
f01018b8:	74 19                	je     f01018d3 <mem_init+0x8d6>
f01018ba:	68 48 3e 10 f0       	push   $0xf0103e48
f01018bf:	68 ee 42 10 f0       	push   $0xf01042ee
f01018c4:	68 07 03 00 00       	push   $0x307
f01018c9:	68 c8 42 10 f0       	push   $0xf01042c8
f01018ce:	e8 b8 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018d3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018d8:	74 19                	je     f01018f3 <mem_init+0x8f6>
f01018da:	68 c2 44 10 f0       	push   $0xf01044c2
f01018df:	68 ee 42 10 f0       	push   $0xf01042ee
f01018e4:	68 08 03 00 00       	push   $0x308
f01018e9:	68 c8 42 10 f0       	push   $0xf01042c8
f01018ee:	e8 98 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018f3:	83 ec 0c             	sub    $0xc,%esp
f01018f6:	6a 00                	push   $0x0
f01018f8:	e8 6f f3 ff ff       	call   f0100c6c <page_alloc>
f01018fd:	83 c4 10             	add    $0x10,%esp
f0101900:	85 c0                	test   %eax,%eax
f0101902:	74 19                	je     f010191d <mem_init+0x920>
f0101904:	68 4e 44 10 f0       	push   $0xf010444e
f0101909:	68 ee 42 10 f0       	push   $0xf01042ee
f010190e:	68 0c 03 00 00       	push   $0x30c
f0101913:	68 c8 42 10 f0       	push   $0xf01042c8
f0101918:	e8 6e e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010191d:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f0101923:	8b 02                	mov    (%edx),%eax
f0101925:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010192a:	89 c1                	mov    %eax,%ecx
f010192c:	c1 e9 0c             	shr    $0xc,%ecx
f010192f:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0101935:	72 15                	jb     f010194c <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101937:	50                   	push   %eax
f0101938:	68 1c 3b 10 f0       	push   $0xf0103b1c
f010193d:	68 0f 03 00 00       	push   $0x30f
f0101942:	68 c8 42 10 f0       	push   $0xf01042c8
f0101947:	e8 3f e7 ff ff       	call   f010008b <_panic>
f010194c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101951:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101954:	83 ec 04             	sub    $0x4,%esp
f0101957:	6a 00                	push   $0x0
f0101959:	68 00 10 00 00       	push   $0x1000
f010195e:	52                   	push   %edx
f010195f:	e8 d6 f3 ff ff       	call   f0100d3a <pgdir_walk>
f0101964:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101967:	8d 51 04             	lea    0x4(%ecx),%edx
f010196a:	83 c4 10             	add    $0x10,%esp
f010196d:	39 d0                	cmp    %edx,%eax
f010196f:	74 19                	je     f010198a <mem_init+0x98d>
f0101971:	68 78 3e 10 f0       	push   $0xf0103e78
f0101976:	68 ee 42 10 f0       	push   $0xf01042ee
f010197b:	68 10 03 00 00       	push   $0x310
f0101980:	68 c8 42 10 f0       	push   $0xf01042c8
f0101985:	e8 01 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010198a:	6a 06                	push   $0x6
f010198c:	68 00 10 00 00       	push   $0x1000
f0101991:	56                   	push   %esi
f0101992:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101998:	e8 cd f5 ff ff       	call   f0100f6a <page_insert>
f010199d:	83 c4 10             	add    $0x10,%esp
f01019a0:	85 c0                	test   %eax,%eax
f01019a2:	74 19                	je     f01019bd <mem_init+0x9c0>
f01019a4:	68 b8 3e 10 f0       	push   $0xf0103eb8
f01019a9:	68 ee 42 10 f0       	push   $0xf01042ee
f01019ae:	68 13 03 00 00       	push   $0x313
f01019b3:	68 c8 42 10 f0       	push   $0xf01042c8
f01019b8:	e8 ce e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019bd:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019c3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019c8:	89 f8                	mov    %edi,%eax
f01019ca:	e8 c3 ee ff ff       	call   f0100892 <check_va2pa>
f01019cf:	89 f2                	mov    %esi,%edx
f01019d1:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019d7:	c1 fa 03             	sar    $0x3,%edx
f01019da:	c1 e2 0c             	shl    $0xc,%edx
f01019dd:	39 d0                	cmp    %edx,%eax
f01019df:	74 19                	je     f01019fa <mem_init+0x9fd>
f01019e1:	68 48 3e 10 f0       	push   $0xf0103e48
f01019e6:	68 ee 42 10 f0       	push   $0xf01042ee
f01019eb:	68 14 03 00 00       	push   $0x314
f01019f0:	68 c8 42 10 f0       	push   $0xf01042c8
f01019f5:	e8 91 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019fa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019ff:	74 19                	je     f0101a1a <mem_init+0xa1d>
f0101a01:	68 c2 44 10 f0       	push   $0xf01044c2
f0101a06:	68 ee 42 10 f0       	push   $0xf01042ee
f0101a0b:	68 15 03 00 00       	push   $0x315
f0101a10:	68 c8 42 10 f0       	push   $0xf01042c8
f0101a15:	e8 71 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a1a:	83 ec 04             	sub    $0x4,%esp
f0101a1d:	6a 00                	push   $0x0
f0101a1f:	68 00 10 00 00       	push   $0x1000
f0101a24:	57                   	push   %edi
f0101a25:	e8 10 f3 ff ff       	call   f0100d3a <pgdir_walk>
f0101a2a:	83 c4 10             	add    $0x10,%esp
f0101a2d:	f6 00 04             	testb  $0x4,(%eax)
f0101a30:	75 19                	jne    f0101a4b <mem_init+0xa4e>
f0101a32:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0101a37:	68 ee 42 10 f0       	push   $0xf01042ee
f0101a3c:	68 16 03 00 00       	push   $0x316
f0101a41:	68 c8 42 10 f0       	push   $0xf01042c8
f0101a46:	e8 40 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a4b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a50:	f6 00 04             	testb  $0x4,(%eax)
f0101a53:	75 19                	jne    f0101a6e <mem_init+0xa71>
f0101a55:	68 d3 44 10 f0       	push   $0xf01044d3
f0101a5a:	68 ee 42 10 f0       	push   $0xf01042ee
f0101a5f:	68 17 03 00 00       	push   $0x317
f0101a64:	68 c8 42 10 f0       	push   $0xf01042c8
f0101a69:	e8 1d e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a6e:	6a 02                	push   $0x2
f0101a70:	68 00 10 00 00       	push   $0x1000
f0101a75:	56                   	push   %esi
f0101a76:	50                   	push   %eax
f0101a77:	e8 ee f4 ff ff       	call   f0100f6a <page_insert>
f0101a7c:	83 c4 10             	add    $0x10,%esp
f0101a7f:	85 c0                	test   %eax,%eax
f0101a81:	74 19                	je     f0101a9c <mem_init+0xa9f>
f0101a83:	68 0c 3e 10 f0       	push   $0xf0103e0c
f0101a88:	68 ee 42 10 f0       	push   $0xf01042ee
f0101a8d:	68 1a 03 00 00       	push   $0x31a
f0101a92:	68 c8 42 10 f0       	push   $0xf01042c8
f0101a97:	e8 ef e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a9c:	83 ec 04             	sub    $0x4,%esp
f0101a9f:	6a 00                	push   $0x0
f0101aa1:	68 00 10 00 00       	push   $0x1000
f0101aa6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101aac:	e8 89 f2 ff ff       	call   f0100d3a <pgdir_walk>
f0101ab1:	83 c4 10             	add    $0x10,%esp
f0101ab4:	f6 00 02             	testb  $0x2,(%eax)
f0101ab7:	75 19                	jne    f0101ad2 <mem_init+0xad5>
f0101ab9:	68 2c 3f 10 f0       	push   $0xf0103f2c
f0101abe:	68 ee 42 10 f0       	push   $0xf01042ee
f0101ac3:	68 1b 03 00 00       	push   $0x31b
f0101ac8:	68 c8 42 10 f0       	push   $0xf01042c8
f0101acd:	e8 b9 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ad2:	83 ec 04             	sub    $0x4,%esp
f0101ad5:	6a 00                	push   $0x0
f0101ad7:	68 00 10 00 00       	push   $0x1000
f0101adc:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ae2:	e8 53 f2 ff ff       	call   f0100d3a <pgdir_walk>
f0101ae7:	83 c4 10             	add    $0x10,%esp
f0101aea:	f6 00 04             	testb  $0x4,(%eax)
f0101aed:	74 19                	je     f0101b08 <mem_init+0xb0b>
f0101aef:	68 60 3f 10 f0       	push   $0xf0103f60
f0101af4:	68 ee 42 10 f0       	push   $0xf01042ee
f0101af9:	68 1c 03 00 00       	push   $0x31c
f0101afe:	68 c8 42 10 f0       	push   $0xf01042c8
f0101b03:	e8 83 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b08:	6a 02                	push   $0x2
f0101b0a:	68 00 00 40 00       	push   $0x400000
f0101b0f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b12:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b18:	e8 4d f4 ff ff       	call   f0100f6a <page_insert>
f0101b1d:	83 c4 10             	add    $0x10,%esp
f0101b20:	85 c0                	test   %eax,%eax
f0101b22:	78 19                	js     f0101b3d <mem_init+0xb40>
f0101b24:	68 98 3f 10 f0       	push   $0xf0103f98
f0101b29:	68 ee 42 10 f0       	push   $0xf01042ee
f0101b2e:	68 1f 03 00 00       	push   $0x31f
f0101b33:	68 c8 42 10 f0       	push   $0xf01042c8
f0101b38:	e8 4e e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b3d:	6a 02                	push   $0x2
f0101b3f:	68 00 10 00 00       	push   $0x1000
f0101b44:	53                   	push   %ebx
f0101b45:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b4b:	e8 1a f4 ff ff       	call   f0100f6a <page_insert>
f0101b50:	83 c4 10             	add    $0x10,%esp
f0101b53:	85 c0                	test   %eax,%eax
f0101b55:	74 19                	je     f0101b70 <mem_init+0xb73>
f0101b57:	68 d0 3f 10 f0       	push   $0xf0103fd0
f0101b5c:	68 ee 42 10 f0       	push   $0xf01042ee
f0101b61:	68 22 03 00 00       	push   $0x322
f0101b66:	68 c8 42 10 f0       	push   $0xf01042c8
f0101b6b:	e8 1b e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b70:	83 ec 04             	sub    $0x4,%esp
f0101b73:	6a 00                	push   $0x0
f0101b75:	68 00 10 00 00       	push   $0x1000
f0101b7a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b80:	e8 b5 f1 ff ff       	call   f0100d3a <pgdir_walk>
f0101b85:	83 c4 10             	add    $0x10,%esp
f0101b88:	f6 00 04             	testb  $0x4,(%eax)
f0101b8b:	74 19                	je     f0101ba6 <mem_init+0xba9>
f0101b8d:	68 60 3f 10 f0       	push   $0xf0103f60
f0101b92:	68 ee 42 10 f0       	push   $0xf01042ee
f0101b97:	68 23 03 00 00       	push   $0x323
f0101b9c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101ba1:	e8 e5 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ba6:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101bac:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bb1:	89 f8                	mov    %edi,%eax
f0101bb3:	e8 da ec ff ff       	call   f0100892 <check_va2pa>
f0101bb8:	89 c1                	mov    %eax,%ecx
f0101bba:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bbd:	89 d8                	mov    %ebx,%eax
f0101bbf:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101bc5:	c1 f8 03             	sar    $0x3,%eax
f0101bc8:	c1 e0 0c             	shl    $0xc,%eax
f0101bcb:	39 c1                	cmp    %eax,%ecx
f0101bcd:	74 19                	je     f0101be8 <mem_init+0xbeb>
f0101bcf:	68 0c 40 10 f0       	push   $0xf010400c
f0101bd4:	68 ee 42 10 f0       	push   $0xf01042ee
f0101bd9:	68 26 03 00 00       	push   $0x326
f0101bde:	68 c8 42 10 f0       	push   $0xf01042c8
f0101be3:	e8 a3 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101be8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bed:	89 f8                	mov    %edi,%eax
f0101bef:	e8 9e ec ff ff       	call   f0100892 <check_va2pa>
f0101bf4:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bf7:	74 19                	je     f0101c12 <mem_init+0xc15>
f0101bf9:	68 38 40 10 f0       	push   $0xf0104038
f0101bfe:	68 ee 42 10 f0       	push   $0xf01042ee
f0101c03:	68 27 03 00 00       	push   $0x327
f0101c08:	68 c8 42 10 f0       	push   $0xf01042c8
f0101c0d:	e8 79 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c12:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c17:	74 19                	je     f0101c32 <mem_init+0xc35>
f0101c19:	68 e9 44 10 f0       	push   $0xf01044e9
f0101c1e:	68 ee 42 10 f0       	push   $0xf01042ee
f0101c23:	68 29 03 00 00       	push   $0x329
f0101c28:	68 c8 42 10 f0       	push   $0xf01042c8
f0101c2d:	e8 59 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c32:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c37:	74 19                	je     f0101c52 <mem_init+0xc55>
f0101c39:	68 fa 44 10 f0       	push   $0xf01044fa
f0101c3e:	68 ee 42 10 f0       	push   $0xf01042ee
f0101c43:	68 2a 03 00 00       	push   $0x32a
f0101c48:	68 c8 42 10 f0       	push   $0xf01042c8
f0101c4d:	e8 39 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c52:	83 ec 0c             	sub    $0xc,%esp
f0101c55:	6a 00                	push   $0x0
f0101c57:	e8 10 f0 ff ff       	call   f0100c6c <page_alloc>
f0101c5c:	83 c4 10             	add    $0x10,%esp
f0101c5f:	85 c0                	test   %eax,%eax
f0101c61:	74 04                	je     f0101c67 <mem_init+0xc6a>
f0101c63:	39 c6                	cmp    %eax,%esi
f0101c65:	74 19                	je     f0101c80 <mem_init+0xc83>
f0101c67:	68 68 40 10 f0       	push   $0xf0104068
f0101c6c:	68 ee 42 10 f0       	push   $0xf01042ee
f0101c71:	68 2d 03 00 00       	push   $0x32d
f0101c76:	68 c8 42 10 f0       	push   $0xf01042c8
f0101c7b:	e8 0b e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c80:	83 ec 08             	sub    $0x8,%esp
f0101c83:	6a 00                	push   $0x0
f0101c85:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c8b:	e8 8c f2 ff ff       	call   f0100f1c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c90:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c96:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c9b:	89 f8                	mov    %edi,%eax
f0101c9d:	e8 f0 eb ff ff       	call   f0100892 <check_va2pa>
f0101ca2:	83 c4 10             	add    $0x10,%esp
f0101ca5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ca8:	74 19                	je     f0101cc3 <mem_init+0xcc6>
f0101caa:	68 8c 40 10 f0       	push   $0xf010408c
f0101caf:	68 ee 42 10 f0       	push   $0xf01042ee
f0101cb4:	68 31 03 00 00       	push   $0x331
f0101cb9:	68 c8 42 10 f0       	push   $0xf01042c8
f0101cbe:	e8 c8 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cc3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc8:	89 f8                	mov    %edi,%eax
f0101cca:	e8 c3 eb ff ff       	call   f0100892 <check_va2pa>
f0101ccf:	89 da                	mov    %ebx,%edx
f0101cd1:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cd7:	c1 fa 03             	sar    $0x3,%edx
f0101cda:	c1 e2 0c             	shl    $0xc,%edx
f0101cdd:	39 d0                	cmp    %edx,%eax
f0101cdf:	74 19                	je     f0101cfa <mem_init+0xcfd>
f0101ce1:	68 38 40 10 f0       	push   $0xf0104038
f0101ce6:	68 ee 42 10 f0       	push   $0xf01042ee
f0101ceb:	68 32 03 00 00       	push   $0x332
f0101cf0:	68 c8 42 10 f0       	push   $0xf01042c8
f0101cf5:	e8 91 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101cfa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cff:	74 19                	je     f0101d1a <mem_init+0xd1d>
f0101d01:	68 a0 44 10 f0       	push   $0xf01044a0
f0101d06:	68 ee 42 10 f0       	push   $0xf01042ee
f0101d0b:	68 33 03 00 00       	push   $0x333
f0101d10:	68 c8 42 10 f0       	push   $0xf01042c8
f0101d15:	e8 71 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d1a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d1f:	74 19                	je     f0101d3a <mem_init+0xd3d>
f0101d21:	68 fa 44 10 f0       	push   $0xf01044fa
f0101d26:	68 ee 42 10 f0       	push   $0xf01042ee
f0101d2b:	68 34 03 00 00       	push   $0x334
f0101d30:	68 c8 42 10 f0       	push   $0xf01042c8
f0101d35:	e8 51 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d3a:	6a 00                	push   $0x0
f0101d3c:	68 00 10 00 00       	push   $0x1000
f0101d41:	53                   	push   %ebx
f0101d42:	57                   	push   %edi
f0101d43:	e8 22 f2 ff ff       	call   f0100f6a <page_insert>
f0101d48:	83 c4 10             	add    $0x10,%esp
f0101d4b:	85 c0                	test   %eax,%eax
f0101d4d:	74 19                	je     f0101d68 <mem_init+0xd6b>
f0101d4f:	68 b0 40 10 f0       	push   $0xf01040b0
f0101d54:	68 ee 42 10 f0       	push   $0xf01042ee
f0101d59:	68 37 03 00 00       	push   $0x337
f0101d5e:	68 c8 42 10 f0       	push   $0xf01042c8
f0101d63:	e8 23 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d68:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d6d:	75 19                	jne    f0101d88 <mem_init+0xd8b>
f0101d6f:	68 0b 45 10 f0       	push   $0xf010450b
f0101d74:	68 ee 42 10 f0       	push   $0xf01042ee
f0101d79:	68 38 03 00 00       	push   $0x338
f0101d7e:	68 c8 42 10 f0       	push   $0xf01042c8
f0101d83:	e8 03 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d88:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d8b:	74 19                	je     f0101da6 <mem_init+0xda9>
f0101d8d:	68 17 45 10 f0       	push   $0xf0104517
f0101d92:	68 ee 42 10 f0       	push   $0xf01042ee
f0101d97:	68 39 03 00 00       	push   $0x339
f0101d9c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101da1:	e8 e5 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101da6:	83 ec 08             	sub    $0x8,%esp
f0101da9:	68 00 10 00 00       	push   $0x1000
f0101dae:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101db4:	e8 63 f1 ff ff       	call   f0100f1c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101db9:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101dbf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc4:	89 f8                	mov    %edi,%eax
f0101dc6:	e8 c7 ea ff ff       	call   f0100892 <check_va2pa>
f0101dcb:	83 c4 10             	add    $0x10,%esp
f0101dce:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dd1:	74 19                	je     f0101dec <mem_init+0xdef>
f0101dd3:	68 8c 40 10 f0       	push   $0xf010408c
f0101dd8:	68 ee 42 10 f0       	push   $0xf01042ee
f0101ddd:	68 3d 03 00 00       	push   $0x33d
f0101de2:	68 c8 42 10 f0       	push   $0xf01042c8
f0101de7:	e8 9f e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101dec:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101df1:	89 f8                	mov    %edi,%eax
f0101df3:	e8 9a ea ff ff       	call   f0100892 <check_va2pa>
f0101df8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dfb:	74 19                	je     f0101e16 <mem_init+0xe19>
f0101dfd:	68 e8 40 10 f0       	push   $0xf01040e8
f0101e02:	68 ee 42 10 f0       	push   $0xf01042ee
f0101e07:	68 3e 03 00 00       	push   $0x33e
f0101e0c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101e11:	e8 75 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e16:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e1b:	74 19                	je     f0101e36 <mem_init+0xe39>
f0101e1d:	68 2c 45 10 f0       	push   $0xf010452c
f0101e22:	68 ee 42 10 f0       	push   $0xf01042ee
f0101e27:	68 3f 03 00 00       	push   $0x33f
f0101e2c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101e31:	e8 55 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e36:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e3b:	74 19                	je     f0101e56 <mem_init+0xe59>
f0101e3d:	68 fa 44 10 f0       	push   $0xf01044fa
f0101e42:	68 ee 42 10 f0       	push   $0xf01042ee
f0101e47:	68 40 03 00 00       	push   $0x340
f0101e4c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101e51:	e8 35 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e56:	83 ec 0c             	sub    $0xc,%esp
f0101e59:	6a 00                	push   $0x0
f0101e5b:	e8 0c ee ff ff       	call   f0100c6c <page_alloc>
f0101e60:	83 c4 10             	add    $0x10,%esp
f0101e63:	39 c3                	cmp    %eax,%ebx
f0101e65:	75 04                	jne    f0101e6b <mem_init+0xe6e>
f0101e67:	85 c0                	test   %eax,%eax
f0101e69:	75 19                	jne    f0101e84 <mem_init+0xe87>
f0101e6b:	68 10 41 10 f0       	push   $0xf0104110
f0101e70:	68 ee 42 10 f0       	push   $0xf01042ee
f0101e75:	68 43 03 00 00       	push   $0x343
f0101e7a:	68 c8 42 10 f0       	push   $0xf01042c8
f0101e7f:	e8 07 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e84:	83 ec 0c             	sub    $0xc,%esp
f0101e87:	6a 00                	push   $0x0
f0101e89:	e8 de ed ff ff       	call   f0100c6c <page_alloc>
f0101e8e:	83 c4 10             	add    $0x10,%esp
f0101e91:	85 c0                	test   %eax,%eax
f0101e93:	74 19                	je     f0101eae <mem_init+0xeb1>
f0101e95:	68 4e 44 10 f0       	push   $0xf010444e
f0101e9a:	68 ee 42 10 f0       	push   $0xf01042ee
f0101e9f:	68 46 03 00 00       	push   $0x346
f0101ea4:	68 c8 42 10 f0       	push   $0xf01042c8
f0101ea9:	e8 dd e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eae:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101eb4:	8b 11                	mov    (%ecx),%edx
f0101eb6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ebc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebf:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101ec5:	c1 f8 03             	sar    $0x3,%eax
f0101ec8:	c1 e0 0c             	shl    $0xc,%eax
f0101ecb:	39 c2                	cmp    %eax,%edx
f0101ecd:	74 19                	je     f0101ee8 <mem_init+0xeeb>
f0101ecf:	68 b4 3d 10 f0       	push   $0xf0103db4
f0101ed4:	68 ee 42 10 f0       	push   $0xf01042ee
f0101ed9:	68 49 03 00 00       	push   $0x349
f0101ede:	68 c8 42 10 f0       	push   $0xf01042c8
f0101ee3:	e8 a3 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101ee8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ef6:	74 19                	je     f0101f11 <mem_init+0xf14>
f0101ef8:	68 b1 44 10 f0       	push   $0xf01044b1
f0101efd:	68 ee 42 10 f0       	push   $0xf01042ee
f0101f02:	68 4b 03 00 00       	push   $0x34b
f0101f07:	68 c8 42 10 f0       	push   $0xf01042c8
f0101f0c:	e8 7a e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f14:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f1a:	83 ec 0c             	sub    $0xc,%esp
f0101f1d:	50                   	push   %eax
f0101f1e:	e8 b3 ed ff ff       	call   f0100cd6 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f23:	83 c4 0c             	add    $0xc,%esp
f0101f26:	6a 01                	push   $0x1
f0101f28:	68 00 10 40 00       	push   $0x401000
f0101f2d:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f33:	e8 02 ee ff ff       	call   f0100d3a <pgdir_walk>
f0101f38:	89 c7                	mov    %eax,%edi
f0101f3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f3d:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f42:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f45:	8b 40 04             	mov    0x4(%eax),%eax
f0101f48:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f4d:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f53:	89 c2                	mov    %eax,%edx
f0101f55:	c1 ea 0c             	shr    $0xc,%edx
f0101f58:	83 c4 10             	add    $0x10,%esp
f0101f5b:	39 ca                	cmp    %ecx,%edx
f0101f5d:	72 15                	jb     f0101f74 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f5f:	50                   	push   %eax
f0101f60:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0101f65:	68 52 03 00 00       	push   $0x352
f0101f6a:	68 c8 42 10 f0       	push   $0xf01042c8
f0101f6f:	e8 17 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f74:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f79:	39 c7                	cmp    %eax,%edi
f0101f7b:	74 19                	je     f0101f96 <mem_init+0xf99>
f0101f7d:	68 3d 45 10 f0       	push   $0xf010453d
f0101f82:	68 ee 42 10 f0       	push   $0xf01042ee
f0101f87:	68 53 03 00 00       	push   $0x353
f0101f8c:	68 c8 42 10 f0       	push   $0xf01042c8
f0101f91:	e8 f5 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f96:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f99:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fa0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fa3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fa9:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101faf:	c1 f8 03             	sar    $0x3,%eax
f0101fb2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb5:	89 c2                	mov    %eax,%edx
f0101fb7:	c1 ea 0c             	shr    $0xc,%edx
f0101fba:	39 d1                	cmp    %edx,%ecx
f0101fbc:	77 12                	ja     f0101fd0 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fbe:	50                   	push   %eax
f0101fbf:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0101fc4:	6a 52                	push   $0x52
f0101fc6:	68 d4 42 10 f0       	push   $0xf01042d4
f0101fcb:	e8 bb e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fd0:	83 ec 04             	sub    $0x4,%esp
f0101fd3:	68 00 10 00 00       	push   $0x1000
f0101fd8:	68 ff 00 00 00       	push   $0xff
f0101fdd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fe2:	50                   	push   %eax
f0101fe3:	e8 f7 11 00 00       	call   f01031df <memset>
	page_free(pp0);
f0101fe8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101feb:	89 3c 24             	mov    %edi,(%esp)
f0101fee:	e8 e3 ec ff ff       	call   f0100cd6 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ff3:	83 c4 0c             	add    $0xc,%esp
f0101ff6:	6a 01                	push   $0x1
f0101ff8:	6a 00                	push   $0x0
f0101ffa:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102000:	e8 35 ed ff ff       	call   f0100d3a <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102005:	89 fa                	mov    %edi,%edx
f0102007:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010200d:	c1 fa 03             	sar    $0x3,%edx
f0102010:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102013:	89 d0                	mov    %edx,%eax
f0102015:	c1 e8 0c             	shr    $0xc,%eax
f0102018:	83 c4 10             	add    $0x10,%esp
f010201b:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0102021:	72 12                	jb     f0102035 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102023:	52                   	push   %edx
f0102024:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0102029:	6a 52                	push   $0x52
f010202b:	68 d4 42 10 f0       	push   $0xf01042d4
f0102030:	e8 56 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102035:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010203b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010203e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102044:	f6 00 01             	testb  $0x1,(%eax)
f0102047:	74 19                	je     f0102062 <mem_init+0x1065>
f0102049:	68 55 45 10 f0       	push   $0xf0104555
f010204e:	68 ee 42 10 f0       	push   $0xf01042ee
f0102053:	68 5d 03 00 00       	push   $0x35d
f0102058:	68 c8 42 10 f0       	push   $0xf01042c8
f010205d:	e8 29 e0 ff ff       	call   f010008b <_panic>
f0102062:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102065:	39 d0                	cmp    %edx,%eax
f0102067:	75 db                	jne    f0102044 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102069:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010206e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102074:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102077:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010207d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102080:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102086:	83 ec 0c             	sub    $0xc,%esp
f0102089:	50                   	push   %eax
f010208a:	e8 47 ec ff ff       	call   f0100cd6 <page_free>
	page_free(pp1);
f010208f:	89 1c 24             	mov    %ebx,(%esp)
f0102092:	e8 3f ec ff ff       	call   f0100cd6 <page_free>
	page_free(pp2);
f0102097:	89 34 24             	mov    %esi,(%esp)
f010209a:	e8 37 ec ff ff       	call   f0100cd6 <page_free>

	cprintf("check_page() succeeded!\n");
f010209f:	c7 04 24 6c 45 10 f0 	movl   $0xf010456c,(%esp)
f01020a6:	e8 4b 06 00 00       	call   f01026f6 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f01020ab:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020b0:	83 c4 10             	add    $0x10,%esp
f01020b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020b8:	77 15                	ja     f01020cf <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020ba:	50                   	push   %eax
f01020bb:	68 2c 3c 10 f0       	push   $0xf0103c2c
f01020c0:	68 a1 00 00 00       	push   $0xa1
f01020c5:	68 c8 42 10 f0       	push   $0xf01042c8
f01020ca:	e8 bc df ff ff       	call   f010008b <_panic>
f01020cf:	83 ec 08             	sub    $0x8,%esp
f01020d2:	6a 04                	push   $0x4
f01020d4:	05 00 00 00 10       	add    $0x10000000,%eax
f01020d9:	50                   	push   %eax
f01020da:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020df:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020e4:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01020e9:	e8 38 ed ff ff       	call   f0100e26 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020ee:	83 c4 10             	add    $0x10,%esp
f01020f1:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f01020f6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020fb:	77 15                	ja     f0102112 <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020fd:	50                   	push   %eax
f01020fe:	68 2c 3c 10 f0       	push   $0xf0103c2c
f0102103:	68 b2 00 00 00       	push   $0xb2
f0102108:	68 c8 42 10 f0       	push   $0xf01042c8
f010210d:	e8 79 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f0102112:	83 ec 08             	sub    $0x8,%esp
f0102115:	6a 02                	push   $0x2
f0102117:	68 00 c0 10 00       	push   $0x10c000
f010211c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102121:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102126:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010212b:	e8 f6 ec ff ff       	call   f0100e26 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f0102130:	83 c4 08             	add    $0x8,%esp
f0102133:	6a 02                	push   $0x2
f0102135:	6a 00                	push   $0x0
f0102137:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010213c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102141:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102146:	e8 db ec ff ff       	call   f0100e26 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010214b:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102151:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0102156:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102159:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102160:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102165:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102168:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010216e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102171:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102174:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102179:	eb 55                	jmp    f01021d0 <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010217b:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102181:	89 f0                	mov    %esi,%eax
f0102183:	e8 0a e7 ff ff       	call   f0100892 <check_va2pa>
f0102188:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010218f:	77 15                	ja     f01021a6 <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102191:	57                   	push   %edi
f0102192:	68 2c 3c 10 f0       	push   $0xf0103c2c
f0102197:	68 9f 02 00 00       	push   $0x29f
f010219c:	68 c8 42 10 f0       	push   $0xf01042c8
f01021a1:	e8 e5 de ff ff       	call   f010008b <_panic>
f01021a6:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021ad:	39 c2                	cmp    %eax,%edx
f01021af:	74 19                	je     f01021ca <mem_init+0x11cd>
f01021b1:	68 34 41 10 f0       	push   $0xf0104134
f01021b6:	68 ee 42 10 f0       	push   $0xf01042ee
f01021bb:	68 9f 02 00 00       	push   $0x29f
f01021c0:	68 c8 42 10 f0       	push   $0xf01042c8
f01021c5:	e8 c1 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021ca:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021d0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021d3:	77 a6                	ja     f010217b <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021d5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021d8:	c1 e7 0c             	shl    $0xc,%edi
f01021db:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021e0:	eb 30                	jmp    f0102212 <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021e2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01021e8:	89 f0                	mov    %esi,%eax
f01021ea:	e8 a3 e6 ff ff       	call   f0100892 <check_va2pa>
f01021ef:	39 c3                	cmp    %eax,%ebx
f01021f1:	74 19                	je     f010220c <mem_init+0x120f>
f01021f3:	68 68 41 10 f0       	push   $0xf0104168
f01021f8:	68 ee 42 10 f0       	push   $0xf01042ee
f01021fd:	68 a4 02 00 00       	push   $0x2a4
f0102202:	68 c8 42 10 f0       	push   $0xf01042c8
f0102207:	e8 7f de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010220c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102212:	39 fb                	cmp    %edi,%ebx
f0102214:	72 cc                	jb     f01021e2 <mem_init+0x11e5>
f0102216:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010221b:	89 da                	mov    %ebx,%edx
f010221d:	89 f0                	mov    %esi,%eax
f010221f:	e8 6e e6 ff ff       	call   f0100892 <check_va2pa>
f0102224:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010222a:	39 c2                	cmp    %eax,%edx
f010222c:	74 19                	je     f0102247 <mem_init+0x124a>
f010222e:	68 90 41 10 f0       	push   $0xf0104190
f0102233:	68 ee 42 10 f0       	push   $0xf01042ee
f0102238:	68 a8 02 00 00       	push   $0x2a8
f010223d:	68 c8 42 10 f0       	push   $0xf01042c8
f0102242:	e8 44 de ff ff       	call   f010008b <_panic>
f0102247:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010224d:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102253:	75 c6                	jne    f010221b <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102255:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010225a:	89 f0                	mov    %esi,%eax
f010225c:	e8 31 e6 ff ff       	call   f0100892 <check_va2pa>
f0102261:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102264:	74 51                	je     f01022b7 <mem_init+0x12ba>
f0102266:	68 d8 41 10 f0       	push   $0xf01041d8
f010226b:	68 ee 42 10 f0       	push   $0xf01042ee
f0102270:	68 a9 02 00 00       	push   $0x2a9
f0102275:	68 c8 42 10 f0       	push   $0xf01042c8
f010227a:	e8 0c de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010227f:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102284:	72 36                	jb     f01022bc <mem_init+0x12bf>
f0102286:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010228b:	76 07                	jbe    f0102294 <mem_init+0x1297>
f010228d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102292:	75 28                	jne    f01022bc <mem_init+0x12bf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102294:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102298:	0f 85 83 00 00 00    	jne    f0102321 <mem_init+0x1324>
f010229e:	68 85 45 10 f0       	push   $0xf0104585
f01022a3:	68 ee 42 10 f0       	push   $0xf01042ee
f01022a8:	68 b1 02 00 00       	push   $0x2b1
f01022ad:	68 c8 42 10 f0       	push   $0xf01042c8
f01022b2:	e8 d4 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022b7:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022bc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022c1:	76 3f                	jbe    f0102302 <mem_init+0x1305>
				assert(pgdir[i] & PTE_P);
f01022c3:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022c6:	f6 c2 01             	test   $0x1,%dl
f01022c9:	75 19                	jne    f01022e4 <mem_init+0x12e7>
f01022cb:	68 85 45 10 f0       	push   $0xf0104585
f01022d0:	68 ee 42 10 f0       	push   $0xf01042ee
f01022d5:	68 b5 02 00 00       	push   $0x2b5
f01022da:	68 c8 42 10 f0       	push   $0xf01042c8
f01022df:	e8 a7 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01022e4:	f6 c2 02             	test   $0x2,%dl
f01022e7:	75 38                	jne    f0102321 <mem_init+0x1324>
f01022e9:	68 96 45 10 f0       	push   $0xf0104596
f01022ee:	68 ee 42 10 f0       	push   $0xf01042ee
f01022f3:	68 b6 02 00 00       	push   $0x2b6
f01022f8:	68 c8 42 10 f0       	push   $0xf01042c8
f01022fd:	e8 89 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102302:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102306:	74 19                	je     f0102321 <mem_init+0x1324>
f0102308:	68 a7 45 10 f0       	push   $0xf01045a7
f010230d:	68 ee 42 10 f0       	push   $0xf01042ee
f0102312:	68 b8 02 00 00       	push   $0x2b8
f0102317:	68 c8 42 10 f0       	push   $0xf01042c8
f010231c:	e8 6a dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102321:	83 c0 01             	add    $0x1,%eax
f0102324:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102329:	0f 86 50 ff ff ff    	jbe    f010227f <mem_init+0x1282>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010232f:	83 ec 0c             	sub    $0xc,%esp
f0102332:	68 08 42 10 f0       	push   $0xf0104208
f0102337:	e8 ba 03 00 00       	call   f01026f6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010233c:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102341:	83 c4 10             	add    $0x10,%esp
f0102344:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102349:	77 15                	ja     f0102360 <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010234b:	50                   	push   %eax
f010234c:	68 2c 3c 10 f0       	push   $0xf0103c2c
f0102351:	68 cb 00 00 00       	push   $0xcb
f0102356:	68 c8 42 10 f0       	push   $0xf01042c8
f010235b:	e8 2b dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102360:	05 00 00 00 10       	add    $0x10000000,%eax
f0102365:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102368:	b8 00 00 00 00       	mov    $0x0,%eax
f010236d:	e8 84 e5 ff ff       	call   f01008f6 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102372:	0f 20 c0             	mov    %cr0,%eax
f0102375:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102378:	0d 23 00 05 80       	or     $0x80050023,%eax
f010237d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102380:	83 ec 0c             	sub    $0xc,%esp
f0102383:	6a 00                	push   $0x0
f0102385:	e8 e2 e8 ff ff       	call   f0100c6c <page_alloc>
f010238a:	89 c3                	mov    %eax,%ebx
f010238c:	83 c4 10             	add    $0x10,%esp
f010238f:	85 c0                	test   %eax,%eax
f0102391:	75 19                	jne    f01023ac <mem_init+0x13af>
f0102393:	68 a3 43 10 f0       	push   $0xf01043a3
f0102398:	68 ee 42 10 f0       	push   $0xf01042ee
f010239d:	68 78 03 00 00       	push   $0x378
f01023a2:	68 c8 42 10 f0       	push   $0xf01042c8
f01023a7:	e8 df dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023ac:	83 ec 0c             	sub    $0xc,%esp
f01023af:	6a 00                	push   $0x0
f01023b1:	e8 b6 e8 ff ff       	call   f0100c6c <page_alloc>
f01023b6:	89 c7                	mov    %eax,%edi
f01023b8:	83 c4 10             	add    $0x10,%esp
f01023bb:	85 c0                	test   %eax,%eax
f01023bd:	75 19                	jne    f01023d8 <mem_init+0x13db>
f01023bf:	68 b9 43 10 f0       	push   $0xf01043b9
f01023c4:	68 ee 42 10 f0       	push   $0xf01042ee
f01023c9:	68 79 03 00 00       	push   $0x379
f01023ce:	68 c8 42 10 f0       	push   $0xf01042c8
f01023d3:	e8 b3 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023d8:	83 ec 0c             	sub    $0xc,%esp
f01023db:	6a 00                	push   $0x0
f01023dd:	e8 8a e8 ff ff       	call   f0100c6c <page_alloc>
f01023e2:	89 c6                	mov    %eax,%esi
f01023e4:	83 c4 10             	add    $0x10,%esp
f01023e7:	85 c0                	test   %eax,%eax
f01023e9:	75 19                	jne    f0102404 <mem_init+0x1407>
f01023eb:	68 cf 43 10 f0       	push   $0xf01043cf
f01023f0:	68 ee 42 10 f0       	push   $0xf01042ee
f01023f5:	68 7a 03 00 00       	push   $0x37a
f01023fa:	68 c8 42 10 f0       	push   $0xf01042c8
f01023ff:	e8 87 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102404:	83 ec 0c             	sub    $0xc,%esp
f0102407:	53                   	push   %ebx
f0102408:	e8 c9 e8 ff ff       	call   f0100cd6 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010240d:	89 f8                	mov    %edi,%eax
f010240f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102415:	c1 f8 03             	sar    $0x3,%eax
f0102418:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010241b:	89 c2                	mov    %eax,%edx
f010241d:	c1 ea 0c             	shr    $0xc,%edx
f0102420:	83 c4 10             	add    $0x10,%esp
f0102423:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102429:	72 12                	jb     f010243d <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010242b:	50                   	push   %eax
f010242c:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0102431:	6a 52                	push   $0x52
f0102433:	68 d4 42 10 f0       	push   $0xf01042d4
f0102438:	e8 4e dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010243d:	83 ec 04             	sub    $0x4,%esp
f0102440:	68 00 10 00 00       	push   $0x1000
f0102445:	6a 01                	push   $0x1
f0102447:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010244c:	50                   	push   %eax
f010244d:	e8 8d 0d 00 00       	call   f01031df <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102452:	89 f0                	mov    %esi,%eax
f0102454:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010245a:	c1 f8 03             	sar    $0x3,%eax
f010245d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102460:	89 c2                	mov    %eax,%edx
f0102462:	c1 ea 0c             	shr    $0xc,%edx
f0102465:	83 c4 10             	add    $0x10,%esp
f0102468:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010246e:	72 12                	jb     f0102482 <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102470:	50                   	push   %eax
f0102471:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0102476:	6a 52                	push   $0x52
f0102478:	68 d4 42 10 f0       	push   $0xf01042d4
f010247d:	e8 09 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102482:	83 ec 04             	sub    $0x4,%esp
f0102485:	68 00 10 00 00       	push   $0x1000
f010248a:	6a 02                	push   $0x2
f010248c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102491:	50                   	push   %eax
f0102492:	e8 48 0d 00 00       	call   f01031df <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102497:	6a 02                	push   $0x2
f0102499:	68 00 10 00 00       	push   $0x1000
f010249e:	57                   	push   %edi
f010249f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024a5:	e8 c0 ea ff ff       	call   f0100f6a <page_insert>
	assert(pp1->pp_ref == 1);
f01024aa:	83 c4 20             	add    $0x20,%esp
f01024ad:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024b2:	74 19                	je     f01024cd <mem_init+0x14d0>
f01024b4:	68 a0 44 10 f0       	push   $0xf01044a0
f01024b9:	68 ee 42 10 f0       	push   $0xf01042ee
f01024be:	68 7f 03 00 00       	push   $0x37f
f01024c3:	68 c8 42 10 f0       	push   $0xf01042c8
f01024c8:	e8 be db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024cd:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024d4:	01 01 01 
f01024d7:	74 19                	je     f01024f2 <mem_init+0x14f5>
f01024d9:	68 28 42 10 f0       	push   $0xf0104228
f01024de:	68 ee 42 10 f0       	push   $0xf01042ee
f01024e3:	68 80 03 00 00       	push   $0x380
f01024e8:	68 c8 42 10 f0       	push   $0xf01042c8
f01024ed:	e8 99 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01024f2:	6a 02                	push   $0x2
f01024f4:	68 00 10 00 00       	push   $0x1000
f01024f9:	56                   	push   %esi
f01024fa:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102500:	e8 65 ea ff ff       	call   f0100f6a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102505:	83 c4 10             	add    $0x10,%esp
f0102508:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010250f:	02 02 02 
f0102512:	74 19                	je     f010252d <mem_init+0x1530>
f0102514:	68 4c 42 10 f0       	push   $0xf010424c
f0102519:	68 ee 42 10 f0       	push   $0xf01042ee
f010251e:	68 82 03 00 00       	push   $0x382
f0102523:	68 c8 42 10 f0       	push   $0xf01042c8
f0102528:	e8 5e db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010252d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102532:	74 19                	je     f010254d <mem_init+0x1550>
f0102534:	68 c2 44 10 f0       	push   $0xf01044c2
f0102539:	68 ee 42 10 f0       	push   $0xf01042ee
f010253e:	68 83 03 00 00       	push   $0x383
f0102543:	68 c8 42 10 f0       	push   $0xf01042c8
f0102548:	e8 3e db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010254d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102552:	74 19                	je     f010256d <mem_init+0x1570>
f0102554:	68 2c 45 10 f0       	push   $0xf010452c
f0102559:	68 ee 42 10 f0       	push   $0xf01042ee
f010255e:	68 84 03 00 00       	push   $0x384
f0102563:	68 c8 42 10 f0       	push   $0xf01042c8
f0102568:	e8 1e db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010256d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102574:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102577:	89 f0                	mov    %esi,%eax
f0102579:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010257f:	c1 f8 03             	sar    $0x3,%eax
f0102582:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102585:	89 c2                	mov    %eax,%edx
f0102587:	c1 ea 0c             	shr    $0xc,%edx
f010258a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102590:	72 12                	jb     f01025a4 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102592:	50                   	push   %eax
f0102593:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0102598:	6a 52                	push   $0x52
f010259a:	68 d4 42 10 f0       	push   $0xf01042d4
f010259f:	e8 e7 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025a4:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025ab:	03 03 03 
f01025ae:	74 19                	je     f01025c9 <mem_init+0x15cc>
f01025b0:	68 70 42 10 f0       	push   $0xf0104270
f01025b5:	68 ee 42 10 f0       	push   $0xf01042ee
f01025ba:	68 86 03 00 00       	push   $0x386
f01025bf:	68 c8 42 10 f0       	push   $0xf01042c8
f01025c4:	e8 c2 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025c9:	83 ec 08             	sub    $0x8,%esp
f01025cc:	68 00 10 00 00       	push   $0x1000
f01025d1:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01025d7:	e8 40 e9 ff ff       	call   f0100f1c <page_remove>
	assert(pp2->pp_ref == 0);
f01025dc:	83 c4 10             	add    $0x10,%esp
f01025df:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025e4:	74 19                	je     f01025ff <mem_init+0x1602>
f01025e6:	68 fa 44 10 f0       	push   $0xf01044fa
f01025eb:	68 ee 42 10 f0       	push   $0xf01042ee
f01025f0:	68 88 03 00 00       	push   $0x388
f01025f5:	68 c8 42 10 f0       	push   $0xf01042c8
f01025fa:	e8 8c da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025ff:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102605:	8b 11                	mov    (%ecx),%edx
f0102607:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010260d:	89 d8                	mov    %ebx,%eax
f010260f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102615:	c1 f8 03             	sar    $0x3,%eax
f0102618:	c1 e0 0c             	shl    $0xc,%eax
f010261b:	39 c2                	cmp    %eax,%edx
f010261d:	74 19                	je     f0102638 <mem_init+0x163b>
f010261f:	68 b4 3d 10 f0       	push   $0xf0103db4
f0102624:	68 ee 42 10 f0       	push   $0xf01042ee
f0102629:	68 8b 03 00 00       	push   $0x38b
f010262e:	68 c8 42 10 f0       	push   $0xf01042c8
f0102633:	e8 53 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102638:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010263e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102643:	74 19                	je     f010265e <mem_init+0x1661>
f0102645:	68 b1 44 10 f0       	push   $0xf01044b1
f010264a:	68 ee 42 10 f0       	push   $0xf01042ee
f010264f:	68 8d 03 00 00       	push   $0x38d
f0102654:	68 c8 42 10 f0       	push   $0xf01042c8
f0102659:	e8 2d da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010265e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102664:	83 ec 0c             	sub    $0xc,%esp
f0102667:	53                   	push   %ebx
f0102668:	e8 69 e6 ff ff       	call   f0100cd6 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010266d:	c7 04 24 9c 42 10 f0 	movl   $0xf010429c,(%esp)
f0102674:	e8 7d 00 00 00       	call   f01026f6 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102679:	83 c4 10             	add    $0x10,%esp
f010267c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010267f:	5b                   	pop    %ebx
f0102680:	5e                   	pop    %esi
f0102681:	5f                   	pop    %edi
f0102682:	5d                   	pop    %ebp
f0102683:	c3                   	ret    

f0102684 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102684:	55                   	push   %ebp
f0102685:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102687:	8b 45 0c             	mov    0xc(%ebp),%eax
f010268a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010268d:	5d                   	pop    %ebp
f010268e:	c3                   	ret    

f010268f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010268f:	55                   	push   %ebp
f0102690:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102692:	ba 70 00 00 00       	mov    $0x70,%edx
f0102697:	8b 45 08             	mov    0x8(%ebp),%eax
f010269a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010269b:	ba 71 00 00 00       	mov    $0x71,%edx
f01026a0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026a1:	0f b6 c0             	movzbl %al,%eax
}
f01026a4:	5d                   	pop    %ebp
f01026a5:	c3                   	ret    

f01026a6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026a6:	55                   	push   %ebp
f01026a7:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026a9:	ba 70 00 00 00       	mov    $0x70,%edx
f01026ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01026b1:	ee                   	out    %al,(%dx)
f01026b2:	ba 71 00 00 00       	mov    $0x71,%edx
f01026b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026ba:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026bb:	5d                   	pop    %ebp
f01026bc:	c3                   	ret    

f01026bd <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026bd:	55                   	push   %ebp
f01026be:	89 e5                	mov    %esp,%ebp
f01026c0:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026c3:	ff 75 08             	pushl  0x8(%ebp)
f01026c6:	e8 27 df ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f01026cb:	83 c4 10             	add    $0x10,%esp
f01026ce:	c9                   	leave  
f01026cf:	c3                   	ret    

f01026d0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026d0:	55                   	push   %ebp
f01026d1:	89 e5                	mov    %esp,%ebp
f01026d3:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026d6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026dd:	ff 75 0c             	pushl  0xc(%ebp)
f01026e0:	ff 75 08             	pushl  0x8(%ebp)
f01026e3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026e6:	50                   	push   %eax
f01026e7:	68 bd 26 10 f0       	push   $0xf01026bd
f01026ec:	e8 c9 03 00 00       	call   f0102aba <vprintfmt>
	return cnt;
}
f01026f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026f4:	c9                   	leave  
f01026f5:	c3                   	ret    

f01026f6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026f6:	55                   	push   %ebp
f01026f7:	89 e5                	mov    %esp,%ebp
f01026f9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01026fc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01026ff:	50                   	push   %eax
f0102700:	ff 75 08             	pushl  0x8(%ebp)
f0102703:	e8 c8 ff ff ff       	call   f01026d0 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102708:	c9                   	leave  
f0102709:	c3                   	ret    

f010270a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010270a:	55                   	push   %ebp
f010270b:	89 e5                	mov    %esp,%ebp
f010270d:	57                   	push   %edi
f010270e:	56                   	push   %esi
f010270f:	53                   	push   %ebx
f0102710:	83 ec 14             	sub    $0x14,%esp
f0102713:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102716:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102719:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010271c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010271f:	8b 1a                	mov    (%edx),%ebx
f0102721:	8b 01                	mov    (%ecx),%eax
f0102723:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102726:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010272d:	eb 7f                	jmp    f01027ae <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010272f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102732:	01 d8                	add    %ebx,%eax
f0102734:	89 c6                	mov    %eax,%esi
f0102736:	c1 ee 1f             	shr    $0x1f,%esi
f0102739:	01 c6                	add    %eax,%esi
f010273b:	d1 fe                	sar    %esi
f010273d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102740:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102743:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102746:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102748:	eb 03                	jmp    f010274d <stab_binsearch+0x43>
			m--;
f010274a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010274d:	39 c3                	cmp    %eax,%ebx
f010274f:	7f 0d                	jg     f010275e <stab_binsearch+0x54>
f0102751:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102755:	83 ea 0c             	sub    $0xc,%edx
f0102758:	39 f9                	cmp    %edi,%ecx
f010275a:	75 ee                	jne    f010274a <stab_binsearch+0x40>
f010275c:	eb 05                	jmp    f0102763 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010275e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102761:	eb 4b                	jmp    f01027ae <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102763:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102766:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102769:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010276d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102770:	76 11                	jbe    f0102783 <stab_binsearch+0x79>
			*region_left = m;
f0102772:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102775:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102777:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010277a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102781:	eb 2b                	jmp    f01027ae <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102783:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102786:	73 14                	jae    f010279c <stab_binsearch+0x92>
			*region_right = m - 1;
f0102788:	83 e8 01             	sub    $0x1,%eax
f010278b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010278e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102791:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102793:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010279a:	eb 12                	jmp    f01027ae <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010279c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010279f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027a1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027a5:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027a7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027ae:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027b1:	0f 8e 78 ff ff ff    	jle    f010272f <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027b7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027bb:	75 0f                	jne    f01027cc <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027c0:	8b 00                	mov    (%eax),%eax
f01027c2:	83 e8 01             	sub    $0x1,%eax
f01027c5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027c8:	89 06                	mov    %eax,(%esi)
f01027ca:	eb 2c                	jmp    f01027f8 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027cf:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027d1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027d4:	8b 0e                	mov    (%esi),%ecx
f01027d6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027d9:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027dc:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027df:	eb 03                	jmp    f01027e4 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027e1:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027e4:	39 c8                	cmp    %ecx,%eax
f01027e6:	7e 0b                	jle    f01027f3 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027e8:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027ec:	83 ea 0c             	sub    $0xc,%edx
f01027ef:	39 df                	cmp    %ebx,%edi
f01027f1:	75 ee                	jne    f01027e1 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027f3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027f6:	89 06                	mov    %eax,(%esi)
	}
}
f01027f8:	83 c4 14             	add    $0x14,%esp
f01027fb:	5b                   	pop    %ebx
f01027fc:	5e                   	pop    %esi
f01027fd:	5f                   	pop    %edi
f01027fe:	5d                   	pop    %ebp
f01027ff:	c3                   	ret    

f0102800 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102800:	55                   	push   %ebp
f0102801:	89 e5                	mov    %esp,%ebp
f0102803:	57                   	push   %edi
f0102804:	56                   	push   %esi
f0102805:	53                   	push   %ebx
f0102806:	83 ec 1c             	sub    $0x1c,%esp
f0102809:	8b 7d 08             	mov    0x8(%ebp),%edi
f010280c:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010280f:	c7 06 b5 45 10 f0    	movl   $0xf01045b5,(%esi)
	info->eip_line = 0;
f0102815:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010281c:	c7 46 08 b5 45 10 f0 	movl   $0xf01045b5,0x8(%esi)
	info->eip_fn_namelen = 9;
f0102823:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010282a:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010282d:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102834:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010283a:	76 11                	jbe    f010284d <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010283c:	b8 4f bd 10 f0       	mov    $0xf010bd4f,%eax
f0102841:	3d 01 a0 10 f0       	cmp    $0xf010a001,%eax
f0102846:	77 19                	ja     f0102861 <debuginfo_eip+0x61>
f0102848:	e9 62 01 00 00       	jmp    f01029af <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010284d:	83 ec 04             	sub    $0x4,%esp
f0102850:	68 bf 45 10 f0       	push   $0xf01045bf
f0102855:	6a 7f                	push   $0x7f
f0102857:	68 cc 45 10 f0       	push   $0xf01045cc
f010285c:	e8 2a d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102861:	80 3d 4e bd 10 f0 00 	cmpb   $0x0,0xf010bd4e
f0102868:	0f 85 48 01 00 00    	jne    f01029b6 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010286e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102875:	b8 00 a0 10 f0       	mov    $0xf010a000,%eax
f010287a:	2d 10 48 10 f0       	sub    $0xf0104810,%eax
f010287f:	c1 f8 02             	sar    $0x2,%eax
f0102882:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102888:	83 e8 01             	sub    $0x1,%eax
f010288b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010288e:	83 ec 08             	sub    $0x8,%esp
f0102891:	57                   	push   %edi
f0102892:	6a 64                	push   $0x64
f0102894:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102897:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010289a:	b8 10 48 10 f0       	mov    $0xf0104810,%eax
f010289f:	e8 66 fe ff ff       	call   f010270a <stab_binsearch>
	if (lfile == 0)
f01028a4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028a7:	83 c4 10             	add    $0x10,%esp
f01028aa:	85 c0                	test   %eax,%eax
f01028ac:	0f 84 0b 01 00 00    	je     f01029bd <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028b2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028b8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028bb:	83 ec 08             	sub    $0x8,%esp
f01028be:	57                   	push   %edi
f01028bf:	6a 24                	push   $0x24
f01028c1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028c4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028c7:	b8 10 48 10 f0       	mov    $0xf0104810,%eax
f01028cc:	e8 39 fe ff ff       	call   f010270a <stab_binsearch>

	if (lfun <= rfun) {
f01028d1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01028d4:	83 c4 10             	add    $0x10,%esp
f01028d7:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01028da:	7f 31                	jg     f010290d <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028dc:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028df:	c1 e0 02             	shl    $0x2,%eax
f01028e2:	8d 90 10 48 10 f0    	lea    -0xfefb7f0(%eax),%edx
f01028e8:	8b 88 10 48 10 f0    	mov    -0xfefb7f0(%eax),%ecx
f01028ee:	b8 4f bd 10 f0       	mov    $0xf010bd4f,%eax
f01028f3:	2d 01 a0 10 f0       	sub    $0xf010a001,%eax
f01028f8:	39 c1                	cmp    %eax,%ecx
f01028fa:	73 09                	jae    f0102905 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01028fc:	81 c1 01 a0 10 f0    	add    $0xf010a001,%ecx
f0102902:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102905:	8b 42 08             	mov    0x8(%edx),%eax
f0102908:	89 46 10             	mov    %eax,0x10(%esi)
f010290b:	eb 06                	jmp    f0102913 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010290d:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102910:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102913:	83 ec 08             	sub    $0x8,%esp
f0102916:	6a 3a                	push   $0x3a
f0102918:	ff 76 08             	pushl  0x8(%esi)
f010291b:	e8 a3 08 00 00       	call   f01031c3 <strfind>
f0102920:	2b 46 08             	sub    0x8(%esi),%eax
f0102923:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102926:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102929:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010292c:	8d 04 85 10 48 10 f0 	lea    -0xfefb7f0(,%eax,4),%eax
f0102933:	83 c4 10             	add    $0x10,%esp
f0102936:	eb 06                	jmp    f010293e <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102938:	83 eb 01             	sub    $0x1,%ebx
f010293b:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010293e:	39 fb                	cmp    %edi,%ebx
f0102940:	7c 34                	jl     f0102976 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0102942:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0102946:	80 fa 84             	cmp    $0x84,%dl
f0102949:	74 0b                	je     f0102956 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010294b:	80 fa 64             	cmp    $0x64,%dl
f010294e:	75 e8                	jne    f0102938 <debuginfo_eip+0x138>
f0102950:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102954:	74 e2                	je     f0102938 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102956:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102959:	8b 14 85 10 48 10 f0 	mov    -0xfefb7f0(,%eax,4),%edx
f0102960:	b8 4f bd 10 f0       	mov    $0xf010bd4f,%eax
f0102965:	2d 01 a0 10 f0       	sub    $0xf010a001,%eax
f010296a:	39 c2                	cmp    %eax,%edx
f010296c:	73 08                	jae    f0102976 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010296e:	81 c2 01 a0 10 f0    	add    $0xf010a001,%edx
f0102974:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102976:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102979:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010297c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102981:	39 cb                	cmp    %ecx,%ebx
f0102983:	7d 44                	jge    f01029c9 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0102985:	8d 53 01             	lea    0x1(%ebx),%edx
f0102988:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010298b:	8d 04 85 10 48 10 f0 	lea    -0xfefb7f0(,%eax,4),%eax
f0102992:	eb 07                	jmp    f010299b <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102994:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102998:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010299b:	39 ca                	cmp    %ecx,%edx
f010299d:	74 25                	je     f01029c4 <debuginfo_eip+0x1c4>
f010299f:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029a2:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01029a6:	74 ec                	je     f0102994 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01029ad:	eb 1a                	jmp    f01029c9 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029b4:	eb 13                	jmp    f01029c9 <debuginfo_eip+0x1c9>
f01029b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029bb:	eb 0c                	jmp    f01029c9 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01029bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029c2:	eb 05                	jmp    f01029c9 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029c9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029cc:	5b                   	pop    %ebx
f01029cd:	5e                   	pop    %esi
f01029ce:	5f                   	pop    %edi
f01029cf:	5d                   	pop    %ebp
f01029d0:	c3                   	ret    

f01029d1 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01029d1:	55                   	push   %ebp
f01029d2:	89 e5                	mov    %esp,%ebp
f01029d4:	57                   	push   %edi
f01029d5:	56                   	push   %esi
f01029d6:	53                   	push   %ebx
f01029d7:	83 ec 1c             	sub    $0x1c,%esp
f01029da:	89 c7                	mov    %eax,%edi
f01029dc:	89 d6                	mov    %edx,%esi
f01029de:	8b 45 08             	mov    0x8(%ebp),%eax
f01029e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01029e4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01029e7:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01029ea:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01029ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01029f2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01029f5:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01029f8:	39 d3                	cmp    %edx,%ebx
f01029fa:	72 05                	jb     f0102a01 <printnum+0x30>
f01029fc:	39 45 10             	cmp    %eax,0x10(%ebp)
f01029ff:	77 45                	ja     f0102a46 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a01:	83 ec 0c             	sub    $0xc,%esp
f0102a04:	ff 75 18             	pushl  0x18(%ebp)
f0102a07:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a0a:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a0d:	53                   	push   %ebx
f0102a0e:	ff 75 10             	pushl  0x10(%ebp)
f0102a11:	83 ec 08             	sub    $0x8,%esp
f0102a14:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a17:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a1a:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a1d:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a20:	e8 cb 09 00 00       	call   f01033f0 <__udivdi3>
f0102a25:	83 c4 18             	add    $0x18,%esp
f0102a28:	52                   	push   %edx
f0102a29:	50                   	push   %eax
f0102a2a:	89 f2                	mov    %esi,%edx
f0102a2c:	89 f8                	mov    %edi,%eax
f0102a2e:	e8 9e ff ff ff       	call   f01029d1 <printnum>
f0102a33:	83 c4 20             	add    $0x20,%esp
f0102a36:	eb 18                	jmp    f0102a50 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a38:	83 ec 08             	sub    $0x8,%esp
f0102a3b:	56                   	push   %esi
f0102a3c:	ff 75 18             	pushl  0x18(%ebp)
f0102a3f:	ff d7                	call   *%edi
f0102a41:	83 c4 10             	add    $0x10,%esp
f0102a44:	eb 03                	jmp    f0102a49 <printnum+0x78>
f0102a46:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a49:	83 eb 01             	sub    $0x1,%ebx
f0102a4c:	85 db                	test   %ebx,%ebx
f0102a4e:	7f e8                	jg     f0102a38 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a50:	83 ec 08             	sub    $0x8,%esp
f0102a53:	56                   	push   %esi
f0102a54:	83 ec 04             	sub    $0x4,%esp
f0102a57:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a5a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a5d:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a60:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a63:	e8 b8 0a 00 00       	call   f0103520 <__umoddi3>
f0102a68:	83 c4 14             	add    $0x14,%esp
f0102a6b:	0f be 80 da 45 10 f0 	movsbl -0xfefba26(%eax),%eax
f0102a72:	50                   	push   %eax
f0102a73:	ff d7                	call   *%edi
}
f0102a75:	83 c4 10             	add    $0x10,%esp
f0102a78:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a7b:	5b                   	pop    %ebx
f0102a7c:	5e                   	pop    %esi
f0102a7d:	5f                   	pop    %edi
f0102a7e:	5d                   	pop    %ebp
f0102a7f:	c3                   	ret    

f0102a80 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102a80:	55                   	push   %ebp
f0102a81:	89 e5                	mov    %esp,%ebp
f0102a83:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102a86:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102a8a:	8b 10                	mov    (%eax),%edx
f0102a8c:	3b 50 04             	cmp    0x4(%eax),%edx
f0102a8f:	73 0a                	jae    f0102a9b <sprintputch+0x1b>
		*b->buf++ = ch;
f0102a91:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102a94:	89 08                	mov    %ecx,(%eax)
f0102a96:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a99:	88 02                	mov    %al,(%edx)
}
f0102a9b:	5d                   	pop    %ebp
f0102a9c:	c3                   	ret    

f0102a9d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102a9d:	55                   	push   %ebp
f0102a9e:	89 e5                	mov    %esp,%ebp
f0102aa0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102aa3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102aa6:	50                   	push   %eax
f0102aa7:	ff 75 10             	pushl  0x10(%ebp)
f0102aaa:	ff 75 0c             	pushl  0xc(%ebp)
f0102aad:	ff 75 08             	pushl  0x8(%ebp)
f0102ab0:	e8 05 00 00 00       	call   f0102aba <vprintfmt>
	va_end(ap);
}
f0102ab5:	83 c4 10             	add    $0x10,%esp
f0102ab8:	c9                   	leave  
f0102ab9:	c3                   	ret    

f0102aba <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102aba:	55                   	push   %ebp
f0102abb:	89 e5                	mov    %esp,%ebp
f0102abd:	57                   	push   %edi
f0102abe:	56                   	push   %esi
f0102abf:	53                   	push   %ebx
f0102ac0:	83 ec 2c             	sub    $0x2c,%esp
f0102ac3:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ac6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ac9:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102acc:	eb 12                	jmp    f0102ae0 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102ace:	85 c0                	test   %eax,%eax
f0102ad0:	0f 84 42 04 00 00    	je     f0102f18 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102ad6:	83 ec 08             	sub    $0x8,%esp
f0102ad9:	53                   	push   %ebx
f0102ada:	50                   	push   %eax
f0102adb:	ff d6                	call   *%esi
f0102add:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102ae0:	83 c7 01             	add    $0x1,%edi
f0102ae3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102ae7:	83 f8 25             	cmp    $0x25,%eax
f0102aea:	75 e2                	jne    f0102ace <vprintfmt+0x14>
f0102aec:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102af0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102af7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102afe:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b05:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b0a:	eb 07                	jmp    f0102b13 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b0f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b13:	8d 47 01             	lea    0x1(%edi),%eax
f0102b16:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b19:	0f b6 07             	movzbl (%edi),%eax
f0102b1c:	0f b6 d0             	movzbl %al,%edx
f0102b1f:	83 e8 23             	sub    $0x23,%eax
f0102b22:	3c 55                	cmp    $0x55,%al
f0102b24:	0f 87 d3 03 00 00    	ja     f0102efd <vprintfmt+0x443>
f0102b2a:	0f b6 c0             	movzbl %al,%eax
f0102b2d:	ff 24 85 80 46 10 f0 	jmp    *-0xfefb980(,%eax,4)
f0102b34:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102b37:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102b3b:	eb d6                	jmp    f0102b13 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b40:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b45:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102b48:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102b4b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102b4f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102b52:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102b55:	83 f9 09             	cmp    $0x9,%ecx
f0102b58:	77 3f                	ja     f0102b99 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102b5a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102b5d:	eb e9                	jmp    f0102b48 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102b5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b62:	8b 00                	mov    (%eax),%eax
f0102b64:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b67:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b6a:	8d 40 04             	lea    0x4(%eax),%eax
f0102b6d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b70:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102b73:	eb 2a                	jmp    f0102b9f <vprintfmt+0xe5>
f0102b75:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b78:	85 c0                	test   %eax,%eax
f0102b7a:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b7f:	0f 49 d0             	cmovns %eax,%edx
f0102b82:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b85:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b88:	eb 89                	jmp    f0102b13 <vprintfmt+0x59>
f0102b8a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102b8d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102b94:	e9 7a ff ff ff       	jmp    f0102b13 <vprintfmt+0x59>
f0102b99:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102b9c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102b9f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ba3:	0f 89 6a ff ff ff    	jns    f0102b13 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102ba9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102bac:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102baf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bb6:	e9 58 ff ff ff       	jmp    f0102b13 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102bbb:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bbe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102bc1:	e9 4d ff ff ff       	jmp    f0102b13 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102bc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bc9:	8d 78 04             	lea    0x4(%eax),%edi
f0102bcc:	83 ec 08             	sub    $0x8,%esp
f0102bcf:	53                   	push   %ebx
f0102bd0:	ff 30                	pushl  (%eax)
f0102bd2:	ff d6                	call   *%esi
			break;
f0102bd4:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102bd7:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102bdd:	e9 fe fe ff ff       	jmp    f0102ae0 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102be2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be5:	8d 78 04             	lea    0x4(%eax),%edi
f0102be8:	8b 00                	mov    (%eax),%eax
f0102bea:	99                   	cltd   
f0102beb:	31 d0                	xor    %edx,%eax
f0102bed:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102bef:	83 f8 07             	cmp    $0x7,%eax
f0102bf2:	7f 0b                	jg     f0102bff <vprintfmt+0x145>
f0102bf4:	8b 14 85 e0 47 10 f0 	mov    -0xfefb820(,%eax,4),%edx
f0102bfb:	85 d2                	test   %edx,%edx
f0102bfd:	75 1b                	jne    f0102c1a <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102bff:	50                   	push   %eax
f0102c00:	68 f2 45 10 f0       	push   $0xf01045f2
f0102c05:	53                   	push   %ebx
f0102c06:	56                   	push   %esi
f0102c07:	e8 91 fe ff ff       	call   f0102a9d <printfmt>
f0102c0c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c0f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c15:	e9 c6 fe ff ff       	jmp    f0102ae0 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c1a:	52                   	push   %edx
f0102c1b:	68 00 43 10 f0       	push   $0xf0104300
f0102c20:	53                   	push   %ebx
f0102c21:	56                   	push   %esi
f0102c22:	e8 76 fe ff ff       	call   f0102a9d <printfmt>
f0102c27:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c2a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c30:	e9 ab fe ff ff       	jmp    f0102ae0 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c35:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c38:	83 c0 04             	add    $0x4,%eax
f0102c3b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102c3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c41:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102c43:	85 ff                	test   %edi,%edi
f0102c45:	b8 eb 45 10 f0       	mov    $0xf01045eb,%eax
f0102c4a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102c4d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c51:	0f 8e 94 00 00 00    	jle    f0102ceb <vprintfmt+0x231>
f0102c57:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102c5b:	0f 84 98 00 00 00    	je     f0102cf9 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c61:	83 ec 08             	sub    $0x8,%esp
f0102c64:	ff 75 d0             	pushl  -0x30(%ebp)
f0102c67:	57                   	push   %edi
f0102c68:	e8 0c 04 00 00       	call   f0103079 <strnlen>
f0102c6d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102c70:	29 c1                	sub    %eax,%ecx
f0102c72:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102c75:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102c78:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102c7c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c7f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102c82:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c84:	eb 0f                	jmp    f0102c95 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102c86:	83 ec 08             	sub    $0x8,%esp
f0102c89:	53                   	push   %ebx
f0102c8a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c8d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c8f:	83 ef 01             	sub    $0x1,%edi
f0102c92:	83 c4 10             	add    $0x10,%esp
f0102c95:	85 ff                	test   %edi,%edi
f0102c97:	7f ed                	jg     f0102c86 <vprintfmt+0x1cc>
f0102c99:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c9c:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102c9f:	85 c9                	test   %ecx,%ecx
f0102ca1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ca6:	0f 49 c1             	cmovns %ecx,%eax
f0102ca9:	29 c1                	sub    %eax,%ecx
f0102cab:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cae:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cb1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cb4:	89 cb                	mov    %ecx,%ebx
f0102cb6:	eb 4d                	jmp    f0102d05 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102cb8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102cbc:	74 1b                	je     f0102cd9 <vprintfmt+0x21f>
f0102cbe:	0f be c0             	movsbl %al,%eax
f0102cc1:	83 e8 20             	sub    $0x20,%eax
f0102cc4:	83 f8 5e             	cmp    $0x5e,%eax
f0102cc7:	76 10                	jbe    f0102cd9 <vprintfmt+0x21f>
					putch('?', putdat);
f0102cc9:	83 ec 08             	sub    $0x8,%esp
f0102ccc:	ff 75 0c             	pushl  0xc(%ebp)
f0102ccf:	6a 3f                	push   $0x3f
f0102cd1:	ff 55 08             	call   *0x8(%ebp)
f0102cd4:	83 c4 10             	add    $0x10,%esp
f0102cd7:	eb 0d                	jmp    f0102ce6 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102cd9:	83 ec 08             	sub    $0x8,%esp
f0102cdc:	ff 75 0c             	pushl  0xc(%ebp)
f0102cdf:	52                   	push   %edx
f0102ce0:	ff 55 08             	call   *0x8(%ebp)
f0102ce3:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102ce6:	83 eb 01             	sub    $0x1,%ebx
f0102ce9:	eb 1a                	jmp    f0102d05 <vprintfmt+0x24b>
f0102ceb:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cee:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cf1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cf4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102cf7:	eb 0c                	jmp    f0102d05 <vprintfmt+0x24b>
f0102cf9:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cfc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cff:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d02:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d05:	83 c7 01             	add    $0x1,%edi
f0102d08:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d0c:	0f be d0             	movsbl %al,%edx
f0102d0f:	85 d2                	test   %edx,%edx
f0102d11:	74 23                	je     f0102d36 <vprintfmt+0x27c>
f0102d13:	85 f6                	test   %esi,%esi
f0102d15:	78 a1                	js     f0102cb8 <vprintfmt+0x1fe>
f0102d17:	83 ee 01             	sub    $0x1,%esi
f0102d1a:	79 9c                	jns    f0102cb8 <vprintfmt+0x1fe>
f0102d1c:	89 df                	mov    %ebx,%edi
f0102d1e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d21:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d24:	eb 18                	jmp    f0102d3e <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102d26:	83 ec 08             	sub    $0x8,%esp
f0102d29:	53                   	push   %ebx
f0102d2a:	6a 20                	push   $0x20
f0102d2c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102d2e:	83 ef 01             	sub    $0x1,%edi
f0102d31:	83 c4 10             	add    $0x10,%esp
f0102d34:	eb 08                	jmp    f0102d3e <vprintfmt+0x284>
f0102d36:	89 df                	mov    %ebx,%edi
f0102d38:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d3b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d3e:	85 ff                	test   %edi,%edi
f0102d40:	7f e4                	jg     f0102d26 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d42:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102d45:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d48:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d4b:	e9 90 fd ff ff       	jmp    f0102ae0 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d50:	83 f9 01             	cmp    $0x1,%ecx
f0102d53:	7e 19                	jle    f0102d6e <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102d55:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d58:	8b 50 04             	mov    0x4(%eax),%edx
f0102d5b:	8b 00                	mov    (%eax),%eax
f0102d5d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d60:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102d63:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d66:	8d 40 08             	lea    0x8(%eax),%eax
f0102d69:	89 45 14             	mov    %eax,0x14(%ebp)
f0102d6c:	eb 38                	jmp    f0102da6 <vprintfmt+0x2ec>
	else if (lflag)
f0102d6e:	85 c9                	test   %ecx,%ecx
f0102d70:	74 1b                	je     f0102d8d <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102d72:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d75:	8b 00                	mov    (%eax),%eax
f0102d77:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d7a:	89 c1                	mov    %eax,%ecx
f0102d7c:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d7f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d82:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d85:	8d 40 04             	lea    0x4(%eax),%eax
f0102d88:	89 45 14             	mov    %eax,0x14(%ebp)
f0102d8b:	eb 19                	jmp    f0102da6 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102d8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d90:	8b 00                	mov    (%eax),%eax
f0102d92:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d95:	89 c1                	mov    %eax,%ecx
f0102d97:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d9a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da0:	8d 40 04             	lea    0x4(%eax),%eax
f0102da3:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102da6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102da9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102dac:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102db1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102db5:	0f 89 0e 01 00 00    	jns    f0102ec9 <vprintfmt+0x40f>
				putch('-', putdat);
f0102dbb:	83 ec 08             	sub    $0x8,%esp
f0102dbe:	53                   	push   %ebx
f0102dbf:	6a 2d                	push   $0x2d
f0102dc1:	ff d6                	call   *%esi
				num = -(long long) num;
f0102dc3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102dc6:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102dc9:	f7 da                	neg    %edx
f0102dcb:	83 d1 00             	adc    $0x0,%ecx
f0102dce:	f7 d9                	neg    %ecx
f0102dd0:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102dd3:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102dd8:	e9 ec 00 00 00       	jmp    f0102ec9 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ddd:	83 f9 01             	cmp    $0x1,%ecx
f0102de0:	7e 18                	jle    f0102dfa <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102de2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de5:	8b 10                	mov    (%eax),%edx
f0102de7:	8b 48 04             	mov    0x4(%eax),%ecx
f0102dea:	8d 40 08             	lea    0x8(%eax),%eax
f0102ded:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102df0:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102df5:	e9 cf 00 00 00       	jmp    f0102ec9 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102dfa:	85 c9                	test   %ecx,%ecx
f0102dfc:	74 1a                	je     f0102e18 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102dfe:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e01:	8b 10                	mov    (%eax),%edx
f0102e03:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e08:	8d 40 04             	lea    0x4(%eax),%eax
f0102e0b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e0e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e13:	e9 b1 00 00 00       	jmp    f0102ec9 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102e18:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1b:	8b 10                	mov    (%eax),%edx
f0102e1d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e22:	8d 40 04             	lea    0x4(%eax),%eax
f0102e25:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e28:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e2d:	e9 97 00 00 00       	jmp    f0102ec9 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102e32:	83 ec 08             	sub    $0x8,%esp
f0102e35:	53                   	push   %ebx
f0102e36:	6a 58                	push   $0x58
f0102e38:	ff d6                	call   *%esi
			putch('X', putdat);
f0102e3a:	83 c4 08             	add    $0x8,%esp
f0102e3d:	53                   	push   %ebx
f0102e3e:	6a 58                	push   $0x58
f0102e40:	ff d6                	call   *%esi
			putch('X', putdat);
f0102e42:	83 c4 08             	add    $0x8,%esp
f0102e45:	53                   	push   %ebx
f0102e46:	6a 58                	push   $0x58
f0102e48:	ff d6                	call   *%esi
			break;
f0102e4a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102e50:	e9 8b fc ff ff       	jmp    f0102ae0 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e55:	83 ec 08             	sub    $0x8,%esp
f0102e58:	53                   	push   %ebx
f0102e59:	6a 30                	push   $0x30
f0102e5b:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e5d:	83 c4 08             	add    $0x8,%esp
f0102e60:	53                   	push   %ebx
f0102e61:	6a 78                	push   $0x78
f0102e63:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102e65:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e68:	8b 10                	mov    (%eax),%edx
f0102e6a:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e6f:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e72:	8d 40 04             	lea    0x4(%eax),%eax
f0102e75:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102e78:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102e7d:	eb 4a                	jmp    f0102ec9 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e7f:	83 f9 01             	cmp    $0x1,%ecx
f0102e82:	7e 15                	jle    f0102e99 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102e84:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e87:	8b 10                	mov    (%eax),%edx
f0102e89:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e8c:	8d 40 08             	lea    0x8(%eax),%eax
f0102e8f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102e92:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e97:	eb 30                	jmp    f0102ec9 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102e99:	85 c9                	test   %ecx,%ecx
f0102e9b:	74 17                	je     f0102eb4 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102e9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ea0:	8b 10                	mov    (%eax),%edx
f0102ea2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102ea7:	8d 40 04             	lea    0x4(%eax),%eax
f0102eaa:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102ead:	b8 10 00 00 00       	mov    $0x10,%eax
f0102eb2:	eb 15                	jmp    f0102ec9 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102eb4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eb7:	8b 10                	mov    (%eax),%edx
f0102eb9:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102ebe:	8d 40 04             	lea    0x4(%eax),%eax
f0102ec1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102ec4:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102ec9:	83 ec 0c             	sub    $0xc,%esp
f0102ecc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102ed0:	57                   	push   %edi
f0102ed1:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ed4:	50                   	push   %eax
f0102ed5:	51                   	push   %ecx
f0102ed6:	52                   	push   %edx
f0102ed7:	89 da                	mov    %ebx,%edx
f0102ed9:	89 f0                	mov    %esi,%eax
f0102edb:	e8 f1 fa ff ff       	call   f01029d1 <printnum>
			break;
f0102ee0:	83 c4 20             	add    $0x20,%esp
f0102ee3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ee6:	e9 f5 fb ff ff       	jmp    f0102ae0 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102eeb:	83 ec 08             	sub    $0x8,%esp
f0102eee:	53                   	push   %ebx
f0102eef:	52                   	push   %edx
f0102ef0:	ff d6                	call   *%esi
			break;
f0102ef2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ef5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ef8:	e9 e3 fb ff ff       	jmp    f0102ae0 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102efd:	83 ec 08             	sub    $0x8,%esp
f0102f00:	53                   	push   %ebx
f0102f01:	6a 25                	push   $0x25
f0102f03:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f05:	83 c4 10             	add    $0x10,%esp
f0102f08:	eb 03                	jmp    f0102f0d <vprintfmt+0x453>
f0102f0a:	83 ef 01             	sub    $0x1,%edi
f0102f0d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f11:	75 f7                	jne    f0102f0a <vprintfmt+0x450>
f0102f13:	e9 c8 fb ff ff       	jmp    f0102ae0 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f18:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f1b:	5b                   	pop    %ebx
f0102f1c:	5e                   	pop    %esi
f0102f1d:	5f                   	pop    %edi
f0102f1e:	5d                   	pop    %ebp
f0102f1f:	c3                   	ret    

f0102f20 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f20:	55                   	push   %ebp
f0102f21:	89 e5                	mov    %esp,%ebp
f0102f23:	83 ec 18             	sub    $0x18,%esp
f0102f26:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f29:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f2c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f2f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f33:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f3d:	85 c0                	test   %eax,%eax
f0102f3f:	74 26                	je     f0102f67 <vsnprintf+0x47>
f0102f41:	85 d2                	test   %edx,%edx
f0102f43:	7e 22                	jle    f0102f67 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f45:	ff 75 14             	pushl  0x14(%ebp)
f0102f48:	ff 75 10             	pushl  0x10(%ebp)
f0102f4b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f4e:	50                   	push   %eax
f0102f4f:	68 80 2a 10 f0       	push   $0xf0102a80
f0102f54:	e8 61 fb ff ff       	call   f0102aba <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f59:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f5c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f62:	83 c4 10             	add    $0x10,%esp
f0102f65:	eb 05                	jmp    f0102f6c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f67:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f6c:	c9                   	leave  
f0102f6d:	c3                   	ret    

f0102f6e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f6e:	55                   	push   %ebp
f0102f6f:	89 e5                	mov    %esp,%ebp
f0102f71:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f74:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f77:	50                   	push   %eax
f0102f78:	ff 75 10             	pushl  0x10(%ebp)
f0102f7b:	ff 75 0c             	pushl  0xc(%ebp)
f0102f7e:	ff 75 08             	pushl  0x8(%ebp)
f0102f81:	e8 9a ff ff ff       	call   f0102f20 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f86:	c9                   	leave  
f0102f87:	c3                   	ret    

f0102f88 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f88:	55                   	push   %ebp
f0102f89:	89 e5                	mov    %esp,%ebp
f0102f8b:	57                   	push   %edi
f0102f8c:	56                   	push   %esi
f0102f8d:	53                   	push   %ebx
f0102f8e:	83 ec 0c             	sub    $0xc,%esp
f0102f91:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f94:	85 c0                	test   %eax,%eax
f0102f96:	74 11                	je     f0102fa9 <readline+0x21>
		cprintf("%s", prompt);
f0102f98:	83 ec 08             	sub    $0x8,%esp
f0102f9b:	50                   	push   %eax
f0102f9c:	68 00 43 10 f0       	push   $0xf0104300
f0102fa1:	e8 50 f7 ff ff       	call   f01026f6 <cprintf>
f0102fa6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102fa9:	83 ec 0c             	sub    $0xc,%esp
f0102fac:	6a 00                	push   $0x0
f0102fae:	e8 60 d6 ff ff       	call   f0100613 <iscons>
f0102fb3:	89 c7                	mov    %eax,%edi
f0102fb5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102fb8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102fbd:	e8 40 d6 ff ff       	call   f0100602 <getchar>
f0102fc2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102fc4:	85 c0                	test   %eax,%eax
f0102fc6:	79 18                	jns    f0102fe0 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102fc8:	83 ec 08             	sub    $0x8,%esp
f0102fcb:	50                   	push   %eax
f0102fcc:	68 00 48 10 f0       	push   $0xf0104800
f0102fd1:	e8 20 f7 ff ff       	call   f01026f6 <cprintf>
			return NULL;
f0102fd6:	83 c4 10             	add    $0x10,%esp
f0102fd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fde:	eb 79                	jmp    f0103059 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fe0:	83 f8 08             	cmp    $0x8,%eax
f0102fe3:	0f 94 c2             	sete   %dl
f0102fe6:	83 f8 7f             	cmp    $0x7f,%eax
f0102fe9:	0f 94 c0             	sete   %al
f0102fec:	08 c2                	or     %al,%dl
f0102fee:	74 1a                	je     f010300a <readline+0x82>
f0102ff0:	85 f6                	test   %esi,%esi
f0102ff2:	7e 16                	jle    f010300a <readline+0x82>
			if (echoing)
f0102ff4:	85 ff                	test   %edi,%edi
f0102ff6:	74 0d                	je     f0103005 <readline+0x7d>
				cputchar('\b');
f0102ff8:	83 ec 0c             	sub    $0xc,%esp
f0102ffb:	6a 08                	push   $0x8
f0102ffd:	e8 f0 d5 ff ff       	call   f01005f2 <cputchar>
f0103002:	83 c4 10             	add    $0x10,%esp
			i--;
f0103005:	83 ee 01             	sub    $0x1,%esi
f0103008:	eb b3                	jmp    f0102fbd <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010300a:	83 fb 1f             	cmp    $0x1f,%ebx
f010300d:	7e 23                	jle    f0103032 <readline+0xaa>
f010300f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103015:	7f 1b                	jg     f0103032 <readline+0xaa>
			if (echoing)
f0103017:	85 ff                	test   %edi,%edi
f0103019:	74 0c                	je     f0103027 <readline+0x9f>
				cputchar(c);
f010301b:	83 ec 0c             	sub    $0xc,%esp
f010301e:	53                   	push   %ebx
f010301f:	e8 ce d5 ff ff       	call   f01005f2 <cputchar>
f0103024:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103027:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f010302d:	8d 76 01             	lea    0x1(%esi),%esi
f0103030:	eb 8b                	jmp    f0102fbd <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103032:	83 fb 0a             	cmp    $0xa,%ebx
f0103035:	74 05                	je     f010303c <readline+0xb4>
f0103037:	83 fb 0d             	cmp    $0xd,%ebx
f010303a:	75 81                	jne    f0102fbd <readline+0x35>
			if (echoing)
f010303c:	85 ff                	test   %edi,%edi
f010303e:	74 0d                	je     f010304d <readline+0xc5>
				cputchar('\n');
f0103040:	83 ec 0c             	sub    $0xc,%esp
f0103043:	6a 0a                	push   $0xa
f0103045:	e8 a8 d5 ff ff       	call   f01005f2 <cputchar>
f010304a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010304d:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0103054:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0103059:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010305c:	5b                   	pop    %ebx
f010305d:	5e                   	pop    %esi
f010305e:	5f                   	pop    %edi
f010305f:	5d                   	pop    %ebp
f0103060:	c3                   	ret    

f0103061 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103061:	55                   	push   %ebp
f0103062:	89 e5                	mov    %esp,%ebp
f0103064:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103067:	b8 00 00 00 00       	mov    $0x0,%eax
f010306c:	eb 03                	jmp    f0103071 <strlen+0x10>
		n++;
f010306e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103071:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103075:	75 f7                	jne    f010306e <strlen+0xd>
		n++;
	return n;
}
f0103077:	5d                   	pop    %ebp
f0103078:	c3                   	ret    

f0103079 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103079:	55                   	push   %ebp
f010307a:	89 e5                	mov    %esp,%ebp
f010307c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010307f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103082:	ba 00 00 00 00       	mov    $0x0,%edx
f0103087:	eb 03                	jmp    f010308c <strnlen+0x13>
		n++;
f0103089:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010308c:	39 c2                	cmp    %eax,%edx
f010308e:	74 08                	je     f0103098 <strnlen+0x1f>
f0103090:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103094:	75 f3                	jne    f0103089 <strnlen+0x10>
f0103096:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103098:	5d                   	pop    %ebp
f0103099:	c3                   	ret    

f010309a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010309a:	55                   	push   %ebp
f010309b:	89 e5                	mov    %esp,%ebp
f010309d:	53                   	push   %ebx
f010309e:	8b 45 08             	mov    0x8(%ebp),%eax
f01030a1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01030a4:	89 c2                	mov    %eax,%edx
f01030a6:	83 c2 01             	add    $0x1,%edx
f01030a9:	83 c1 01             	add    $0x1,%ecx
f01030ac:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01030b0:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030b3:	84 db                	test   %bl,%bl
f01030b5:	75 ef                	jne    f01030a6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01030b7:	5b                   	pop    %ebx
f01030b8:	5d                   	pop    %ebp
f01030b9:	c3                   	ret    

f01030ba <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030ba:	55                   	push   %ebp
f01030bb:	89 e5                	mov    %esp,%ebp
f01030bd:	53                   	push   %ebx
f01030be:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01030c1:	53                   	push   %ebx
f01030c2:	e8 9a ff ff ff       	call   f0103061 <strlen>
f01030c7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030ca:	ff 75 0c             	pushl  0xc(%ebp)
f01030cd:	01 d8                	add    %ebx,%eax
f01030cf:	50                   	push   %eax
f01030d0:	e8 c5 ff ff ff       	call   f010309a <strcpy>
	return dst;
}
f01030d5:	89 d8                	mov    %ebx,%eax
f01030d7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030da:	c9                   	leave  
f01030db:	c3                   	ret    

f01030dc <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030dc:	55                   	push   %ebp
f01030dd:	89 e5                	mov    %esp,%ebp
f01030df:	56                   	push   %esi
f01030e0:	53                   	push   %ebx
f01030e1:	8b 75 08             	mov    0x8(%ebp),%esi
f01030e4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030e7:	89 f3                	mov    %esi,%ebx
f01030e9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030ec:	89 f2                	mov    %esi,%edx
f01030ee:	eb 0f                	jmp    f01030ff <strncpy+0x23>
		*dst++ = *src;
f01030f0:	83 c2 01             	add    $0x1,%edx
f01030f3:	0f b6 01             	movzbl (%ecx),%eax
f01030f6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030f9:	80 39 01             	cmpb   $0x1,(%ecx)
f01030fc:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030ff:	39 da                	cmp    %ebx,%edx
f0103101:	75 ed                	jne    f01030f0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103103:	89 f0                	mov    %esi,%eax
f0103105:	5b                   	pop    %ebx
f0103106:	5e                   	pop    %esi
f0103107:	5d                   	pop    %ebp
f0103108:	c3                   	ret    

f0103109 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103109:	55                   	push   %ebp
f010310a:	89 e5                	mov    %esp,%ebp
f010310c:	56                   	push   %esi
f010310d:	53                   	push   %ebx
f010310e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103111:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103114:	8b 55 10             	mov    0x10(%ebp),%edx
f0103117:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103119:	85 d2                	test   %edx,%edx
f010311b:	74 21                	je     f010313e <strlcpy+0x35>
f010311d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103121:	89 f2                	mov    %esi,%edx
f0103123:	eb 09                	jmp    f010312e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103125:	83 c2 01             	add    $0x1,%edx
f0103128:	83 c1 01             	add    $0x1,%ecx
f010312b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010312e:	39 c2                	cmp    %eax,%edx
f0103130:	74 09                	je     f010313b <strlcpy+0x32>
f0103132:	0f b6 19             	movzbl (%ecx),%ebx
f0103135:	84 db                	test   %bl,%bl
f0103137:	75 ec                	jne    f0103125 <strlcpy+0x1c>
f0103139:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010313b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010313e:	29 f0                	sub    %esi,%eax
}
f0103140:	5b                   	pop    %ebx
f0103141:	5e                   	pop    %esi
f0103142:	5d                   	pop    %ebp
f0103143:	c3                   	ret    

f0103144 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103144:	55                   	push   %ebp
f0103145:	89 e5                	mov    %esp,%ebp
f0103147:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010314a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010314d:	eb 06                	jmp    f0103155 <strcmp+0x11>
		p++, q++;
f010314f:	83 c1 01             	add    $0x1,%ecx
f0103152:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103155:	0f b6 01             	movzbl (%ecx),%eax
f0103158:	84 c0                	test   %al,%al
f010315a:	74 04                	je     f0103160 <strcmp+0x1c>
f010315c:	3a 02                	cmp    (%edx),%al
f010315e:	74 ef                	je     f010314f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103160:	0f b6 c0             	movzbl %al,%eax
f0103163:	0f b6 12             	movzbl (%edx),%edx
f0103166:	29 d0                	sub    %edx,%eax
}
f0103168:	5d                   	pop    %ebp
f0103169:	c3                   	ret    

f010316a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010316a:	55                   	push   %ebp
f010316b:	89 e5                	mov    %esp,%ebp
f010316d:	53                   	push   %ebx
f010316e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103171:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103174:	89 c3                	mov    %eax,%ebx
f0103176:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103179:	eb 06                	jmp    f0103181 <strncmp+0x17>
		n--, p++, q++;
f010317b:	83 c0 01             	add    $0x1,%eax
f010317e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103181:	39 d8                	cmp    %ebx,%eax
f0103183:	74 15                	je     f010319a <strncmp+0x30>
f0103185:	0f b6 08             	movzbl (%eax),%ecx
f0103188:	84 c9                	test   %cl,%cl
f010318a:	74 04                	je     f0103190 <strncmp+0x26>
f010318c:	3a 0a                	cmp    (%edx),%cl
f010318e:	74 eb                	je     f010317b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103190:	0f b6 00             	movzbl (%eax),%eax
f0103193:	0f b6 12             	movzbl (%edx),%edx
f0103196:	29 d0                	sub    %edx,%eax
f0103198:	eb 05                	jmp    f010319f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010319a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010319f:	5b                   	pop    %ebx
f01031a0:	5d                   	pop    %ebp
f01031a1:	c3                   	ret    

f01031a2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01031a2:	55                   	push   %ebp
f01031a3:	89 e5                	mov    %esp,%ebp
f01031a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01031a8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031ac:	eb 07                	jmp    f01031b5 <strchr+0x13>
		if (*s == c)
f01031ae:	38 ca                	cmp    %cl,%dl
f01031b0:	74 0f                	je     f01031c1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01031b2:	83 c0 01             	add    $0x1,%eax
f01031b5:	0f b6 10             	movzbl (%eax),%edx
f01031b8:	84 d2                	test   %dl,%dl
f01031ba:	75 f2                	jne    f01031ae <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031c1:	5d                   	pop    %ebp
f01031c2:	c3                   	ret    

f01031c3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01031c3:	55                   	push   %ebp
f01031c4:	89 e5                	mov    %esp,%ebp
f01031c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01031c9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031cd:	eb 03                	jmp    f01031d2 <strfind+0xf>
f01031cf:	83 c0 01             	add    $0x1,%eax
f01031d2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031d5:	38 ca                	cmp    %cl,%dl
f01031d7:	74 04                	je     f01031dd <strfind+0x1a>
f01031d9:	84 d2                	test   %dl,%dl
f01031db:	75 f2                	jne    f01031cf <strfind+0xc>
			break;
	return (char *) s;
}
f01031dd:	5d                   	pop    %ebp
f01031de:	c3                   	ret    

f01031df <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031df:	55                   	push   %ebp
f01031e0:	89 e5                	mov    %esp,%ebp
f01031e2:	57                   	push   %edi
f01031e3:	56                   	push   %esi
f01031e4:	53                   	push   %ebx
f01031e5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031e8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031eb:	85 c9                	test   %ecx,%ecx
f01031ed:	74 36                	je     f0103225 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031ef:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031f5:	75 28                	jne    f010321f <memset+0x40>
f01031f7:	f6 c1 03             	test   $0x3,%cl
f01031fa:	75 23                	jne    f010321f <memset+0x40>
		c &= 0xFF;
f01031fc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103200:	89 d3                	mov    %edx,%ebx
f0103202:	c1 e3 08             	shl    $0x8,%ebx
f0103205:	89 d6                	mov    %edx,%esi
f0103207:	c1 e6 18             	shl    $0x18,%esi
f010320a:	89 d0                	mov    %edx,%eax
f010320c:	c1 e0 10             	shl    $0x10,%eax
f010320f:	09 f0                	or     %esi,%eax
f0103211:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103213:	89 d8                	mov    %ebx,%eax
f0103215:	09 d0                	or     %edx,%eax
f0103217:	c1 e9 02             	shr    $0x2,%ecx
f010321a:	fc                   	cld    
f010321b:	f3 ab                	rep stos %eax,%es:(%edi)
f010321d:	eb 06                	jmp    f0103225 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010321f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103222:	fc                   	cld    
f0103223:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103225:	89 f8                	mov    %edi,%eax
f0103227:	5b                   	pop    %ebx
f0103228:	5e                   	pop    %esi
f0103229:	5f                   	pop    %edi
f010322a:	5d                   	pop    %ebp
f010322b:	c3                   	ret    

f010322c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010322c:	55                   	push   %ebp
f010322d:	89 e5                	mov    %esp,%ebp
f010322f:	57                   	push   %edi
f0103230:	56                   	push   %esi
f0103231:	8b 45 08             	mov    0x8(%ebp),%eax
f0103234:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103237:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010323a:	39 c6                	cmp    %eax,%esi
f010323c:	73 35                	jae    f0103273 <memmove+0x47>
f010323e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103241:	39 d0                	cmp    %edx,%eax
f0103243:	73 2e                	jae    f0103273 <memmove+0x47>
		s += n;
		d += n;
f0103245:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103248:	89 d6                	mov    %edx,%esi
f010324a:	09 fe                	or     %edi,%esi
f010324c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103252:	75 13                	jne    f0103267 <memmove+0x3b>
f0103254:	f6 c1 03             	test   $0x3,%cl
f0103257:	75 0e                	jne    f0103267 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103259:	83 ef 04             	sub    $0x4,%edi
f010325c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010325f:	c1 e9 02             	shr    $0x2,%ecx
f0103262:	fd                   	std    
f0103263:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103265:	eb 09                	jmp    f0103270 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103267:	83 ef 01             	sub    $0x1,%edi
f010326a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010326d:	fd                   	std    
f010326e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103270:	fc                   	cld    
f0103271:	eb 1d                	jmp    f0103290 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103273:	89 f2                	mov    %esi,%edx
f0103275:	09 c2                	or     %eax,%edx
f0103277:	f6 c2 03             	test   $0x3,%dl
f010327a:	75 0f                	jne    f010328b <memmove+0x5f>
f010327c:	f6 c1 03             	test   $0x3,%cl
f010327f:	75 0a                	jne    f010328b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103281:	c1 e9 02             	shr    $0x2,%ecx
f0103284:	89 c7                	mov    %eax,%edi
f0103286:	fc                   	cld    
f0103287:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103289:	eb 05                	jmp    f0103290 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010328b:	89 c7                	mov    %eax,%edi
f010328d:	fc                   	cld    
f010328e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103290:	5e                   	pop    %esi
f0103291:	5f                   	pop    %edi
f0103292:	5d                   	pop    %ebp
f0103293:	c3                   	ret    

f0103294 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103294:	55                   	push   %ebp
f0103295:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103297:	ff 75 10             	pushl  0x10(%ebp)
f010329a:	ff 75 0c             	pushl  0xc(%ebp)
f010329d:	ff 75 08             	pushl  0x8(%ebp)
f01032a0:	e8 87 ff ff ff       	call   f010322c <memmove>
}
f01032a5:	c9                   	leave  
f01032a6:	c3                   	ret    

f01032a7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01032a7:	55                   	push   %ebp
f01032a8:	89 e5                	mov    %esp,%ebp
f01032aa:	56                   	push   %esi
f01032ab:	53                   	push   %ebx
f01032ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01032af:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032b2:	89 c6                	mov    %eax,%esi
f01032b4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032b7:	eb 1a                	jmp    f01032d3 <memcmp+0x2c>
		if (*s1 != *s2)
f01032b9:	0f b6 08             	movzbl (%eax),%ecx
f01032bc:	0f b6 1a             	movzbl (%edx),%ebx
f01032bf:	38 d9                	cmp    %bl,%cl
f01032c1:	74 0a                	je     f01032cd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01032c3:	0f b6 c1             	movzbl %cl,%eax
f01032c6:	0f b6 db             	movzbl %bl,%ebx
f01032c9:	29 d8                	sub    %ebx,%eax
f01032cb:	eb 0f                	jmp    f01032dc <memcmp+0x35>
		s1++, s2++;
f01032cd:	83 c0 01             	add    $0x1,%eax
f01032d0:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032d3:	39 f0                	cmp    %esi,%eax
f01032d5:	75 e2                	jne    f01032b9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032dc:	5b                   	pop    %ebx
f01032dd:	5e                   	pop    %esi
f01032de:	5d                   	pop    %ebp
f01032df:	c3                   	ret    

f01032e0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032e0:	55                   	push   %ebp
f01032e1:	89 e5                	mov    %esp,%ebp
f01032e3:	53                   	push   %ebx
f01032e4:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032e7:	89 c1                	mov    %eax,%ecx
f01032e9:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032ec:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032f0:	eb 0a                	jmp    f01032fc <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032f2:	0f b6 10             	movzbl (%eax),%edx
f01032f5:	39 da                	cmp    %ebx,%edx
f01032f7:	74 07                	je     f0103300 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032f9:	83 c0 01             	add    $0x1,%eax
f01032fc:	39 c8                	cmp    %ecx,%eax
f01032fe:	72 f2                	jb     f01032f2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103300:	5b                   	pop    %ebx
f0103301:	5d                   	pop    %ebp
f0103302:	c3                   	ret    

f0103303 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103303:	55                   	push   %ebp
f0103304:	89 e5                	mov    %esp,%ebp
f0103306:	57                   	push   %edi
f0103307:	56                   	push   %esi
f0103308:	53                   	push   %ebx
f0103309:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010330c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010330f:	eb 03                	jmp    f0103314 <strtol+0x11>
		s++;
f0103311:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103314:	0f b6 01             	movzbl (%ecx),%eax
f0103317:	3c 20                	cmp    $0x20,%al
f0103319:	74 f6                	je     f0103311 <strtol+0xe>
f010331b:	3c 09                	cmp    $0x9,%al
f010331d:	74 f2                	je     f0103311 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010331f:	3c 2b                	cmp    $0x2b,%al
f0103321:	75 0a                	jne    f010332d <strtol+0x2a>
		s++;
f0103323:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103326:	bf 00 00 00 00       	mov    $0x0,%edi
f010332b:	eb 11                	jmp    f010333e <strtol+0x3b>
f010332d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103332:	3c 2d                	cmp    $0x2d,%al
f0103334:	75 08                	jne    f010333e <strtol+0x3b>
		s++, neg = 1;
f0103336:	83 c1 01             	add    $0x1,%ecx
f0103339:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010333e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103344:	75 15                	jne    f010335b <strtol+0x58>
f0103346:	80 39 30             	cmpb   $0x30,(%ecx)
f0103349:	75 10                	jne    f010335b <strtol+0x58>
f010334b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010334f:	75 7c                	jne    f01033cd <strtol+0xca>
		s += 2, base = 16;
f0103351:	83 c1 02             	add    $0x2,%ecx
f0103354:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103359:	eb 16                	jmp    f0103371 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010335b:	85 db                	test   %ebx,%ebx
f010335d:	75 12                	jne    f0103371 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010335f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103364:	80 39 30             	cmpb   $0x30,(%ecx)
f0103367:	75 08                	jne    f0103371 <strtol+0x6e>
		s++, base = 8;
f0103369:	83 c1 01             	add    $0x1,%ecx
f010336c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103371:	b8 00 00 00 00       	mov    $0x0,%eax
f0103376:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103379:	0f b6 11             	movzbl (%ecx),%edx
f010337c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010337f:	89 f3                	mov    %esi,%ebx
f0103381:	80 fb 09             	cmp    $0x9,%bl
f0103384:	77 08                	ja     f010338e <strtol+0x8b>
			dig = *s - '0';
f0103386:	0f be d2             	movsbl %dl,%edx
f0103389:	83 ea 30             	sub    $0x30,%edx
f010338c:	eb 22                	jmp    f01033b0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010338e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103391:	89 f3                	mov    %esi,%ebx
f0103393:	80 fb 19             	cmp    $0x19,%bl
f0103396:	77 08                	ja     f01033a0 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103398:	0f be d2             	movsbl %dl,%edx
f010339b:	83 ea 57             	sub    $0x57,%edx
f010339e:	eb 10                	jmp    f01033b0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01033a0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01033a3:	89 f3                	mov    %esi,%ebx
f01033a5:	80 fb 19             	cmp    $0x19,%bl
f01033a8:	77 16                	ja     f01033c0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01033aa:	0f be d2             	movsbl %dl,%edx
f01033ad:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01033b0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033b3:	7d 0b                	jge    f01033c0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01033b5:	83 c1 01             	add    $0x1,%ecx
f01033b8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033bc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01033be:	eb b9                	jmp    f0103379 <strtol+0x76>

	if (endptr)
f01033c0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033c4:	74 0d                	je     f01033d3 <strtol+0xd0>
		*endptr = (char *) s;
f01033c6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033c9:	89 0e                	mov    %ecx,(%esi)
f01033cb:	eb 06                	jmp    f01033d3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033cd:	85 db                	test   %ebx,%ebx
f01033cf:	74 98                	je     f0103369 <strtol+0x66>
f01033d1:	eb 9e                	jmp    f0103371 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033d3:	89 c2                	mov    %eax,%edx
f01033d5:	f7 da                	neg    %edx
f01033d7:	85 ff                	test   %edi,%edi
f01033d9:	0f 45 c2             	cmovne %edx,%eax
}
f01033dc:	5b                   	pop    %ebx
f01033dd:	5e                   	pop    %esi
f01033de:	5f                   	pop    %edi
f01033df:	5d                   	pop    %ebp
f01033e0:	c3                   	ret    
f01033e1:	66 90                	xchg   %ax,%ax
f01033e3:	66 90                	xchg   %ax,%ax
f01033e5:	66 90                	xchg   %ax,%ax
f01033e7:	66 90                	xchg   %ax,%ax
f01033e9:	66 90                	xchg   %ax,%ax
f01033eb:	66 90                	xchg   %ax,%ax
f01033ed:	66 90                	xchg   %ax,%ax
f01033ef:	90                   	nop

f01033f0 <__udivdi3>:
f01033f0:	55                   	push   %ebp
f01033f1:	57                   	push   %edi
f01033f2:	56                   	push   %esi
f01033f3:	53                   	push   %ebx
f01033f4:	83 ec 1c             	sub    $0x1c,%esp
f01033f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103403:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103407:	85 f6                	test   %esi,%esi
f0103409:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010340d:	89 ca                	mov    %ecx,%edx
f010340f:	89 f8                	mov    %edi,%eax
f0103411:	75 3d                	jne    f0103450 <__udivdi3+0x60>
f0103413:	39 cf                	cmp    %ecx,%edi
f0103415:	0f 87 c5 00 00 00    	ja     f01034e0 <__udivdi3+0xf0>
f010341b:	85 ff                	test   %edi,%edi
f010341d:	89 fd                	mov    %edi,%ebp
f010341f:	75 0b                	jne    f010342c <__udivdi3+0x3c>
f0103421:	b8 01 00 00 00       	mov    $0x1,%eax
f0103426:	31 d2                	xor    %edx,%edx
f0103428:	f7 f7                	div    %edi
f010342a:	89 c5                	mov    %eax,%ebp
f010342c:	89 c8                	mov    %ecx,%eax
f010342e:	31 d2                	xor    %edx,%edx
f0103430:	f7 f5                	div    %ebp
f0103432:	89 c1                	mov    %eax,%ecx
f0103434:	89 d8                	mov    %ebx,%eax
f0103436:	89 cf                	mov    %ecx,%edi
f0103438:	f7 f5                	div    %ebp
f010343a:	89 c3                	mov    %eax,%ebx
f010343c:	89 d8                	mov    %ebx,%eax
f010343e:	89 fa                	mov    %edi,%edx
f0103440:	83 c4 1c             	add    $0x1c,%esp
f0103443:	5b                   	pop    %ebx
f0103444:	5e                   	pop    %esi
f0103445:	5f                   	pop    %edi
f0103446:	5d                   	pop    %ebp
f0103447:	c3                   	ret    
f0103448:	90                   	nop
f0103449:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103450:	39 ce                	cmp    %ecx,%esi
f0103452:	77 74                	ja     f01034c8 <__udivdi3+0xd8>
f0103454:	0f bd fe             	bsr    %esi,%edi
f0103457:	83 f7 1f             	xor    $0x1f,%edi
f010345a:	0f 84 98 00 00 00    	je     f01034f8 <__udivdi3+0x108>
f0103460:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103465:	89 f9                	mov    %edi,%ecx
f0103467:	89 c5                	mov    %eax,%ebp
f0103469:	29 fb                	sub    %edi,%ebx
f010346b:	d3 e6                	shl    %cl,%esi
f010346d:	89 d9                	mov    %ebx,%ecx
f010346f:	d3 ed                	shr    %cl,%ebp
f0103471:	89 f9                	mov    %edi,%ecx
f0103473:	d3 e0                	shl    %cl,%eax
f0103475:	09 ee                	or     %ebp,%esi
f0103477:	89 d9                	mov    %ebx,%ecx
f0103479:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010347d:	89 d5                	mov    %edx,%ebp
f010347f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103483:	d3 ed                	shr    %cl,%ebp
f0103485:	89 f9                	mov    %edi,%ecx
f0103487:	d3 e2                	shl    %cl,%edx
f0103489:	89 d9                	mov    %ebx,%ecx
f010348b:	d3 e8                	shr    %cl,%eax
f010348d:	09 c2                	or     %eax,%edx
f010348f:	89 d0                	mov    %edx,%eax
f0103491:	89 ea                	mov    %ebp,%edx
f0103493:	f7 f6                	div    %esi
f0103495:	89 d5                	mov    %edx,%ebp
f0103497:	89 c3                	mov    %eax,%ebx
f0103499:	f7 64 24 0c          	mull   0xc(%esp)
f010349d:	39 d5                	cmp    %edx,%ebp
f010349f:	72 10                	jb     f01034b1 <__udivdi3+0xc1>
f01034a1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01034a5:	89 f9                	mov    %edi,%ecx
f01034a7:	d3 e6                	shl    %cl,%esi
f01034a9:	39 c6                	cmp    %eax,%esi
f01034ab:	73 07                	jae    f01034b4 <__udivdi3+0xc4>
f01034ad:	39 d5                	cmp    %edx,%ebp
f01034af:	75 03                	jne    f01034b4 <__udivdi3+0xc4>
f01034b1:	83 eb 01             	sub    $0x1,%ebx
f01034b4:	31 ff                	xor    %edi,%edi
f01034b6:	89 d8                	mov    %ebx,%eax
f01034b8:	89 fa                	mov    %edi,%edx
f01034ba:	83 c4 1c             	add    $0x1c,%esp
f01034bd:	5b                   	pop    %ebx
f01034be:	5e                   	pop    %esi
f01034bf:	5f                   	pop    %edi
f01034c0:	5d                   	pop    %ebp
f01034c1:	c3                   	ret    
f01034c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034c8:	31 ff                	xor    %edi,%edi
f01034ca:	31 db                	xor    %ebx,%ebx
f01034cc:	89 d8                	mov    %ebx,%eax
f01034ce:	89 fa                	mov    %edi,%edx
f01034d0:	83 c4 1c             	add    $0x1c,%esp
f01034d3:	5b                   	pop    %ebx
f01034d4:	5e                   	pop    %esi
f01034d5:	5f                   	pop    %edi
f01034d6:	5d                   	pop    %ebp
f01034d7:	c3                   	ret    
f01034d8:	90                   	nop
f01034d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034e0:	89 d8                	mov    %ebx,%eax
f01034e2:	f7 f7                	div    %edi
f01034e4:	31 ff                	xor    %edi,%edi
f01034e6:	89 c3                	mov    %eax,%ebx
f01034e8:	89 d8                	mov    %ebx,%eax
f01034ea:	89 fa                	mov    %edi,%edx
f01034ec:	83 c4 1c             	add    $0x1c,%esp
f01034ef:	5b                   	pop    %ebx
f01034f0:	5e                   	pop    %esi
f01034f1:	5f                   	pop    %edi
f01034f2:	5d                   	pop    %ebp
f01034f3:	c3                   	ret    
f01034f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034f8:	39 ce                	cmp    %ecx,%esi
f01034fa:	72 0c                	jb     f0103508 <__udivdi3+0x118>
f01034fc:	31 db                	xor    %ebx,%ebx
f01034fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103502:	0f 87 34 ff ff ff    	ja     f010343c <__udivdi3+0x4c>
f0103508:	bb 01 00 00 00       	mov    $0x1,%ebx
f010350d:	e9 2a ff ff ff       	jmp    f010343c <__udivdi3+0x4c>
f0103512:	66 90                	xchg   %ax,%ax
f0103514:	66 90                	xchg   %ax,%ax
f0103516:	66 90                	xchg   %ax,%ax
f0103518:	66 90                	xchg   %ax,%ax
f010351a:	66 90                	xchg   %ax,%ax
f010351c:	66 90                	xchg   %ax,%ax
f010351e:	66 90                	xchg   %ax,%ax

f0103520 <__umoddi3>:
f0103520:	55                   	push   %ebp
f0103521:	57                   	push   %edi
f0103522:	56                   	push   %esi
f0103523:	53                   	push   %ebx
f0103524:	83 ec 1c             	sub    $0x1c,%esp
f0103527:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010352b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010352f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103533:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103537:	85 d2                	test   %edx,%edx
f0103539:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010353d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103541:	89 f3                	mov    %esi,%ebx
f0103543:	89 3c 24             	mov    %edi,(%esp)
f0103546:	89 74 24 04          	mov    %esi,0x4(%esp)
f010354a:	75 1c                	jne    f0103568 <__umoddi3+0x48>
f010354c:	39 f7                	cmp    %esi,%edi
f010354e:	76 50                	jbe    f01035a0 <__umoddi3+0x80>
f0103550:	89 c8                	mov    %ecx,%eax
f0103552:	89 f2                	mov    %esi,%edx
f0103554:	f7 f7                	div    %edi
f0103556:	89 d0                	mov    %edx,%eax
f0103558:	31 d2                	xor    %edx,%edx
f010355a:	83 c4 1c             	add    $0x1c,%esp
f010355d:	5b                   	pop    %ebx
f010355e:	5e                   	pop    %esi
f010355f:	5f                   	pop    %edi
f0103560:	5d                   	pop    %ebp
f0103561:	c3                   	ret    
f0103562:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103568:	39 f2                	cmp    %esi,%edx
f010356a:	89 d0                	mov    %edx,%eax
f010356c:	77 52                	ja     f01035c0 <__umoddi3+0xa0>
f010356e:	0f bd ea             	bsr    %edx,%ebp
f0103571:	83 f5 1f             	xor    $0x1f,%ebp
f0103574:	75 5a                	jne    f01035d0 <__umoddi3+0xb0>
f0103576:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010357a:	0f 82 e0 00 00 00    	jb     f0103660 <__umoddi3+0x140>
f0103580:	39 0c 24             	cmp    %ecx,(%esp)
f0103583:	0f 86 d7 00 00 00    	jbe    f0103660 <__umoddi3+0x140>
f0103589:	8b 44 24 08          	mov    0x8(%esp),%eax
f010358d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103591:	83 c4 1c             	add    $0x1c,%esp
f0103594:	5b                   	pop    %ebx
f0103595:	5e                   	pop    %esi
f0103596:	5f                   	pop    %edi
f0103597:	5d                   	pop    %ebp
f0103598:	c3                   	ret    
f0103599:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035a0:	85 ff                	test   %edi,%edi
f01035a2:	89 fd                	mov    %edi,%ebp
f01035a4:	75 0b                	jne    f01035b1 <__umoddi3+0x91>
f01035a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01035ab:	31 d2                	xor    %edx,%edx
f01035ad:	f7 f7                	div    %edi
f01035af:	89 c5                	mov    %eax,%ebp
f01035b1:	89 f0                	mov    %esi,%eax
f01035b3:	31 d2                	xor    %edx,%edx
f01035b5:	f7 f5                	div    %ebp
f01035b7:	89 c8                	mov    %ecx,%eax
f01035b9:	f7 f5                	div    %ebp
f01035bb:	89 d0                	mov    %edx,%eax
f01035bd:	eb 99                	jmp    f0103558 <__umoddi3+0x38>
f01035bf:	90                   	nop
f01035c0:	89 c8                	mov    %ecx,%eax
f01035c2:	89 f2                	mov    %esi,%edx
f01035c4:	83 c4 1c             	add    $0x1c,%esp
f01035c7:	5b                   	pop    %ebx
f01035c8:	5e                   	pop    %esi
f01035c9:	5f                   	pop    %edi
f01035ca:	5d                   	pop    %ebp
f01035cb:	c3                   	ret    
f01035cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035d0:	8b 34 24             	mov    (%esp),%esi
f01035d3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035d8:	89 e9                	mov    %ebp,%ecx
f01035da:	29 ef                	sub    %ebp,%edi
f01035dc:	d3 e0                	shl    %cl,%eax
f01035de:	89 f9                	mov    %edi,%ecx
f01035e0:	89 f2                	mov    %esi,%edx
f01035e2:	d3 ea                	shr    %cl,%edx
f01035e4:	89 e9                	mov    %ebp,%ecx
f01035e6:	09 c2                	or     %eax,%edx
f01035e8:	89 d8                	mov    %ebx,%eax
f01035ea:	89 14 24             	mov    %edx,(%esp)
f01035ed:	89 f2                	mov    %esi,%edx
f01035ef:	d3 e2                	shl    %cl,%edx
f01035f1:	89 f9                	mov    %edi,%ecx
f01035f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035fb:	d3 e8                	shr    %cl,%eax
f01035fd:	89 e9                	mov    %ebp,%ecx
f01035ff:	89 c6                	mov    %eax,%esi
f0103601:	d3 e3                	shl    %cl,%ebx
f0103603:	89 f9                	mov    %edi,%ecx
f0103605:	89 d0                	mov    %edx,%eax
f0103607:	d3 e8                	shr    %cl,%eax
f0103609:	89 e9                	mov    %ebp,%ecx
f010360b:	09 d8                	or     %ebx,%eax
f010360d:	89 d3                	mov    %edx,%ebx
f010360f:	89 f2                	mov    %esi,%edx
f0103611:	f7 34 24             	divl   (%esp)
f0103614:	89 d6                	mov    %edx,%esi
f0103616:	d3 e3                	shl    %cl,%ebx
f0103618:	f7 64 24 04          	mull   0x4(%esp)
f010361c:	39 d6                	cmp    %edx,%esi
f010361e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103622:	89 d1                	mov    %edx,%ecx
f0103624:	89 c3                	mov    %eax,%ebx
f0103626:	72 08                	jb     f0103630 <__umoddi3+0x110>
f0103628:	75 11                	jne    f010363b <__umoddi3+0x11b>
f010362a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010362e:	73 0b                	jae    f010363b <__umoddi3+0x11b>
f0103630:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103634:	1b 14 24             	sbb    (%esp),%edx
f0103637:	89 d1                	mov    %edx,%ecx
f0103639:	89 c3                	mov    %eax,%ebx
f010363b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010363f:	29 da                	sub    %ebx,%edx
f0103641:	19 ce                	sbb    %ecx,%esi
f0103643:	89 f9                	mov    %edi,%ecx
f0103645:	89 f0                	mov    %esi,%eax
f0103647:	d3 e0                	shl    %cl,%eax
f0103649:	89 e9                	mov    %ebp,%ecx
f010364b:	d3 ea                	shr    %cl,%edx
f010364d:	89 e9                	mov    %ebp,%ecx
f010364f:	d3 ee                	shr    %cl,%esi
f0103651:	09 d0                	or     %edx,%eax
f0103653:	89 f2                	mov    %esi,%edx
f0103655:	83 c4 1c             	add    $0x1c,%esp
f0103658:	5b                   	pop    %ebx
f0103659:	5e                   	pop    %esi
f010365a:	5f                   	pop    %edi
f010365b:	5d                   	pop    %ebp
f010365c:	c3                   	ret    
f010365d:	8d 76 00             	lea    0x0(%esi),%esi
f0103660:	29 f9                	sub    %edi,%ecx
f0103662:	19 d6                	sbb    %edx,%esi
f0103664:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103668:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010366c:	e9 18 ff ff ff       	jmp    f0103589 <__umoddi3+0x69>
