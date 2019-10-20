
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 40 18 10 f0       	push   $0xf0101840
f0100050:	e8 d7 08 00 00       	call   f010092c <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 fc 06 00 00       	call   f0100777 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 5c 18 10 f0       	push   $0xf010185c
f0100087:	e8 a0 08 00 00       	call   f010092c <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 e5 12 00 00       	call   f0101396 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 18 10 f0       	push   $0xf0101877
f01000c3:	e8 64 08 00 00       	call   f010092c <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 de 06 00 00       	call   f01007bf <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 92 18 10 f0       	push   $0xf0101892
f0100110:	e8 17 08 00 00       	call   f010092c <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 e7 07 00 00       	call   f0100906 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ce 18 10 f0 	movl   $0xf01018ce,(%esp)
f0100126:	e8 01 08 00 00       	call   f010092c <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 87 06 00 00       	call   f01007bf <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 aa 18 10 f0       	push   $0xf01018aa
f0100152:	e8 d5 07 00 00       	call   f010092c <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 a3 07 00 00       	call   f0100906 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ce 18 10 f0 	movl   $0xf01018ce,(%esp)
f010016a:	e8 bd 07 00 00       	call   f010092c <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a 20 19 10 f0 	movzbl -0xfefe6e0(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 00 19 10 f0 	mov    -0xfefe700(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 c4 18 10 f0       	push   $0xf01018c4
f01002c0:	e8 67 06 00 00       	call   f010092c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 75 0f 00 00       	call   f01013e3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100510:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100521:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 d0 18 10 f0       	push   $0xf01018d0
f010063d:	e8 ea 02 00 00       	call   f010092c <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 20 1b 10 f0       	push   $0xf0101b20
f0100683:	68 3e 1b 10 f0       	push   $0xf0101b3e
f0100688:	68 43 1b 10 f0       	push   $0xf0101b43
f010068d:	e8 9a 02 00 00       	call   f010092c <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 dc 1b 10 f0       	push   $0xf0101bdc
f010069a:	68 4c 1b 10 f0       	push   $0xf0101b4c
f010069f:	68 43 1b 10 f0       	push   $0xf0101b43
f01006a4:	e8 83 02 00 00       	call   f010092c <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 55 1b 10 f0       	push   $0xf0101b55
f01006b1:	68 6a 1b 10 f0       	push   $0xf0101b6a
f01006b6:	68 43 1b 10 f0       	push   $0xf0101b43
f01006bb:	e8 6c 02 00 00       	call   f010092c <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cd:	68 74 1b 10 f0       	push   $0xf0101b74
f01006d2:	e8 55 02 00 00       	call   f010092c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	83 c4 08             	add    $0x8,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 04 1c 10 f0       	push   $0xf0101c04
f01006e4:	e8 43 02 00 00       	call   f010092c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 0c 00 10 00       	push   $0x10000c
f01006f1:	68 0c 00 10 f0       	push   $0xf010000c
f01006f6:	68 2c 1c 10 f0       	push   $0xf0101c2c
f01006fb:	e8 2c 02 00 00       	call   f010092c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 21 18 10 00       	push   $0x101821
f0100708:	68 21 18 10 f0       	push   $0xf0101821
f010070d:	68 50 1c 10 f0       	push   $0xf0101c50
f0100712:	e8 15 02 00 00       	call   f010092c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 00 23 11 00       	push   $0x112300
f010071f:	68 00 23 11 f0       	push   $0xf0112300
f0100724:	68 74 1c 10 f0       	push   $0xf0101c74
f0100729:	e8 fe 01 00 00       	call   f010092c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	68 44 29 11 00       	push   $0x112944
f0100736:	68 44 29 11 f0       	push   $0xf0112944
f010073b:	68 98 1c 10 f0       	push   $0xf0101c98
f0100740:	e8 e7 01 00 00       	call   f010092c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100745:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010074a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074f:	83 c4 08             	add    $0x8,%esp
f0100752:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100757:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075d:	85 c0                	test   %eax,%eax
f010075f:	0f 48 c2             	cmovs  %edx,%eax
f0100762:	c1 f8 0a             	sar    $0xa,%eax
f0100765:	50                   	push   %eax
f0100766:	68 bc 1c 10 f0       	push   $0xf0101cbc
f010076b:	e8 bc 01 00 00       	call   f010092c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	53                   	push   %ebx
f010077b:	83 ec 10             	sub    $0x10,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010077e:	89 eb                	mov    %ebp,%ebx
	// Your code here
    uint32_t *ebp;
    ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
f0100780:	68 8d 1b 10 f0       	push   $0xf0101b8d
f0100785:	e8 a2 01 00 00       	call   f010092c <cprintf>
    while (ebp)
f010078a:	83 c4 10             	add    $0x10,%esp
f010078d:	eb 22                	jmp    f01007b1 <mon_backtrace+0x3a>
    {
	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", 
f010078f:	ff 73 18             	pushl  0x18(%ebx)
f0100792:	ff 73 14             	pushl  0x14(%ebx)
f0100795:	ff 73 10             	pushl  0x10(%ebx)
f0100798:	ff 73 0c             	pushl  0xc(%ebx)
f010079b:	ff 73 08             	pushl  0x8(%ebx)
f010079e:	ff 73 04             	pushl  0x4(%ebx)
f01007a1:	53                   	push   %ebx
f01007a2:	68 e8 1c 10 f0       	push   $0xf0101ce8
f01007a7:	e8 80 01 00 00       	call   f010092c <cprintf>
	 ebp, ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);

	ebp = (uint32_t *)*ebp;
f01007ac:	8b 1b                	mov    (%ebx),%ebx
f01007ae:	83 c4 20             	add    $0x20,%esp
{
	// Your code here
    uint32_t *ebp;
    ebp = (uint32_t *)read_ebp();
    cprintf("Stack backtrace:\n");
    while (ebp)
f01007b1:	85 db                	test   %ebx,%ebx
f01007b3:	75 da                	jne    f010078f <mon_backtrace+0x18>

	ebp = (uint32_t *)*ebp;
    }

	return 0;
}
f01007b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01007bd:	c9                   	leave  
f01007be:	c3                   	ret    

f01007bf <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007bf:	55                   	push   %ebp
f01007c0:	89 e5                	mov    %esp,%ebp
f01007c2:	57                   	push   %edi
f01007c3:	56                   	push   %esi
f01007c4:	53                   	push   %ebx
f01007c5:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007c8:	68 20 1d 10 f0       	push   $0xf0101d20
f01007cd:	e8 5a 01 00 00       	call   f010092c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007d2:	c7 04 24 44 1d 10 f0 	movl   $0xf0101d44,(%esp)
f01007d9:	e8 4e 01 00 00       	call   f010092c <cprintf>
f01007de:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007e1:	83 ec 0c             	sub    $0xc,%esp
f01007e4:	68 9f 1b 10 f0       	push   $0xf0101b9f
f01007e9:	e8 51 09 00 00       	call   f010113f <readline>
f01007ee:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007f0:	83 c4 10             	add    $0x10,%esp
f01007f3:	85 c0                	test   %eax,%eax
f01007f5:	74 ea                	je     f01007e1 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f7:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007fe:	be 00 00 00 00       	mov    $0x0,%esi
f0100803:	eb 0a                	jmp    f010080f <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100805:	c6 03 00             	movb   $0x0,(%ebx)
f0100808:	89 f7                	mov    %esi,%edi
f010080a:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010080d:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010080f:	0f b6 03             	movzbl (%ebx),%eax
f0100812:	84 c0                	test   %al,%al
f0100814:	74 63                	je     f0100879 <monitor+0xba>
f0100816:	83 ec 08             	sub    $0x8,%esp
f0100819:	0f be c0             	movsbl %al,%eax
f010081c:	50                   	push   %eax
f010081d:	68 a3 1b 10 f0       	push   $0xf0101ba3
f0100822:	e8 32 0b 00 00       	call   f0101359 <strchr>
f0100827:	83 c4 10             	add    $0x10,%esp
f010082a:	85 c0                	test   %eax,%eax
f010082c:	75 d7                	jne    f0100805 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010082e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100831:	74 46                	je     f0100879 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100833:	83 fe 0f             	cmp    $0xf,%esi
f0100836:	75 14                	jne    f010084c <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100838:	83 ec 08             	sub    $0x8,%esp
f010083b:	6a 10                	push   $0x10
f010083d:	68 a8 1b 10 f0       	push   $0xf0101ba8
f0100842:	e8 e5 00 00 00       	call   f010092c <cprintf>
f0100847:	83 c4 10             	add    $0x10,%esp
f010084a:	eb 95                	jmp    f01007e1 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010084c:	8d 7e 01             	lea    0x1(%esi),%edi
f010084f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100853:	eb 03                	jmp    f0100858 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100855:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100858:	0f b6 03             	movzbl (%ebx),%eax
f010085b:	84 c0                	test   %al,%al
f010085d:	74 ae                	je     f010080d <monitor+0x4e>
f010085f:	83 ec 08             	sub    $0x8,%esp
f0100862:	0f be c0             	movsbl %al,%eax
f0100865:	50                   	push   %eax
f0100866:	68 a3 1b 10 f0       	push   $0xf0101ba3
f010086b:	e8 e9 0a 00 00       	call   f0101359 <strchr>
f0100870:	83 c4 10             	add    $0x10,%esp
f0100873:	85 c0                	test   %eax,%eax
f0100875:	74 de                	je     f0100855 <monitor+0x96>
f0100877:	eb 94                	jmp    f010080d <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100879:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100880:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100881:	85 f6                	test   %esi,%esi
f0100883:	0f 84 58 ff ff ff    	je     f01007e1 <monitor+0x22>
f0100889:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010088e:	83 ec 08             	sub    $0x8,%esp
f0100891:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100894:	ff 34 85 80 1d 10 f0 	pushl  -0xfefe280(,%eax,4)
f010089b:	ff 75 a8             	pushl  -0x58(%ebp)
f010089e:	e8 58 0a 00 00       	call   f01012fb <strcmp>
f01008a3:	83 c4 10             	add    $0x10,%esp
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 21                	jne    f01008cb <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008aa:	83 ec 04             	sub    $0x4,%esp
f01008ad:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008b0:	ff 75 08             	pushl  0x8(%ebp)
f01008b3:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b6:	52                   	push   %edx
f01008b7:	56                   	push   %esi
f01008b8:	ff 14 85 88 1d 10 f0 	call   *-0xfefe278(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008bf:	83 c4 10             	add    $0x10,%esp
f01008c2:	85 c0                	test   %eax,%eax
f01008c4:	78 25                	js     f01008eb <monitor+0x12c>
f01008c6:	e9 16 ff ff ff       	jmp    f01007e1 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008cb:	83 c3 01             	add    $0x1,%ebx
f01008ce:	83 fb 03             	cmp    $0x3,%ebx
f01008d1:	75 bb                	jne    f010088e <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d3:	83 ec 08             	sub    $0x8,%esp
f01008d6:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d9:	68 c5 1b 10 f0       	push   $0xf0101bc5
f01008de:	e8 49 00 00 00       	call   f010092c <cprintf>
f01008e3:	83 c4 10             	add    $0x10,%esp
f01008e6:	e9 f6 fe ff ff       	jmp    f01007e1 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ee:	5b                   	pop    %ebx
f01008ef:	5e                   	pop    %esi
f01008f0:	5f                   	pop    %edi
f01008f1:	5d                   	pop    %ebp
f01008f2:	c3                   	ret    

f01008f3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008f3:	55                   	push   %ebp
f01008f4:	89 e5                	mov    %esp,%ebp
f01008f6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008f9:	ff 75 08             	pushl  0x8(%ebp)
f01008fc:	e8 4c fd ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0100901:	83 c4 10             	add    $0x10,%esp
f0100904:	c9                   	leave  
f0100905:	c3                   	ret    

f0100906 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100906:	55                   	push   %ebp
f0100907:	89 e5                	mov    %esp,%ebp
f0100909:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010090c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100913:	ff 75 0c             	pushl  0xc(%ebp)
f0100916:	ff 75 08             	pushl  0x8(%ebp)
f0100919:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010091c:	50                   	push   %eax
f010091d:	68 f3 08 10 f0       	push   $0xf01008f3
f0100922:	e8 03 04 00 00       	call   f0100d2a <vprintfmt>
	return cnt;
}
f0100927:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010092a:	c9                   	leave  
f010092b:	c3                   	ret    

f010092c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010092c:	55                   	push   %ebp
f010092d:	89 e5                	mov    %esp,%ebp
f010092f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100932:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100935:	50                   	push   %eax
f0100936:	ff 75 08             	pushl  0x8(%ebp)
f0100939:	e8 c8 ff ff ff       	call   f0100906 <vcprintf>
	va_end(ap);

	return cnt;
}
f010093e:	c9                   	leave  
f010093f:	c3                   	ret    

f0100940 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100940:	55                   	push   %ebp
f0100941:	89 e5                	mov    %esp,%ebp
f0100943:	57                   	push   %edi
f0100944:	56                   	push   %esi
f0100945:	53                   	push   %ebx
f0100946:	83 ec 14             	sub    $0x14,%esp
f0100949:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010094c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010094f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100952:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100955:	8b 1a                	mov    (%edx),%ebx
f0100957:	8b 01                	mov    (%ecx),%eax
f0100959:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010095c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100963:	eb 7f                	jmp    f01009e4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100965:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100968:	01 d8                	add    %ebx,%eax
f010096a:	89 c6                	mov    %eax,%esi
f010096c:	c1 ee 1f             	shr    $0x1f,%esi
f010096f:	01 c6                	add    %eax,%esi
f0100971:	d1 fe                	sar    %esi
f0100973:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100976:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100979:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010097c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010097e:	eb 03                	jmp    f0100983 <stab_binsearch+0x43>
			m--;
f0100980:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100983:	39 c3                	cmp    %eax,%ebx
f0100985:	7f 0d                	jg     f0100994 <stab_binsearch+0x54>
f0100987:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010098b:	83 ea 0c             	sub    $0xc,%edx
f010098e:	39 f9                	cmp    %edi,%ecx
f0100990:	75 ee                	jne    f0100980 <stab_binsearch+0x40>
f0100992:	eb 05                	jmp    f0100999 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100994:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100997:	eb 4b                	jmp    f01009e4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100999:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010099c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010099f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009a3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009a6:	76 11                	jbe    f01009b9 <stab_binsearch+0x79>
			*region_left = m;
f01009a8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009ab:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009ad:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009b7:	eb 2b                	jmp    f01009e4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009b9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009bc:	73 14                	jae    f01009d2 <stab_binsearch+0x92>
			*region_right = m - 1;
f01009be:	83 e8 01             	sub    $0x1,%eax
f01009c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009c7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009c9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009d0:	eb 12                	jmp    f01009e4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009d2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009d5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01009d7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01009db:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009dd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009e4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009e7:	0f 8e 78 ff ff ff    	jle    f0100965 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009ed:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009f1:	75 0f                	jne    f0100a02 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01009f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f6:	8b 00                	mov    (%eax),%eax
f01009f8:	83 e8 01             	sub    $0x1,%eax
f01009fb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009fe:	89 06                	mov    %eax,(%esi)
f0100a00:	eb 2c                	jmp    f0100a2e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a02:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a05:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a07:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a0a:	8b 0e                	mov    (%esi),%ecx
f0100a0c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a0f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a12:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a15:	eb 03                	jmp    f0100a1a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a17:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a1a:	39 c8                	cmp    %ecx,%eax
f0100a1c:	7e 0b                	jle    f0100a29 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a1e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a22:	83 ea 0c             	sub    $0xc,%edx
f0100a25:	39 df                	cmp    %ebx,%edi
f0100a27:	75 ee                	jne    f0100a17 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a29:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a2c:	89 06                	mov    %eax,(%esi)
	}
}
f0100a2e:	83 c4 14             	add    $0x14,%esp
f0100a31:	5b                   	pop    %ebx
f0100a32:	5e                   	pop    %esi
f0100a33:	5f                   	pop    %edi
f0100a34:	5d                   	pop    %ebp
f0100a35:	c3                   	ret    

f0100a36 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a36:	55                   	push   %ebp
f0100a37:	89 e5                	mov    %esp,%ebp
f0100a39:	57                   	push   %edi
f0100a3a:	56                   	push   %esi
f0100a3b:	53                   	push   %ebx
f0100a3c:	83 ec 1c             	sub    $0x1c,%esp
f0100a3f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100a42:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a45:	c7 06 a4 1d 10 f0    	movl   $0xf0101da4,(%esi)
	info->eip_line = 0;
f0100a4b:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a52:	c7 46 08 a4 1d 10 f0 	movl   $0xf0101da4,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a59:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a60:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a63:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a6a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a70:	76 11                	jbe    f0100a83 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a72:	b8 c7 71 10 f0       	mov    $0xf01071c7,%eax
f0100a77:	3d c1 58 10 f0       	cmp    $0xf01058c1,%eax
f0100a7c:	77 19                	ja     f0100a97 <debuginfo_eip+0x61>
f0100a7e:	e9 62 01 00 00       	jmp    f0100be5 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a83:	83 ec 04             	sub    $0x4,%esp
f0100a86:	68 ae 1d 10 f0       	push   $0xf0101dae
f0100a8b:	6a 7f                	push   $0x7f
f0100a8d:	68 bb 1d 10 f0       	push   $0xf0101dbb
f0100a92:	e8 4f f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a97:	80 3d c6 71 10 f0 00 	cmpb   $0x0,0xf01071c6
f0100a9e:	0f 85 48 01 00 00    	jne    f0100bec <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100aa4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aab:	b8 c0 58 10 f0       	mov    $0xf01058c0,%eax
f0100ab0:	2d f0 1f 10 f0       	sub    $0xf0101ff0,%eax
f0100ab5:	c1 f8 02             	sar    $0x2,%eax
f0100ab8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100abe:	83 e8 01             	sub    $0x1,%eax
f0100ac1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ac4:	83 ec 08             	sub    $0x8,%esp
f0100ac7:	57                   	push   %edi
f0100ac8:	6a 64                	push   $0x64
f0100aca:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100acd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ad0:	b8 f0 1f 10 f0       	mov    $0xf0101ff0,%eax
f0100ad5:	e8 66 fe ff ff       	call   f0100940 <stab_binsearch>
	if (lfile == 0)
f0100ada:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100add:	83 c4 10             	add    $0x10,%esp
f0100ae0:	85 c0                	test   %eax,%eax
f0100ae2:	0f 84 0b 01 00 00    	je     f0100bf3 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ae8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100aeb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aee:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100af1:	83 ec 08             	sub    $0x8,%esp
f0100af4:	57                   	push   %edi
f0100af5:	6a 24                	push   $0x24
f0100af7:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100afa:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100afd:	b8 f0 1f 10 f0       	mov    $0xf0101ff0,%eax
f0100b02:	e8 39 fe ff ff       	call   f0100940 <stab_binsearch>

	if (lfun <= rfun) {
f0100b07:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b0a:	83 c4 10             	add    $0x10,%esp
f0100b0d:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b10:	7f 31                	jg     f0100b43 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b12:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b15:	c1 e0 02             	shl    $0x2,%eax
f0100b18:	8d 90 f0 1f 10 f0    	lea    -0xfefe010(%eax),%edx
f0100b1e:	8b 88 f0 1f 10 f0    	mov    -0xfefe010(%eax),%ecx
f0100b24:	b8 c7 71 10 f0       	mov    $0xf01071c7,%eax
f0100b29:	2d c1 58 10 f0       	sub    $0xf01058c1,%eax
f0100b2e:	39 c1                	cmp    %eax,%ecx
f0100b30:	73 09                	jae    f0100b3b <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b32:	81 c1 c1 58 10 f0    	add    $0xf01058c1,%ecx
f0100b38:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b3b:	8b 42 08             	mov    0x8(%edx),%eax
f0100b3e:	89 46 10             	mov    %eax,0x10(%esi)
f0100b41:	eb 06                	jmp    f0100b49 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b43:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b46:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b49:	83 ec 08             	sub    $0x8,%esp
f0100b4c:	6a 3a                	push   $0x3a
f0100b4e:	ff 76 08             	pushl  0x8(%esi)
f0100b51:	e8 24 08 00 00       	call   f010137a <strfind>
f0100b56:	2b 46 08             	sub    0x8(%esi),%eax
f0100b59:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b5f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b62:	8d 04 85 f0 1f 10 f0 	lea    -0xfefe010(,%eax,4),%eax
f0100b69:	83 c4 10             	add    $0x10,%esp
f0100b6c:	eb 06                	jmp    f0100b74 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b6e:	83 eb 01             	sub    $0x1,%ebx
f0100b71:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b74:	39 fb                	cmp    %edi,%ebx
f0100b76:	7c 34                	jl     f0100bac <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100b78:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b7c:	80 fa 84             	cmp    $0x84,%dl
f0100b7f:	74 0b                	je     f0100b8c <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b81:	80 fa 64             	cmp    $0x64,%dl
f0100b84:	75 e8                	jne    f0100b6e <debuginfo_eip+0x138>
f0100b86:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b8a:	74 e2                	je     f0100b6e <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b8c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b8f:	8b 14 85 f0 1f 10 f0 	mov    -0xfefe010(,%eax,4),%edx
f0100b96:	b8 c7 71 10 f0       	mov    $0xf01071c7,%eax
f0100b9b:	2d c1 58 10 f0       	sub    $0xf01058c1,%eax
f0100ba0:	39 c2                	cmp    %eax,%edx
f0100ba2:	73 08                	jae    f0100bac <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ba4:	81 c2 c1 58 10 f0    	add    $0xf01058c1,%edx
f0100baa:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bac:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100baf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bb2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bb7:	39 cb                	cmp    %ecx,%ebx
f0100bb9:	7d 44                	jge    f0100bff <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100bbb:	8d 53 01             	lea    0x1(%ebx),%edx
f0100bbe:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bc1:	8d 04 85 f0 1f 10 f0 	lea    -0xfefe010(,%eax,4),%eax
f0100bc8:	eb 07                	jmp    f0100bd1 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bca:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bce:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bd1:	39 ca                	cmp    %ecx,%edx
f0100bd3:	74 25                	je     f0100bfa <debuginfo_eip+0x1c4>
f0100bd5:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bd8:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bdc:	74 ec                	je     f0100bca <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bde:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be3:	eb 1a                	jmp    f0100bff <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100be5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bea:	eb 13                	jmp    f0100bff <debuginfo_eip+0x1c9>
f0100bec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bf1:	eb 0c                	jmp    f0100bff <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bf8:	eb 05                	jmp    f0100bff <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bfa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c02:	5b                   	pop    %ebx
f0100c03:	5e                   	pop    %esi
f0100c04:	5f                   	pop    %edi
f0100c05:	5d                   	pop    %ebp
f0100c06:	c3                   	ret    

f0100c07 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c07:	55                   	push   %ebp
f0100c08:	89 e5                	mov    %esp,%ebp
f0100c0a:	57                   	push   %edi
f0100c0b:	56                   	push   %esi
f0100c0c:	53                   	push   %ebx
f0100c0d:	83 ec 1c             	sub    $0x1c,%esp
f0100c10:	89 c7                	mov    %eax,%edi
f0100c12:	89 d6                	mov    %edx,%esi
f0100c14:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c17:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c1a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c1d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c20:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c23:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c28:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c2b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c2e:	39 d3                	cmp    %edx,%ebx
f0100c30:	72 05                	jb     f0100c37 <printnum+0x30>
f0100c32:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c35:	77 45                	ja     f0100c7c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c37:	83 ec 0c             	sub    $0xc,%esp
f0100c3a:	ff 75 18             	pushl  0x18(%ebp)
f0100c3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c40:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c43:	53                   	push   %ebx
f0100c44:	ff 75 10             	pushl  0x10(%ebp)
f0100c47:	83 ec 08             	sub    $0x8,%esp
f0100c4a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c4d:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c50:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c53:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c56:	e8 45 09 00 00       	call   f01015a0 <__udivdi3>
f0100c5b:	83 c4 18             	add    $0x18,%esp
f0100c5e:	52                   	push   %edx
f0100c5f:	50                   	push   %eax
f0100c60:	89 f2                	mov    %esi,%edx
f0100c62:	89 f8                	mov    %edi,%eax
f0100c64:	e8 9e ff ff ff       	call   f0100c07 <printnum>
f0100c69:	83 c4 20             	add    $0x20,%esp
f0100c6c:	eb 18                	jmp    f0100c86 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c6e:	83 ec 08             	sub    $0x8,%esp
f0100c71:	56                   	push   %esi
f0100c72:	ff 75 18             	pushl  0x18(%ebp)
f0100c75:	ff d7                	call   *%edi
f0100c77:	83 c4 10             	add    $0x10,%esp
f0100c7a:	eb 03                	jmp    f0100c7f <printnum+0x78>
f0100c7c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c7f:	83 eb 01             	sub    $0x1,%ebx
f0100c82:	85 db                	test   %ebx,%ebx
f0100c84:	7f e8                	jg     f0100c6e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c86:	83 ec 08             	sub    $0x8,%esp
f0100c89:	56                   	push   %esi
f0100c8a:	83 ec 04             	sub    $0x4,%esp
f0100c8d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c90:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c93:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c96:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c99:	e8 32 0a 00 00       	call   f01016d0 <__umoddi3>
f0100c9e:	83 c4 14             	add    $0x14,%esp
f0100ca1:	0f be 80 c9 1d 10 f0 	movsbl -0xfefe237(%eax),%eax
f0100ca8:	50                   	push   %eax
f0100ca9:	ff d7                	call   *%edi
}
f0100cab:	83 c4 10             	add    $0x10,%esp
f0100cae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cb1:	5b                   	pop    %ebx
f0100cb2:	5e                   	pop    %esi
f0100cb3:	5f                   	pop    %edi
f0100cb4:	5d                   	pop    %ebp
f0100cb5:	c3                   	ret    

f0100cb6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100cb6:	55                   	push   %ebp
f0100cb7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100cb9:	83 fa 01             	cmp    $0x1,%edx
f0100cbc:	7e 0e                	jle    f0100ccc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100cbe:	8b 10                	mov    (%eax),%edx
f0100cc0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100cc3:	89 08                	mov    %ecx,(%eax)
f0100cc5:	8b 02                	mov    (%edx),%eax
f0100cc7:	8b 52 04             	mov    0x4(%edx),%edx
f0100cca:	eb 22                	jmp    f0100cee <getuint+0x38>
	else if (lflag)
f0100ccc:	85 d2                	test   %edx,%edx
f0100cce:	74 10                	je     f0100ce0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100cd0:	8b 10                	mov    (%eax),%edx
f0100cd2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100cd5:	89 08                	mov    %ecx,(%eax)
f0100cd7:	8b 02                	mov    (%edx),%eax
f0100cd9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cde:	eb 0e                	jmp    f0100cee <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ce0:	8b 10                	mov    (%eax),%edx
f0100ce2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ce5:	89 08                	mov    %ecx,(%eax)
f0100ce7:	8b 02                	mov    (%edx),%eax
f0100ce9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100cee:	5d                   	pop    %ebp
f0100cef:	c3                   	ret    

f0100cf0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cf0:	55                   	push   %ebp
f0100cf1:	89 e5                	mov    %esp,%ebp
f0100cf3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cf6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100cfa:	8b 10                	mov    (%eax),%edx
f0100cfc:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cff:	73 0a                	jae    f0100d0b <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d01:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d04:	89 08                	mov    %ecx,(%eax)
f0100d06:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d09:	88 02                	mov    %al,(%edx)
}
f0100d0b:	5d                   	pop    %ebp
f0100d0c:	c3                   	ret    

f0100d0d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d0d:	55                   	push   %ebp
f0100d0e:	89 e5                	mov    %esp,%ebp
f0100d10:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d13:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d16:	50                   	push   %eax
f0100d17:	ff 75 10             	pushl  0x10(%ebp)
f0100d1a:	ff 75 0c             	pushl  0xc(%ebp)
f0100d1d:	ff 75 08             	pushl  0x8(%ebp)
f0100d20:	e8 05 00 00 00       	call   f0100d2a <vprintfmt>
	va_end(ap);
}
f0100d25:	83 c4 10             	add    $0x10,%esp
f0100d28:	c9                   	leave  
f0100d29:	c3                   	ret    

f0100d2a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d2a:	55                   	push   %ebp
f0100d2b:	89 e5                	mov    %esp,%ebp
f0100d2d:	57                   	push   %edi
f0100d2e:	56                   	push   %esi
f0100d2f:	53                   	push   %ebx
f0100d30:	83 ec 2c             	sub    $0x2c,%esp
f0100d33:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d36:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d39:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d3c:	eb 12                	jmp    f0100d50 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d3e:	85 c0                	test   %eax,%eax
f0100d40:	0f 84 89 03 00 00    	je     f01010cf <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100d46:	83 ec 08             	sub    $0x8,%esp
f0100d49:	53                   	push   %ebx
f0100d4a:	50                   	push   %eax
f0100d4b:	ff d6                	call   *%esi
f0100d4d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d50:	83 c7 01             	add    $0x1,%edi
f0100d53:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d57:	83 f8 25             	cmp    $0x25,%eax
f0100d5a:	75 e2                	jne    f0100d3e <vprintfmt+0x14>
f0100d5c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d60:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d67:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d6e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100d75:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d7a:	eb 07                	jmp    f0100d83 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d7f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d83:	8d 47 01             	lea    0x1(%edi),%eax
f0100d86:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d89:	0f b6 07             	movzbl (%edi),%eax
f0100d8c:	0f b6 c8             	movzbl %al,%ecx
f0100d8f:	83 e8 23             	sub    $0x23,%eax
f0100d92:	3c 55                	cmp    $0x55,%al
f0100d94:	0f 87 1a 03 00 00    	ja     f01010b4 <vprintfmt+0x38a>
f0100d9a:	0f b6 c0             	movzbl %al,%eax
f0100d9d:	ff 24 85 60 1e 10 f0 	jmp    *-0xfefe1a0(,%eax,4)
f0100da4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100da7:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100dab:	eb d6                	jmp    f0100d83 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100db0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100db5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100db8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100dbb:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100dbf:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100dc2:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100dc5:	83 fa 09             	cmp    $0x9,%edx
f0100dc8:	77 39                	ja     f0100e03 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100dca:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100dcd:	eb e9                	jmp    f0100db8 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100dcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dd2:	8d 48 04             	lea    0x4(%eax),%ecx
f0100dd5:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100dd8:	8b 00                	mov    (%eax),%eax
f0100dda:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ddd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100de0:	eb 27                	jmp    f0100e09 <vprintfmt+0xdf>
f0100de2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100de5:	85 c0                	test   %eax,%eax
f0100de7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dec:	0f 49 c8             	cmovns %eax,%ecx
f0100def:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100df2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100df5:	eb 8c                	jmp    f0100d83 <vprintfmt+0x59>
f0100df7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100dfa:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e01:	eb 80                	jmp    f0100d83 <vprintfmt+0x59>
f0100e03:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e06:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e09:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e0d:	0f 89 70 ff ff ff    	jns    f0100d83 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e13:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e16:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e19:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e20:	e9 5e ff ff ff       	jmp    f0100d83 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e25:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e2b:	e9 53 ff ff ff       	jmp    f0100d83 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e30:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e33:	8d 50 04             	lea    0x4(%eax),%edx
f0100e36:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e39:	83 ec 08             	sub    $0x8,%esp
f0100e3c:	53                   	push   %ebx
f0100e3d:	ff 30                	pushl  (%eax)
f0100e3f:	ff d6                	call   *%esi
			break;
f0100e41:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e47:	e9 04 ff ff ff       	jmp    f0100d50 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e4f:	8d 50 04             	lea    0x4(%eax),%edx
f0100e52:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e55:	8b 00                	mov    (%eax),%eax
f0100e57:	99                   	cltd   
f0100e58:	31 d0                	xor    %edx,%eax
f0100e5a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e5c:	83 f8 07             	cmp    $0x7,%eax
f0100e5f:	7f 0b                	jg     f0100e6c <vprintfmt+0x142>
f0100e61:	8b 14 85 c0 1f 10 f0 	mov    -0xfefe040(,%eax,4),%edx
f0100e68:	85 d2                	test   %edx,%edx
f0100e6a:	75 18                	jne    f0100e84 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100e6c:	50                   	push   %eax
f0100e6d:	68 e1 1d 10 f0       	push   $0xf0101de1
f0100e72:	53                   	push   %ebx
f0100e73:	56                   	push   %esi
f0100e74:	e8 94 fe ff ff       	call   f0100d0d <printfmt>
f0100e79:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e7f:	e9 cc fe ff ff       	jmp    f0100d50 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100e84:	52                   	push   %edx
f0100e85:	68 ea 1d 10 f0       	push   $0xf0101dea
f0100e8a:	53                   	push   %ebx
f0100e8b:	56                   	push   %esi
f0100e8c:	e8 7c fe ff ff       	call   f0100d0d <printfmt>
f0100e91:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e94:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e97:	e9 b4 fe ff ff       	jmp    f0100d50 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e9c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e9f:	8d 50 04             	lea    0x4(%eax),%edx
f0100ea2:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ea5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100ea7:	85 ff                	test   %edi,%edi
f0100ea9:	b8 da 1d 10 f0       	mov    $0xf0101dda,%eax
f0100eae:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100eb1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100eb5:	0f 8e 94 00 00 00    	jle    f0100f4f <vprintfmt+0x225>
f0100ebb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100ebf:	0f 84 98 00 00 00    	je     f0100f5d <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ec5:	83 ec 08             	sub    $0x8,%esp
f0100ec8:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ecb:	57                   	push   %edi
f0100ecc:	e8 5f 03 00 00       	call   f0101230 <strnlen>
f0100ed1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100ed4:	29 c1                	sub    %eax,%ecx
f0100ed6:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100ed9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100edc:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100ee0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ee3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ee6:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ee8:	eb 0f                	jmp    f0100ef9 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100eea:	83 ec 08             	sub    $0x8,%esp
f0100eed:	53                   	push   %ebx
f0100eee:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ef1:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ef3:	83 ef 01             	sub    $0x1,%edi
f0100ef6:	83 c4 10             	add    $0x10,%esp
f0100ef9:	85 ff                	test   %edi,%edi
f0100efb:	7f ed                	jg     f0100eea <vprintfmt+0x1c0>
f0100efd:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f00:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f03:	85 c9                	test   %ecx,%ecx
f0100f05:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f0a:	0f 49 c1             	cmovns %ecx,%eax
f0100f0d:	29 c1                	sub    %eax,%ecx
f0100f0f:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f12:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f15:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f18:	89 cb                	mov    %ecx,%ebx
f0100f1a:	eb 4d                	jmp    f0100f69 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f1c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f20:	74 1b                	je     f0100f3d <vprintfmt+0x213>
f0100f22:	0f be c0             	movsbl %al,%eax
f0100f25:	83 e8 20             	sub    $0x20,%eax
f0100f28:	83 f8 5e             	cmp    $0x5e,%eax
f0100f2b:	76 10                	jbe    f0100f3d <vprintfmt+0x213>
					putch('?', putdat);
f0100f2d:	83 ec 08             	sub    $0x8,%esp
f0100f30:	ff 75 0c             	pushl  0xc(%ebp)
f0100f33:	6a 3f                	push   $0x3f
f0100f35:	ff 55 08             	call   *0x8(%ebp)
f0100f38:	83 c4 10             	add    $0x10,%esp
f0100f3b:	eb 0d                	jmp    f0100f4a <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100f3d:	83 ec 08             	sub    $0x8,%esp
f0100f40:	ff 75 0c             	pushl  0xc(%ebp)
f0100f43:	52                   	push   %edx
f0100f44:	ff 55 08             	call   *0x8(%ebp)
f0100f47:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f4a:	83 eb 01             	sub    $0x1,%ebx
f0100f4d:	eb 1a                	jmp    f0100f69 <vprintfmt+0x23f>
f0100f4f:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f52:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f55:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f58:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f5b:	eb 0c                	jmp    f0100f69 <vprintfmt+0x23f>
f0100f5d:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f60:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f63:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f66:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f69:	83 c7 01             	add    $0x1,%edi
f0100f6c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100f70:	0f be d0             	movsbl %al,%edx
f0100f73:	85 d2                	test   %edx,%edx
f0100f75:	74 23                	je     f0100f9a <vprintfmt+0x270>
f0100f77:	85 f6                	test   %esi,%esi
f0100f79:	78 a1                	js     f0100f1c <vprintfmt+0x1f2>
f0100f7b:	83 ee 01             	sub    $0x1,%esi
f0100f7e:	79 9c                	jns    f0100f1c <vprintfmt+0x1f2>
f0100f80:	89 df                	mov    %ebx,%edi
f0100f82:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f85:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f88:	eb 18                	jmp    f0100fa2 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100f8a:	83 ec 08             	sub    $0x8,%esp
f0100f8d:	53                   	push   %ebx
f0100f8e:	6a 20                	push   $0x20
f0100f90:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f92:	83 ef 01             	sub    $0x1,%edi
f0100f95:	83 c4 10             	add    $0x10,%esp
f0100f98:	eb 08                	jmp    f0100fa2 <vprintfmt+0x278>
f0100f9a:	89 df                	mov    %ebx,%edi
f0100f9c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f9f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fa2:	85 ff                	test   %edi,%edi
f0100fa4:	7f e4                	jg     f0100f8a <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fa9:	e9 a2 fd ff ff       	jmp    f0100d50 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fae:	83 fa 01             	cmp    $0x1,%edx
f0100fb1:	7e 16                	jle    f0100fc9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0100fb3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb6:	8d 50 08             	lea    0x8(%eax),%edx
f0100fb9:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fbc:	8b 50 04             	mov    0x4(%eax),%edx
f0100fbf:	8b 00                	mov    (%eax),%eax
f0100fc1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fc4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fc7:	eb 32                	jmp    f0100ffb <vprintfmt+0x2d1>
	else if (lflag)
f0100fc9:	85 d2                	test   %edx,%edx
f0100fcb:	74 18                	je     f0100fe5 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0100fcd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd0:	8d 50 04             	lea    0x4(%eax),%edx
f0100fd3:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fd6:	8b 00                	mov    (%eax),%eax
f0100fd8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fdb:	89 c1                	mov    %eax,%ecx
f0100fdd:	c1 f9 1f             	sar    $0x1f,%ecx
f0100fe0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fe3:	eb 16                	jmp    f0100ffb <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0100fe5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe8:	8d 50 04             	lea    0x4(%eax),%edx
f0100feb:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fee:	8b 00                	mov    (%eax),%eax
f0100ff0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ff3:	89 c1                	mov    %eax,%ecx
f0100ff5:	c1 f9 1f             	sar    $0x1f,%ecx
f0100ff8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100ffb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ffe:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101001:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101006:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010100a:	79 74                	jns    f0101080 <vprintfmt+0x356>
				putch('-', putdat);
f010100c:	83 ec 08             	sub    $0x8,%esp
f010100f:	53                   	push   %ebx
f0101010:	6a 2d                	push   $0x2d
f0101012:	ff d6                	call   *%esi
				num = -(long long) num;
f0101014:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101017:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010101a:	f7 d8                	neg    %eax
f010101c:	83 d2 00             	adc    $0x0,%edx
f010101f:	f7 da                	neg    %edx
f0101021:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101024:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101029:	eb 55                	jmp    f0101080 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010102b:	8d 45 14             	lea    0x14(%ebp),%eax
f010102e:	e8 83 fc ff ff       	call   f0100cb6 <getuint>
			base = 10;
f0101033:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101038:	eb 46                	jmp    f0101080 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010103a:	8d 45 14             	lea    0x14(%ebp),%eax
f010103d:	e8 74 fc ff ff       	call   f0100cb6 <getuint>
			base = 8;
f0101042:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101047:	eb 37                	jmp    f0101080 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0101049:	83 ec 08             	sub    $0x8,%esp
f010104c:	53                   	push   %ebx
f010104d:	6a 30                	push   $0x30
f010104f:	ff d6                	call   *%esi
			putch('x', putdat);
f0101051:	83 c4 08             	add    $0x8,%esp
f0101054:	53                   	push   %ebx
f0101055:	6a 78                	push   $0x78
f0101057:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101059:	8b 45 14             	mov    0x14(%ebp),%eax
f010105c:	8d 50 04             	lea    0x4(%eax),%edx
f010105f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101062:	8b 00                	mov    (%eax),%eax
f0101064:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101069:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010106c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101071:	eb 0d                	jmp    f0101080 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101073:	8d 45 14             	lea    0x14(%ebp),%eax
f0101076:	e8 3b fc ff ff       	call   f0100cb6 <getuint>
			base = 16;
f010107b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101080:	83 ec 0c             	sub    $0xc,%esp
f0101083:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101087:	57                   	push   %edi
f0101088:	ff 75 e0             	pushl  -0x20(%ebp)
f010108b:	51                   	push   %ecx
f010108c:	52                   	push   %edx
f010108d:	50                   	push   %eax
f010108e:	89 da                	mov    %ebx,%edx
f0101090:	89 f0                	mov    %esi,%eax
f0101092:	e8 70 fb ff ff       	call   f0100c07 <printnum>
			break;
f0101097:	83 c4 20             	add    $0x20,%esp
f010109a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010109d:	e9 ae fc ff ff       	jmp    f0100d50 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01010a2:	83 ec 08             	sub    $0x8,%esp
f01010a5:	53                   	push   %ebx
f01010a6:	51                   	push   %ecx
f01010a7:	ff d6                	call   *%esi
			break;
f01010a9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01010af:	e9 9c fc ff ff       	jmp    f0100d50 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01010b4:	83 ec 08             	sub    $0x8,%esp
f01010b7:	53                   	push   %ebx
f01010b8:	6a 25                	push   $0x25
f01010ba:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010bc:	83 c4 10             	add    $0x10,%esp
f01010bf:	eb 03                	jmp    f01010c4 <vprintfmt+0x39a>
f01010c1:	83 ef 01             	sub    $0x1,%edi
f01010c4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01010c8:	75 f7                	jne    f01010c1 <vprintfmt+0x397>
f01010ca:	e9 81 fc ff ff       	jmp    f0100d50 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01010cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010d2:	5b                   	pop    %ebx
f01010d3:	5e                   	pop    %esi
f01010d4:	5f                   	pop    %edi
f01010d5:	5d                   	pop    %ebp
f01010d6:	c3                   	ret    

f01010d7 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01010d7:	55                   	push   %ebp
f01010d8:	89 e5                	mov    %esp,%ebp
f01010da:	83 ec 18             	sub    $0x18,%esp
f01010dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01010e0:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01010e3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01010e6:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01010ea:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01010ed:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01010f4:	85 c0                	test   %eax,%eax
f01010f6:	74 26                	je     f010111e <vsnprintf+0x47>
f01010f8:	85 d2                	test   %edx,%edx
f01010fa:	7e 22                	jle    f010111e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01010fc:	ff 75 14             	pushl  0x14(%ebp)
f01010ff:	ff 75 10             	pushl  0x10(%ebp)
f0101102:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101105:	50                   	push   %eax
f0101106:	68 f0 0c 10 f0       	push   $0xf0100cf0
f010110b:	e8 1a fc ff ff       	call   f0100d2a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101110:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101113:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101116:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101119:	83 c4 10             	add    $0x10,%esp
f010111c:	eb 05                	jmp    f0101123 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010111e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101123:	c9                   	leave  
f0101124:	c3                   	ret    

f0101125 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101125:	55                   	push   %ebp
f0101126:	89 e5                	mov    %esp,%ebp
f0101128:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010112b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010112e:	50                   	push   %eax
f010112f:	ff 75 10             	pushl  0x10(%ebp)
f0101132:	ff 75 0c             	pushl  0xc(%ebp)
f0101135:	ff 75 08             	pushl  0x8(%ebp)
f0101138:	e8 9a ff ff ff       	call   f01010d7 <vsnprintf>
	va_end(ap);

	return rc;
}
f010113d:	c9                   	leave  
f010113e:	c3                   	ret    

f010113f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010113f:	55                   	push   %ebp
f0101140:	89 e5                	mov    %esp,%ebp
f0101142:	57                   	push   %edi
f0101143:	56                   	push   %esi
f0101144:	53                   	push   %ebx
f0101145:	83 ec 0c             	sub    $0xc,%esp
f0101148:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010114b:	85 c0                	test   %eax,%eax
f010114d:	74 11                	je     f0101160 <readline+0x21>
		cprintf("%s", prompt);
f010114f:	83 ec 08             	sub    $0x8,%esp
f0101152:	50                   	push   %eax
f0101153:	68 ea 1d 10 f0       	push   $0xf0101dea
f0101158:	e8 cf f7 ff ff       	call   f010092c <cprintf>
f010115d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101160:	83 ec 0c             	sub    $0xc,%esp
f0101163:	6a 00                	push   $0x0
f0101165:	e8 04 f5 ff ff       	call   f010066e <iscons>
f010116a:	89 c7                	mov    %eax,%edi
f010116c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010116f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101174:	e8 e4 f4 ff ff       	call   f010065d <getchar>
f0101179:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010117b:	85 c0                	test   %eax,%eax
f010117d:	79 18                	jns    f0101197 <readline+0x58>
			cprintf("read error: %e\n", c);
f010117f:	83 ec 08             	sub    $0x8,%esp
f0101182:	50                   	push   %eax
f0101183:	68 e0 1f 10 f0       	push   $0xf0101fe0
f0101188:	e8 9f f7 ff ff       	call   f010092c <cprintf>
			return NULL;
f010118d:	83 c4 10             	add    $0x10,%esp
f0101190:	b8 00 00 00 00       	mov    $0x0,%eax
f0101195:	eb 79                	jmp    f0101210 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101197:	83 f8 08             	cmp    $0x8,%eax
f010119a:	0f 94 c2             	sete   %dl
f010119d:	83 f8 7f             	cmp    $0x7f,%eax
f01011a0:	0f 94 c0             	sete   %al
f01011a3:	08 c2                	or     %al,%dl
f01011a5:	74 1a                	je     f01011c1 <readline+0x82>
f01011a7:	85 f6                	test   %esi,%esi
f01011a9:	7e 16                	jle    f01011c1 <readline+0x82>
			if (echoing)
f01011ab:	85 ff                	test   %edi,%edi
f01011ad:	74 0d                	je     f01011bc <readline+0x7d>
				cputchar('\b');
f01011af:	83 ec 0c             	sub    $0xc,%esp
f01011b2:	6a 08                	push   $0x8
f01011b4:	e8 94 f4 ff ff       	call   f010064d <cputchar>
f01011b9:	83 c4 10             	add    $0x10,%esp
			i--;
f01011bc:	83 ee 01             	sub    $0x1,%esi
f01011bf:	eb b3                	jmp    f0101174 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011c1:	83 fb 1f             	cmp    $0x1f,%ebx
f01011c4:	7e 23                	jle    f01011e9 <readline+0xaa>
f01011c6:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01011cc:	7f 1b                	jg     f01011e9 <readline+0xaa>
			if (echoing)
f01011ce:	85 ff                	test   %edi,%edi
f01011d0:	74 0c                	je     f01011de <readline+0x9f>
				cputchar(c);
f01011d2:	83 ec 0c             	sub    $0xc,%esp
f01011d5:	53                   	push   %ebx
f01011d6:	e8 72 f4 ff ff       	call   f010064d <cputchar>
f01011db:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01011de:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01011e4:	8d 76 01             	lea    0x1(%esi),%esi
f01011e7:	eb 8b                	jmp    f0101174 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01011e9:	83 fb 0a             	cmp    $0xa,%ebx
f01011ec:	74 05                	je     f01011f3 <readline+0xb4>
f01011ee:	83 fb 0d             	cmp    $0xd,%ebx
f01011f1:	75 81                	jne    f0101174 <readline+0x35>
			if (echoing)
f01011f3:	85 ff                	test   %edi,%edi
f01011f5:	74 0d                	je     f0101204 <readline+0xc5>
				cputchar('\n');
f01011f7:	83 ec 0c             	sub    $0xc,%esp
f01011fa:	6a 0a                	push   $0xa
f01011fc:	e8 4c f4 ff ff       	call   f010064d <cputchar>
f0101201:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101204:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010120b:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101210:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101213:	5b                   	pop    %ebx
f0101214:	5e                   	pop    %esi
f0101215:	5f                   	pop    %edi
f0101216:	5d                   	pop    %ebp
f0101217:	c3                   	ret    

f0101218 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101218:	55                   	push   %ebp
f0101219:	89 e5                	mov    %esp,%ebp
f010121b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010121e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101223:	eb 03                	jmp    f0101228 <strlen+0x10>
		n++;
f0101225:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101228:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010122c:	75 f7                	jne    f0101225 <strlen+0xd>
		n++;
	return n;
}
f010122e:	5d                   	pop    %ebp
f010122f:	c3                   	ret    

f0101230 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101230:	55                   	push   %ebp
f0101231:	89 e5                	mov    %esp,%ebp
f0101233:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101236:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101239:	ba 00 00 00 00       	mov    $0x0,%edx
f010123e:	eb 03                	jmp    f0101243 <strnlen+0x13>
		n++;
f0101240:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101243:	39 c2                	cmp    %eax,%edx
f0101245:	74 08                	je     f010124f <strnlen+0x1f>
f0101247:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010124b:	75 f3                	jne    f0101240 <strnlen+0x10>
f010124d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010124f:	5d                   	pop    %ebp
f0101250:	c3                   	ret    

f0101251 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101251:	55                   	push   %ebp
f0101252:	89 e5                	mov    %esp,%ebp
f0101254:	53                   	push   %ebx
f0101255:	8b 45 08             	mov    0x8(%ebp),%eax
f0101258:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010125b:	89 c2                	mov    %eax,%edx
f010125d:	83 c2 01             	add    $0x1,%edx
f0101260:	83 c1 01             	add    $0x1,%ecx
f0101263:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101267:	88 5a ff             	mov    %bl,-0x1(%edx)
f010126a:	84 db                	test   %bl,%bl
f010126c:	75 ef                	jne    f010125d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010126e:	5b                   	pop    %ebx
f010126f:	5d                   	pop    %ebp
f0101270:	c3                   	ret    

f0101271 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101271:	55                   	push   %ebp
f0101272:	89 e5                	mov    %esp,%ebp
f0101274:	53                   	push   %ebx
f0101275:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101278:	53                   	push   %ebx
f0101279:	e8 9a ff ff ff       	call   f0101218 <strlen>
f010127e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101281:	ff 75 0c             	pushl  0xc(%ebp)
f0101284:	01 d8                	add    %ebx,%eax
f0101286:	50                   	push   %eax
f0101287:	e8 c5 ff ff ff       	call   f0101251 <strcpy>
	return dst;
}
f010128c:	89 d8                	mov    %ebx,%eax
f010128e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101291:	c9                   	leave  
f0101292:	c3                   	ret    

f0101293 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101293:	55                   	push   %ebp
f0101294:	89 e5                	mov    %esp,%ebp
f0101296:	56                   	push   %esi
f0101297:	53                   	push   %ebx
f0101298:	8b 75 08             	mov    0x8(%ebp),%esi
f010129b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010129e:	89 f3                	mov    %esi,%ebx
f01012a0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012a3:	89 f2                	mov    %esi,%edx
f01012a5:	eb 0f                	jmp    f01012b6 <strncpy+0x23>
		*dst++ = *src;
f01012a7:	83 c2 01             	add    $0x1,%edx
f01012aa:	0f b6 01             	movzbl (%ecx),%eax
f01012ad:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012b0:	80 39 01             	cmpb   $0x1,(%ecx)
f01012b3:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012b6:	39 da                	cmp    %ebx,%edx
f01012b8:	75 ed                	jne    f01012a7 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01012ba:	89 f0                	mov    %esi,%eax
f01012bc:	5b                   	pop    %ebx
f01012bd:	5e                   	pop    %esi
f01012be:	5d                   	pop    %ebp
f01012bf:	c3                   	ret    

f01012c0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012c0:	55                   	push   %ebp
f01012c1:	89 e5                	mov    %esp,%ebp
f01012c3:	56                   	push   %esi
f01012c4:	53                   	push   %ebx
f01012c5:	8b 75 08             	mov    0x8(%ebp),%esi
f01012c8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012cb:	8b 55 10             	mov    0x10(%ebp),%edx
f01012ce:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01012d0:	85 d2                	test   %edx,%edx
f01012d2:	74 21                	je     f01012f5 <strlcpy+0x35>
f01012d4:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01012d8:	89 f2                	mov    %esi,%edx
f01012da:	eb 09                	jmp    f01012e5 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01012dc:	83 c2 01             	add    $0x1,%edx
f01012df:	83 c1 01             	add    $0x1,%ecx
f01012e2:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01012e5:	39 c2                	cmp    %eax,%edx
f01012e7:	74 09                	je     f01012f2 <strlcpy+0x32>
f01012e9:	0f b6 19             	movzbl (%ecx),%ebx
f01012ec:	84 db                	test   %bl,%bl
f01012ee:	75 ec                	jne    f01012dc <strlcpy+0x1c>
f01012f0:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01012f2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01012f5:	29 f0                	sub    %esi,%eax
}
f01012f7:	5b                   	pop    %ebx
f01012f8:	5e                   	pop    %esi
f01012f9:	5d                   	pop    %ebp
f01012fa:	c3                   	ret    

f01012fb <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01012fb:	55                   	push   %ebp
f01012fc:	89 e5                	mov    %esp,%ebp
f01012fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101301:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101304:	eb 06                	jmp    f010130c <strcmp+0x11>
		p++, q++;
f0101306:	83 c1 01             	add    $0x1,%ecx
f0101309:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010130c:	0f b6 01             	movzbl (%ecx),%eax
f010130f:	84 c0                	test   %al,%al
f0101311:	74 04                	je     f0101317 <strcmp+0x1c>
f0101313:	3a 02                	cmp    (%edx),%al
f0101315:	74 ef                	je     f0101306 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101317:	0f b6 c0             	movzbl %al,%eax
f010131a:	0f b6 12             	movzbl (%edx),%edx
f010131d:	29 d0                	sub    %edx,%eax
}
f010131f:	5d                   	pop    %ebp
f0101320:	c3                   	ret    

f0101321 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101321:	55                   	push   %ebp
f0101322:	89 e5                	mov    %esp,%ebp
f0101324:	53                   	push   %ebx
f0101325:	8b 45 08             	mov    0x8(%ebp),%eax
f0101328:	8b 55 0c             	mov    0xc(%ebp),%edx
f010132b:	89 c3                	mov    %eax,%ebx
f010132d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101330:	eb 06                	jmp    f0101338 <strncmp+0x17>
		n--, p++, q++;
f0101332:	83 c0 01             	add    $0x1,%eax
f0101335:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101338:	39 d8                	cmp    %ebx,%eax
f010133a:	74 15                	je     f0101351 <strncmp+0x30>
f010133c:	0f b6 08             	movzbl (%eax),%ecx
f010133f:	84 c9                	test   %cl,%cl
f0101341:	74 04                	je     f0101347 <strncmp+0x26>
f0101343:	3a 0a                	cmp    (%edx),%cl
f0101345:	74 eb                	je     f0101332 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101347:	0f b6 00             	movzbl (%eax),%eax
f010134a:	0f b6 12             	movzbl (%edx),%edx
f010134d:	29 d0                	sub    %edx,%eax
f010134f:	eb 05                	jmp    f0101356 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101351:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101356:	5b                   	pop    %ebx
f0101357:	5d                   	pop    %ebp
f0101358:	c3                   	ret    

f0101359 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101359:	55                   	push   %ebp
f010135a:	89 e5                	mov    %esp,%ebp
f010135c:	8b 45 08             	mov    0x8(%ebp),%eax
f010135f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101363:	eb 07                	jmp    f010136c <strchr+0x13>
		if (*s == c)
f0101365:	38 ca                	cmp    %cl,%dl
f0101367:	74 0f                	je     f0101378 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101369:	83 c0 01             	add    $0x1,%eax
f010136c:	0f b6 10             	movzbl (%eax),%edx
f010136f:	84 d2                	test   %dl,%dl
f0101371:	75 f2                	jne    f0101365 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101373:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101378:	5d                   	pop    %ebp
f0101379:	c3                   	ret    

f010137a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010137a:	55                   	push   %ebp
f010137b:	89 e5                	mov    %esp,%ebp
f010137d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101380:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101384:	eb 03                	jmp    f0101389 <strfind+0xf>
f0101386:	83 c0 01             	add    $0x1,%eax
f0101389:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010138c:	38 ca                	cmp    %cl,%dl
f010138e:	74 04                	je     f0101394 <strfind+0x1a>
f0101390:	84 d2                	test   %dl,%dl
f0101392:	75 f2                	jne    f0101386 <strfind+0xc>
			break;
	return (char *) s;
}
f0101394:	5d                   	pop    %ebp
f0101395:	c3                   	ret    

f0101396 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101396:	55                   	push   %ebp
f0101397:	89 e5                	mov    %esp,%ebp
f0101399:	57                   	push   %edi
f010139a:	56                   	push   %esi
f010139b:	53                   	push   %ebx
f010139c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010139f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013a2:	85 c9                	test   %ecx,%ecx
f01013a4:	74 36                	je     f01013dc <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013a6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013ac:	75 28                	jne    f01013d6 <memset+0x40>
f01013ae:	f6 c1 03             	test   $0x3,%cl
f01013b1:	75 23                	jne    f01013d6 <memset+0x40>
		c &= 0xFF;
f01013b3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013b7:	89 d3                	mov    %edx,%ebx
f01013b9:	c1 e3 08             	shl    $0x8,%ebx
f01013bc:	89 d6                	mov    %edx,%esi
f01013be:	c1 e6 18             	shl    $0x18,%esi
f01013c1:	89 d0                	mov    %edx,%eax
f01013c3:	c1 e0 10             	shl    $0x10,%eax
f01013c6:	09 f0                	or     %esi,%eax
f01013c8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01013ca:	89 d8                	mov    %ebx,%eax
f01013cc:	09 d0                	or     %edx,%eax
f01013ce:	c1 e9 02             	shr    $0x2,%ecx
f01013d1:	fc                   	cld    
f01013d2:	f3 ab                	rep stos %eax,%es:(%edi)
f01013d4:	eb 06                	jmp    f01013dc <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01013d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013d9:	fc                   	cld    
f01013da:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01013dc:	89 f8                	mov    %edi,%eax
f01013de:	5b                   	pop    %ebx
f01013df:	5e                   	pop    %esi
f01013e0:	5f                   	pop    %edi
f01013e1:	5d                   	pop    %ebp
f01013e2:	c3                   	ret    

f01013e3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01013e3:	55                   	push   %ebp
f01013e4:	89 e5                	mov    %esp,%ebp
f01013e6:	57                   	push   %edi
f01013e7:	56                   	push   %esi
f01013e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013eb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01013ee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01013f1:	39 c6                	cmp    %eax,%esi
f01013f3:	73 35                	jae    f010142a <memmove+0x47>
f01013f5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01013f8:	39 d0                	cmp    %edx,%eax
f01013fa:	73 2e                	jae    f010142a <memmove+0x47>
		s += n;
		d += n;
f01013fc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01013ff:	89 d6                	mov    %edx,%esi
f0101401:	09 fe                	or     %edi,%esi
f0101403:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101409:	75 13                	jne    f010141e <memmove+0x3b>
f010140b:	f6 c1 03             	test   $0x3,%cl
f010140e:	75 0e                	jne    f010141e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101410:	83 ef 04             	sub    $0x4,%edi
f0101413:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101416:	c1 e9 02             	shr    $0x2,%ecx
f0101419:	fd                   	std    
f010141a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010141c:	eb 09                	jmp    f0101427 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010141e:	83 ef 01             	sub    $0x1,%edi
f0101421:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101424:	fd                   	std    
f0101425:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101427:	fc                   	cld    
f0101428:	eb 1d                	jmp    f0101447 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010142a:	89 f2                	mov    %esi,%edx
f010142c:	09 c2                	or     %eax,%edx
f010142e:	f6 c2 03             	test   $0x3,%dl
f0101431:	75 0f                	jne    f0101442 <memmove+0x5f>
f0101433:	f6 c1 03             	test   $0x3,%cl
f0101436:	75 0a                	jne    f0101442 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101438:	c1 e9 02             	shr    $0x2,%ecx
f010143b:	89 c7                	mov    %eax,%edi
f010143d:	fc                   	cld    
f010143e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101440:	eb 05                	jmp    f0101447 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101442:	89 c7                	mov    %eax,%edi
f0101444:	fc                   	cld    
f0101445:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101447:	5e                   	pop    %esi
f0101448:	5f                   	pop    %edi
f0101449:	5d                   	pop    %ebp
f010144a:	c3                   	ret    

f010144b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010144b:	55                   	push   %ebp
f010144c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010144e:	ff 75 10             	pushl  0x10(%ebp)
f0101451:	ff 75 0c             	pushl  0xc(%ebp)
f0101454:	ff 75 08             	pushl  0x8(%ebp)
f0101457:	e8 87 ff ff ff       	call   f01013e3 <memmove>
}
f010145c:	c9                   	leave  
f010145d:	c3                   	ret    

f010145e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010145e:	55                   	push   %ebp
f010145f:	89 e5                	mov    %esp,%ebp
f0101461:	56                   	push   %esi
f0101462:	53                   	push   %ebx
f0101463:	8b 45 08             	mov    0x8(%ebp),%eax
f0101466:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101469:	89 c6                	mov    %eax,%esi
f010146b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010146e:	eb 1a                	jmp    f010148a <memcmp+0x2c>
		if (*s1 != *s2)
f0101470:	0f b6 08             	movzbl (%eax),%ecx
f0101473:	0f b6 1a             	movzbl (%edx),%ebx
f0101476:	38 d9                	cmp    %bl,%cl
f0101478:	74 0a                	je     f0101484 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010147a:	0f b6 c1             	movzbl %cl,%eax
f010147d:	0f b6 db             	movzbl %bl,%ebx
f0101480:	29 d8                	sub    %ebx,%eax
f0101482:	eb 0f                	jmp    f0101493 <memcmp+0x35>
		s1++, s2++;
f0101484:	83 c0 01             	add    $0x1,%eax
f0101487:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010148a:	39 f0                	cmp    %esi,%eax
f010148c:	75 e2                	jne    f0101470 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010148e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101493:	5b                   	pop    %ebx
f0101494:	5e                   	pop    %esi
f0101495:	5d                   	pop    %ebp
f0101496:	c3                   	ret    

f0101497 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101497:	55                   	push   %ebp
f0101498:	89 e5                	mov    %esp,%ebp
f010149a:	53                   	push   %ebx
f010149b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010149e:	89 c1                	mov    %eax,%ecx
f01014a0:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01014a3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014a7:	eb 0a                	jmp    f01014b3 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014a9:	0f b6 10             	movzbl (%eax),%edx
f01014ac:	39 da                	cmp    %ebx,%edx
f01014ae:	74 07                	je     f01014b7 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014b0:	83 c0 01             	add    $0x1,%eax
f01014b3:	39 c8                	cmp    %ecx,%eax
f01014b5:	72 f2                	jb     f01014a9 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01014b7:	5b                   	pop    %ebx
f01014b8:	5d                   	pop    %ebp
f01014b9:	c3                   	ret    

f01014ba <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01014ba:	55                   	push   %ebp
f01014bb:	89 e5                	mov    %esp,%ebp
f01014bd:	57                   	push   %edi
f01014be:	56                   	push   %esi
f01014bf:	53                   	push   %ebx
f01014c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014c3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014c6:	eb 03                	jmp    f01014cb <strtol+0x11>
		s++;
f01014c8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014cb:	0f b6 01             	movzbl (%ecx),%eax
f01014ce:	3c 20                	cmp    $0x20,%al
f01014d0:	74 f6                	je     f01014c8 <strtol+0xe>
f01014d2:	3c 09                	cmp    $0x9,%al
f01014d4:	74 f2                	je     f01014c8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01014d6:	3c 2b                	cmp    $0x2b,%al
f01014d8:	75 0a                	jne    f01014e4 <strtol+0x2a>
		s++;
f01014da:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01014dd:	bf 00 00 00 00       	mov    $0x0,%edi
f01014e2:	eb 11                	jmp    f01014f5 <strtol+0x3b>
f01014e4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01014e9:	3c 2d                	cmp    $0x2d,%al
f01014eb:	75 08                	jne    f01014f5 <strtol+0x3b>
		s++, neg = 1;
f01014ed:	83 c1 01             	add    $0x1,%ecx
f01014f0:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01014f5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01014fb:	75 15                	jne    f0101512 <strtol+0x58>
f01014fd:	80 39 30             	cmpb   $0x30,(%ecx)
f0101500:	75 10                	jne    f0101512 <strtol+0x58>
f0101502:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101506:	75 7c                	jne    f0101584 <strtol+0xca>
		s += 2, base = 16;
f0101508:	83 c1 02             	add    $0x2,%ecx
f010150b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101510:	eb 16                	jmp    f0101528 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101512:	85 db                	test   %ebx,%ebx
f0101514:	75 12                	jne    f0101528 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101516:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010151b:	80 39 30             	cmpb   $0x30,(%ecx)
f010151e:	75 08                	jne    f0101528 <strtol+0x6e>
		s++, base = 8;
f0101520:	83 c1 01             	add    $0x1,%ecx
f0101523:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101528:	b8 00 00 00 00       	mov    $0x0,%eax
f010152d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101530:	0f b6 11             	movzbl (%ecx),%edx
f0101533:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101536:	89 f3                	mov    %esi,%ebx
f0101538:	80 fb 09             	cmp    $0x9,%bl
f010153b:	77 08                	ja     f0101545 <strtol+0x8b>
			dig = *s - '0';
f010153d:	0f be d2             	movsbl %dl,%edx
f0101540:	83 ea 30             	sub    $0x30,%edx
f0101543:	eb 22                	jmp    f0101567 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101545:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101548:	89 f3                	mov    %esi,%ebx
f010154a:	80 fb 19             	cmp    $0x19,%bl
f010154d:	77 08                	ja     f0101557 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010154f:	0f be d2             	movsbl %dl,%edx
f0101552:	83 ea 57             	sub    $0x57,%edx
f0101555:	eb 10                	jmp    f0101567 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101557:	8d 72 bf             	lea    -0x41(%edx),%esi
f010155a:	89 f3                	mov    %esi,%ebx
f010155c:	80 fb 19             	cmp    $0x19,%bl
f010155f:	77 16                	ja     f0101577 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101561:	0f be d2             	movsbl %dl,%edx
f0101564:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101567:	3b 55 10             	cmp    0x10(%ebp),%edx
f010156a:	7d 0b                	jge    f0101577 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010156c:	83 c1 01             	add    $0x1,%ecx
f010156f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101573:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101575:	eb b9                	jmp    f0101530 <strtol+0x76>

	if (endptr)
f0101577:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010157b:	74 0d                	je     f010158a <strtol+0xd0>
		*endptr = (char *) s;
f010157d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101580:	89 0e                	mov    %ecx,(%esi)
f0101582:	eb 06                	jmp    f010158a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101584:	85 db                	test   %ebx,%ebx
f0101586:	74 98                	je     f0101520 <strtol+0x66>
f0101588:	eb 9e                	jmp    f0101528 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010158a:	89 c2                	mov    %eax,%edx
f010158c:	f7 da                	neg    %edx
f010158e:	85 ff                	test   %edi,%edi
f0101590:	0f 45 c2             	cmovne %edx,%eax
}
f0101593:	5b                   	pop    %ebx
f0101594:	5e                   	pop    %esi
f0101595:	5f                   	pop    %edi
f0101596:	5d                   	pop    %ebp
f0101597:	c3                   	ret    
f0101598:	66 90                	xchg   %ax,%ax
f010159a:	66 90                	xchg   %ax,%ax
f010159c:	66 90                	xchg   %ax,%ax
f010159e:	66 90                	xchg   %ax,%ax

f01015a0 <__udivdi3>:
f01015a0:	55                   	push   %ebp
f01015a1:	57                   	push   %edi
f01015a2:	56                   	push   %esi
f01015a3:	53                   	push   %ebx
f01015a4:	83 ec 1c             	sub    $0x1c,%esp
f01015a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01015ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01015af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01015b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01015b7:	85 f6                	test   %esi,%esi
f01015b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01015bd:	89 ca                	mov    %ecx,%edx
f01015bf:	89 f8                	mov    %edi,%eax
f01015c1:	75 3d                	jne    f0101600 <__udivdi3+0x60>
f01015c3:	39 cf                	cmp    %ecx,%edi
f01015c5:	0f 87 c5 00 00 00    	ja     f0101690 <__udivdi3+0xf0>
f01015cb:	85 ff                	test   %edi,%edi
f01015cd:	89 fd                	mov    %edi,%ebp
f01015cf:	75 0b                	jne    f01015dc <__udivdi3+0x3c>
f01015d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01015d6:	31 d2                	xor    %edx,%edx
f01015d8:	f7 f7                	div    %edi
f01015da:	89 c5                	mov    %eax,%ebp
f01015dc:	89 c8                	mov    %ecx,%eax
f01015de:	31 d2                	xor    %edx,%edx
f01015e0:	f7 f5                	div    %ebp
f01015e2:	89 c1                	mov    %eax,%ecx
f01015e4:	89 d8                	mov    %ebx,%eax
f01015e6:	89 cf                	mov    %ecx,%edi
f01015e8:	f7 f5                	div    %ebp
f01015ea:	89 c3                	mov    %eax,%ebx
f01015ec:	89 d8                	mov    %ebx,%eax
f01015ee:	89 fa                	mov    %edi,%edx
f01015f0:	83 c4 1c             	add    $0x1c,%esp
f01015f3:	5b                   	pop    %ebx
f01015f4:	5e                   	pop    %esi
f01015f5:	5f                   	pop    %edi
f01015f6:	5d                   	pop    %ebp
f01015f7:	c3                   	ret    
f01015f8:	90                   	nop
f01015f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101600:	39 ce                	cmp    %ecx,%esi
f0101602:	77 74                	ja     f0101678 <__udivdi3+0xd8>
f0101604:	0f bd fe             	bsr    %esi,%edi
f0101607:	83 f7 1f             	xor    $0x1f,%edi
f010160a:	0f 84 98 00 00 00    	je     f01016a8 <__udivdi3+0x108>
f0101610:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101615:	89 f9                	mov    %edi,%ecx
f0101617:	89 c5                	mov    %eax,%ebp
f0101619:	29 fb                	sub    %edi,%ebx
f010161b:	d3 e6                	shl    %cl,%esi
f010161d:	89 d9                	mov    %ebx,%ecx
f010161f:	d3 ed                	shr    %cl,%ebp
f0101621:	89 f9                	mov    %edi,%ecx
f0101623:	d3 e0                	shl    %cl,%eax
f0101625:	09 ee                	or     %ebp,%esi
f0101627:	89 d9                	mov    %ebx,%ecx
f0101629:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010162d:	89 d5                	mov    %edx,%ebp
f010162f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101633:	d3 ed                	shr    %cl,%ebp
f0101635:	89 f9                	mov    %edi,%ecx
f0101637:	d3 e2                	shl    %cl,%edx
f0101639:	89 d9                	mov    %ebx,%ecx
f010163b:	d3 e8                	shr    %cl,%eax
f010163d:	09 c2                	or     %eax,%edx
f010163f:	89 d0                	mov    %edx,%eax
f0101641:	89 ea                	mov    %ebp,%edx
f0101643:	f7 f6                	div    %esi
f0101645:	89 d5                	mov    %edx,%ebp
f0101647:	89 c3                	mov    %eax,%ebx
f0101649:	f7 64 24 0c          	mull   0xc(%esp)
f010164d:	39 d5                	cmp    %edx,%ebp
f010164f:	72 10                	jb     f0101661 <__udivdi3+0xc1>
f0101651:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101655:	89 f9                	mov    %edi,%ecx
f0101657:	d3 e6                	shl    %cl,%esi
f0101659:	39 c6                	cmp    %eax,%esi
f010165b:	73 07                	jae    f0101664 <__udivdi3+0xc4>
f010165d:	39 d5                	cmp    %edx,%ebp
f010165f:	75 03                	jne    f0101664 <__udivdi3+0xc4>
f0101661:	83 eb 01             	sub    $0x1,%ebx
f0101664:	31 ff                	xor    %edi,%edi
f0101666:	89 d8                	mov    %ebx,%eax
f0101668:	89 fa                	mov    %edi,%edx
f010166a:	83 c4 1c             	add    $0x1c,%esp
f010166d:	5b                   	pop    %ebx
f010166e:	5e                   	pop    %esi
f010166f:	5f                   	pop    %edi
f0101670:	5d                   	pop    %ebp
f0101671:	c3                   	ret    
f0101672:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101678:	31 ff                	xor    %edi,%edi
f010167a:	31 db                	xor    %ebx,%ebx
f010167c:	89 d8                	mov    %ebx,%eax
f010167e:	89 fa                	mov    %edi,%edx
f0101680:	83 c4 1c             	add    $0x1c,%esp
f0101683:	5b                   	pop    %ebx
f0101684:	5e                   	pop    %esi
f0101685:	5f                   	pop    %edi
f0101686:	5d                   	pop    %ebp
f0101687:	c3                   	ret    
f0101688:	90                   	nop
f0101689:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101690:	89 d8                	mov    %ebx,%eax
f0101692:	f7 f7                	div    %edi
f0101694:	31 ff                	xor    %edi,%edi
f0101696:	89 c3                	mov    %eax,%ebx
f0101698:	89 d8                	mov    %ebx,%eax
f010169a:	89 fa                	mov    %edi,%edx
f010169c:	83 c4 1c             	add    $0x1c,%esp
f010169f:	5b                   	pop    %ebx
f01016a0:	5e                   	pop    %esi
f01016a1:	5f                   	pop    %edi
f01016a2:	5d                   	pop    %ebp
f01016a3:	c3                   	ret    
f01016a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016a8:	39 ce                	cmp    %ecx,%esi
f01016aa:	72 0c                	jb     f01016b8 <__udivdi3+0x118>
f01016ac:	31 db                	xor    %ebx,%ebx
f01016ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01016b2:	0f 87 34 ff ff ff    	ja     f01015ec <__udivdi3+0x4c>
f01016b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01016bd:	e9 2a ff ff ff       	jmp    f01015ec <__udivdi3+0x4c>
f01016c2:	66 90                	xchg   %ax,%ax
f01016c4:	66 90                	xchg   %ax,%ax
f01016c6:	66 90                	xchg   %ax,%ax
f01016c8:	66 90                	xchg   %ax,%ax
f01016ca:	66 90                	xchg   %ax,%ax
f01016cc:	66 90                	xchg   %ax,%ax
f01016ce:	66 90                	xchg   %ax,%ax

f01016d0 <__umoddi3>:
f01016d0:	55                   	push   %ebp
f01016d1:	57                   	push   %edi
f01016d2:	56                   	push   %esi
f01016d3:	53                   	push   %ebx
f01016d4:	83 ec 1c             	sub    $0x1c,%esp
f01016d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01016db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01016df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01016e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016e7:	85 d2                	test   %edx,%edx
f01016e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01016ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01016f1:	89 f3                	mov    %esi,%ebx
f01016f3:	89 3c 24             	mov    %edi,(%esp)
f01016f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01016fa:	75 1c                	jne    f0101718 <__umoddi3+0x48>
f01016fc:	39 f7                	cmp    %esi,%edi
f01016fe:	76 50                	jbe    f0101750 <__umoddi3+0x80>
f0101700:	89 c8                	mov    %ecx,%eax
f0101702:	89 f2                	mov    %esi,%edx
f0101704:	f7 f7                	div    %edi
f0101706:	89 d0                	mov    %edx,%eax
f0101708:	31 d2                	xor    %edx,%edx
f010170a:	83 c4 1c             	add    $0x1c,%esp
f010170d:	5b                   	pop    %ebx
f010170e:	5e                   	pop    %esi
f010170f:	5f                   	pop    %edi
f0101710:	5d                   	pop    %ebp
f0101711:	c3                   	ret    
f0101712:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101718:	39 f2                	cmp    %esi,%edx
f010171a:	89 d0                	mov    %edx,%eax
f010171c:	77 52                	ja     f0101770 <__umoddi3+0xa0>
f010171e:	0f bd ea             	bsr    %edx,%ebp
f0101721:	83 f5 1f             	xor    $0x1f,%ebp
f0101724:	75 5a                	jne    f0101780 <__umoddi3+0xb0>
f0101726:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010172a:	0f 82 e0 00 00 00    	jb     f0101810 <__umoddi3+0x140>
f0101730:	39 0c 24             	cmp    %ecx,(%esp)
f0101733:	0f 86 d7 00 00 00    	jbe    f0101810 <__umoddi3+0x140>
f0101739:	8b 44 24 08          	mov    0x8(%esp),%eax
f010173d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101741:	83 c4 1c             	add    $0x1c,%esp
f0101744:	5b                   	pop    %ebx
f0101745:	5e                   	pop    %esi
f0101746:	5f                   	pop    %edi
f0101747:	5d                   	pop    %ebp
f0101748:	c3                   	ret    
f0101749:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101750:	85 ff                	test   %edi,%edi
f0101752:	89 fd                	mov    %edi,%ebp
f0101754:	75 0b                	jne    f0101761 <__umoddi3+0x91>
f0101756:	b8 01 00 00 00       	mov    $0x1,%eax
f010175b:	31 d2                	xor    %edx,%edx
f010175d:	f7 f7                	div    %edi
f010175f:	89 c5                	mov    %eax,%ebp
f0101761:	89 f0                	mov    %esi,%eax
f0101763:	31 d2                	xor    %edx,%edx
f0101765:	f7 f5                	div    %ebp
f0101767:	89 c8                	mov    %ecx,%eax
f0101769:	f7 f5                	div    %ebp
f010176b:	89 d0                	mov    %edx,%eax
f010176d:	eb 99                	jmp    f0101708 <__umoddi3+0x38>
f010176f:	90                   	nop
f0101770:	89 c8                	mov    %ecx,%eax
f0101772:	89 f2                	mov    %esi,%edx
f0101774:	83 c4 1c             	add    $0x1c,%esp
f0101777:	5b                   	pop    %ebx
f0101778:	5e                   	pop    %esi
f0101779:	5f                   	pop    %edi
f010177a:	5d                   	pop    %ebp
f010177b:	c3                   	ret    
f010177c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101780:	8b 34 24             	mov    (%esp),%esi
f0101783:	bf 20 00 00 00       	mov    $0x20,%edi
f0101788:	89 e9                	mov    %ebp,%ecx
f010178a:	29 ef                	sub    %ebp,%edi
f010178c:	d3 e0                	shl    %cl,%eax
f010178e:	89 f9                	mov    %edi,%ecx
f0101790:	89 f2                	mov    %esi,%edx
f0101792:	d3 ea                	shr    %cl,%edx
f0101794:	89 e9                	mov    %ebp,%ecx
f0101796:	09 c2                	or     %eax,%edx
f0101798:	89 d8                	mov    %ebx,%eax
f010179a:	89 14 24             	mov    %edx,(%esp)
f010179d:	89 f2                	mov    %esi,%edx
f010179f:	d3 e2                	shl    %cl,%edx
f01017a1:	89 f9                	mov    %edi,%ecx
f01017a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01017a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01017ab:	d3 e8                	shr    %cl,%eax
f01017ad:	89 e9                	mov    %ebp,%ecx
f01017af:	89 c6                	mov    %eax,%esi
f01017b1:	d3 e3                	shl    %cl,%ebx
f01017b3:	89 f9                	mov    %edi,%ecx
f01017b5:	89 d0                	mov    %edx,%eax
f01017b7:	d3 e8                	shr    %cl,%eax
f01017b9:	89 e9                	mov    %ebp,%ecx
f01017bb:	09 d8                	or     %ebx,%eax
f01017bd:	89 d3                	mov    %edx,%ebx
f01017bf:	89 f2                	mov    %esi,%edx
f01017c1:	f7 34 24             	divl   (%esp)
f01017c4:	89 d6                	mov    %edx,%esi
f01017c6:	d3 e3                	shl    %cl,%ebx
f01017c8:	f7 64 24 04          	mull   0x4(%esp)
f01017cc:	39 d6                	cmp    %edx,%esi
f01017ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01017d2:	89 d1                	mov    %edx,%ecx
f01017d4:	89 c3                	mov    %eax,%ebx
f01017d6:	72 08                	jb     f01017e0 <__umoddi3+0x110>
f01017d8:	75 11                	jne    f01017eb <__umoddi3+0x11b>
f01017da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01017de:	73 0b                	jae    f01017eb <__umoddi3+0x11b>
f01017e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01017e4:	1b 14 24             	sbb    (%esp),%edx
f01017e7:	89 d1                	mov    %edx,%ecx
f01017e9:	89 c3                	mov    %eax,%ebx
f01017eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01017ef:	29 da                	sub    %ebx,%edx
f01017f1:	19 ce                	sbb    %ecx,%esi
f01017f3:	89 f9                	mov    %edi,%ecx
f01017f5:	89 f0                	mov    %esi,%eax
f01017f7:	d3 e0                	shl    %cl,%eax
f01017f9:	89 e9                	mov    %ebp,%ecx
f01017fb:	d3 ea                	shr    %cl,%edx
f01017fd:	89 e9                	mov    %ebp,%ecx
f01017ff:	d3 ee                	shr    %cl,%esi
f0101801:	09 d0                	or     %edx,%eax
f0101803:	89 f2                	mov    %esi,%edx
f0101805:	83 c4 1c             	add    $0x1c,%esp
f0101808:	5b                   	pop    %ebx
f0101809:	5e                   	pop    %esi
f010180a:	5f                   	pop    %edi
f010180b:	5d                   	pop    %ebp
f010180c:	c3                   	ret    
f010180d:	8d 76 00             	lea    0x0(%esi),%esi
f0101810:	29 f9                	sub    %edi,%ecx
f0101812:	19 d6                	sbb    %edx,%esi
f0101814:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101818:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010181c:	e9 18 ff ff ff       	jmp    f0101739 <__umoddi3+0x69>
