
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:



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
f0100046:	b8 10 cb 17 f0       	mov    $0xf017cb10,%eax
f010004b:	2d ee bb 17 f0       	sub    $0xf017bbee,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ee bb 17 f0       	push   $0xf017bbee
f0100058:	e8 d8 41 00 00       	call   f0104235 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 46 10 f0       	push   $0xf01046e0
f010006f:	e8 59 2e 00 00       	call   f0102ecd <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 2a 0f 00 00       	call   f0100fa3 <mem_init>


	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 8f 28 00 00       	call   f010290d <env_init>
	trap_init();
f010007e:	e8 bb 2e 00 00       	call   f0102f3e <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 7e 0b 13 f0       	push   $0xf0130b7e
f010008d:	e8 46 2a 00 00       	call   f0102ad8 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 4c be 17 f0    	pushl  0xf017be4c
f010009b:	e8 64 2d 00 00       	call   f0102e04 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 00 cb 17 f0 00 	cmpl   $0x0,0xf017cb00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 cb 17 f0    	mov    %esi,0xf017cb00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 fb 46 10 f0       	push   $0xf01046fb
f01000ca:	e8 fe 2d 00 00       	call   f0102ecd <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 ce 2d 00 00       	call   f0102ea7 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 61 4e 10 f0 	movl   $0xf0104e61,(%esp)
f01000e0:	e8 e8 2d 00 00       	call   f0102ecd <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 32 06 00 00       	call   f0100724 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 13 47 10 f0       	push   $0xf0104713
f010010c:	e8 bc 2d 00 00       	call   f0102ecd <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 8a 2d 00 00       	call   f0102ea7 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 61 4e 10 f0 	movl   $0xf0104e61,(%esp)
f0100124:	e8 a4 2d 00 00       	call   f0102ecd <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 24 be 17 f0    	mov    0xf017be24,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 be 17 f0    	mov    %edx,0xf017be24
f010016e:	88 81 20 bc 17 f0    	mov    %al,-0xfe843e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 be 17 f0 00 	movl   $0x0,0xf017be24
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 00 bc 17 f0 40 	orl    $0x40,0xf017bc00
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 80 48 10 f0 	movzbl -0xfefb780(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 00 bc 17 f0    	mov    %ecx,0xf017bc00
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 80 48 10 f0 	movzbl -0xfefb780(%edx),%eax
f010021e:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f0100224:	0f b6 8a 80 47 10 f0 	movzbl -0xfefb880(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d 60 47 10 f0 	mov    -0xfefb8a0(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 2d 47 10 f0       	push   $0xf010472d
f010027a:	e8 4e 2c 00 00       	call   f0102ecd <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 28 be 17 f0 	addw   $0x50,0xf017be28
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 28 be 17 f0 	mov    %dx,0xf017be28
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 28 be 17 f0 	cmpw   $0x7cf,0xf017be28
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 2c be 17 f0       	mov    0xf017be2c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 5a 3e 00 00       	call   f0104282 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 be 17 f0 	subw   $0x50,0xf017be28
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 be 17 f0    	mov    0xf017be30,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 be 17 f0 	movzwl 0xf017be28,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 34 be 17 f0 00 	cmpb   $0x0,0xf017be34
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 20 be 17 f0       	mov    0xf017be20,%eax
f01004ca:	3b 05 24 be 17 f0    	cmp    0xf017be24,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 be 17 f0    	mov    %edx,0xf017be20
f01004db:	0f b6 88 20 bc 17 f0 	movzbl -0xfe843e0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 20 be 17 f0 00 	movl   $0x0,0xf017be20
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 30 be 17 f0 b4 	movl   $0x3b4,0xf017be30
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 30 be 17 f0 d4 	movl   $0x3d4,0xf017be30
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 30 be 17 f0    	mov    0xf017be30,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 2c be 17 f0    	mov    %esi,0xf017be2c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 34 be 17 f0 	setne  0xf017be34
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 39 47 10 f0       	push   $0xf0104739
f01005f7:	e8 d1 28 00 00       	call   f0102ecd <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100638:	68 80 49 10 f0       	push   $0xf0104980
f010063d:	68 9e 49 10 f0       	push   $0xf010499e
f0100642:	68 a3 49 10 f0       	push   $0xf01049a3
f0100647:	e8 81 28 00 00       	call   f0102ecd <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 0c 4a 10 f0       	push   $0xf0104a0c
f0100654:	68 ac 49 10 f0       	push   $0xf01049ac
f0100659:	68 a3 49 10 f0       	push   $0xf01049a3
f010065e:	e8 6a 28 00 00       	call   f0102ecd <cprintf>
	return 0;
}
f0100663:	b8 00 00 00 00       	mov    $0x0,%eax
f0100668:	c9                   	leave  
f0100669:	c3                   	ret    

f010066a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066a:	55                   	push   %ebp
f010066b:	89 e5                	mov    %esp,%ebp
f010066d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100670:	68 b5 49 10 f0       	push   $0xf01049b5
f0100675:	e8 53 28 00 00       	call   f0102ecd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067a:	83 c4 08             	add    $0x8,%esp
f010067d:	68 0c 00 10 00       	push   $0x10000c
f0100682:	68 34 4a 10 f0       	push   $0xf0104a34
f0100687:	e8 41 28 00 00       	call   f0102ecd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068c:	83 c4 0c             	add    $0xc,%esp
f010068f:	68 0c 00 10 00       	push   $0x10000c
f0100694:	68 0c 00 10 f0       	push   $0xf010000c
f0100699:	68 5c 4a 10 f0       	push   $0xf0104a5c
f010069e:	e8 2a 28 00 00       	call   f0102ecd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 c1 46 10 00       	push   $0x1046c1
f01006ab:	68 c1 46 10 f0       	push   $0xf01046c1
f01006b0:	68 80 4a 10 f0       	push   $0xf0104a80
f01006b5:	e8 13 28 00 00       	call   f0102ecd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 ee bb 17 00       	push   $0x17bbee
f01006c2:	68 ee bb 17 f0       	push   $0xf017bbee
f01006c7:	68 a4 4a 10 f0       	push   $0xf0104aa4
f01006cc:	e8 fc 27 00 00       	call   f0102ecd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 10 cb 17 00       	push   $0x17cb10
f01006d9:	68 10 cb 17 f0       	push   $0xf017cb10
f01006de:	68 c8 4a 10 f0       	push   $0xf0104ac8
f01006e3:	e8 e5 27 00 00       	call   f0102ecd <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e8:	b8 0f cf 17 f0       	mov    $0xf017cf0f,%eax
f01006ed:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f2:	83 c4 08             	add    $0x8,%esp
f01006f5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006fa:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100700:	85 c0                	test   %eax,%eax
f0100702:	0f 48 c2             	cmovs  %edx,%eax
f0100705:	c1 f8 0a             	sar    $0xa,%eax
f0100708:	50                   	push   %eax
f0100709:	68 ec 4a 10 f0       	push   $0xf0104aec
f010070e:	e8 ba 27 00 00       	call   f0102ecd <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100713:	b8 00 00 00 00       	mov    $0x0,%eax
f0100718:	c9                   	leave  
f0100719:	c3                   	ret    

f010071a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071a:	55                   	push   %ebp
f010071b:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010071d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100722:	5d                   	pop    %ebp
f0100723:	c3                   	ret    

f0100724 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100724:	55                   	push   %ebp
f0100725:	89 e5                	mov    %esp,%ebp
f0100727:	57                   	push   %edi
f0100728:	56                   	push   %esi
f0100729:	53                   	push   %ebx
f010072a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010072d:	68 18 4b 10 f0       	push   $0xf0104b18
f0100732:	e8 96 27 00 00       	call   f0102ecd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100737:	c7 04 24 3c 4b 10 f0 	movl   $0xf0104b3c,(%esp)
f010073e:	e8 8a 27 00 00       	call   f0102ecd <cprintf>


	if (tf != NULL)
f0100743:	83 c4 10             	add    $0x10,%esp
f0100746:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010074a:	74 0e                	je     f010075a <monitor+0x36>
		print_trapframe(tf);
f010074c:	83 ec 0c             	sub    $0xc,%esp
f010074f:	ff 75 08             	pushl  0x8(%ebp)
f0100752:	e8 b0 2b 00 00       	call   f0103307 <print_trapframe>
f0100757:	83 c4 10             	add    $0x10,%esp



	while (1) {
		buf = readline("K> ");
f010075a:	83 ec 0c             	sub    $0xc,%esp
f010075d:	68 ce 49 10 f0       	push   $0xf01049ce
f0100762:	e8 77 38 00 00       	call   f0103fde <readline>
f0100767:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100769:	83 c4 10             	add    $0x10,%esp
f010076c:	85 c0                	test   %eax,%eax
f010076e:	74 ea                	je     f010075a <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100770:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100777:	be 00 00 00 00       	mov    $0x0,%esi
f010077c:	eb 0a                	jmp    f0100788 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010077e:	c6 03 00             	movb   $0x0,(%ebx)
f0100781:	89 f7                	mov    %esi,%edi
f0100783:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100786:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100788:	0f b6 03             	movzbl (%ebx),%eax
f010078b:	84 c0                	test   %al,%al
f010078d:	74 63                	je     f01007f2 <monitor+0xce>
f010078f:	83 ec 08             	sub    $0x8,%esp
f0100792:	0f be c0             	movsbl %al,%eax
f0100795:	50                   	push   %eax
f0100796:	68 d2 49 10 f0       	push   $0xf01049d2
f010079b:	e8 58 3a 00 00       	call   f01041f8 <strchr>
f01007a0:	83 c4 10             	add    $0x10,%esp
f01007a3:	85 c0                	test   %eax,%eax
f01007a5:	75 d7                	jne    f010077e <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01007a7:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007aa:	74 46                	je     f01007f2 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007ac:	83 fe 0f             	cmp    $0xf,%esi
f01007af:	75 14                	jne    f01007c5 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007b1:	83 ec 08             	sub    $0x8,%esp
f01007b4:	6a 10                	push   $0x10
f01007b6:	68 d7 49 10 f0       	push   $0xf01049d7
f01007bb:	e8 0d 27 00 00       	call   f0102ecd <cprintf>
f01007c0:	83 c4 10             	add    $0x10,%esp
f01007c3:	eb 95                	jmp    f010075a <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01007c5:	8d 7e 01             	lea    0x1(%esi),%edi
f01007c8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007cc:	eb 03                	jmp    f01007d1 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007ce:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007d1:	0f b6 03             	movzbl (%ebx),%eax
f01007d4:	84 c0                	test   %al,%al
f01007d6:	74 ae                	je     f0100786 <monitor+0x62>
f01007d8:	83 ec 08             	sub    $0x8,%esp
f01007db:	0f be c0             	movsbl %al,%eax
f01007de:	50                   	push   %eax
f01007df:	68 d2 49 10 f0       	push   $0xf01049d2
f01007e4:	e8 0f 3a 00 00       	call   f01041f8 <strchr>
f01007e9:	83 c4 10             	add    $0x10,%esp
f01007ec:	85 c0                	test   %eax,%eax
f01007ee:	74 de                	je     f01007ce <monitor+0xaa>
f01007f0:	eb 94                	jmp    f0100786 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01007f2:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007f9:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007fa:	85 f6                	test   %esi,%esi
f01007fc:	0f 84 58 ff ff ff    	je     f010075a <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100802:	83 ec 08             	sub    $0x8,%esp
f0100805:	68 9e 49 10 f0       	push   $0xf010499e
f010080a:	ff 75 a8             	pushl  -0x58(%ebp)
f010080d:	e8 88 39 00 00       	call   f010419a <strcmp>
f0100812:	83 c4 10             	add    $0x10,%esp
f0100815:	85 c0                	test   %eax,%eax
f0100817:	74 1e                	je     f0100837 <monitor+0x113>
f0100819:	83 ec 08             	sub    $0x8,%esp
f010081c:	68 ac 49 10 f0       	push   $0xf01049ac
f0100821:	ff 75 a8             	pushl  -0x58(%ebp)
f0100824:	e8 71 39 00 00       	call   f010419a <strcmp>
f0100829:	83 c4 10             	add    $0x10,%esp
f010082c:	85 c0                	test   %eax,%eax
f010082e:	75 2f                	jne    f010085f <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100830:	b8 01 00 00 00       	mov    $0x1,%eax
f0100835:	eb 05                	jmp    f010083c <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100837:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010083c:	83 ec 04             	sub    $0x4,%esp
f010083f:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100842:	01 d0                	add    %edx,%eax
f0100844:	ff 75 08             	pushl  0x8(%ebp)
f0100847:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010084a:	51                   	push   %ecx
f010084b:	56                   	push   %esi
f010084c:	ff 14 85 6c 4b 10 f0 	call   *-0xfefb494(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100853:	83 c4 10             	add    $0x10,%esp
f0100856:	85 c0                	test   %eax,%eax
f0100858:	78 1d                	js     f0100877 <monitor+0x153>
f010085a:	e9 fb fe ff ff       	jmp    f010075a <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010085f:	83 ec 08             	sub    $0x8,%esp
f0100862:	ff 75 a8             	pushl  -0x58(%ebp)
f0100865:	68 f4 49 10 f0       	push   $0xf01049f4
f010086a:	e8 5e 26 00 00       	call   f0102ecd <cprintf>
f010086f:	83 c4 10             	add    $0x10,%esp
f0100872:	e9 e3 fe ff ff       	jmp    f010075a <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100877:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010087a:	5b                   	pop    %ebx
f010087b:	5e                   	pop    %esi
f010087c:	5f                   	pop    %edi
f010087d:	5d                   	pop    %ebp
f010087e:	c3                   	ret    

f010087f <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010087f:	55                   	push   %ebp
f0100880:	89 e5                	mov    %esp,%ebp
f0100882:	53                   	push   %ebx
f0100883:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100886:	83 3d 38 be 17 f0 00 	cmpl   $0x0,0xf017be38
f010088d:	75 11                	jne    f01008a0 <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010088f:	ba 0f db 17 f0       	mov    $0xf017db0f,%edx
f0100894:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010089a:	89 15 38 be 17 f0    	mov    %edx,0xf017be38
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01008a0:	8b 1d 38 be 17 f0    	mov    0xf017be38,%ebx
	nextfree = ROUNDUP(nextfree+n, PGSIZE);
f01008a6:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f01008ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008b3:	89 15 38 be 17 f0    	mov    %edx,0xf017be38
	if((uint32_t)nextfree-KERNBASE > (npages * PGSIZE)) {
f01008b9:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01008bf:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f01008c5:	c1 e1 0c             	shl    $0xc,%ecx
f01008c8:	39 ca                	cmp    %ecx,%edx
f01008ca:	76 14                	jbe    f01008e0 <boot_alloc+0x61>
		panic("Out of memory!\n");
f01008cc:	83 ec 04             	sub    $0x4,%esp
f01008cf:	68 7c 4b 10 f0       	push   $0xf0104b7c
f01008d4:	6a 69                	push   $0x69
f01008d6:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01008db:	e8 c0 f7 ff ff       	call   f01000a0 <_panic>
	}
	return result;
}
f01008e0:	89 d8                	mov    %ebx,%eax
f01008e2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01008e5:	c9                   	leave  
f01008e6:	c3                   	ret    

f01008e7 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01008e7:	89 d1                	mov    %edx,%ecx
f01008e9:	c1 e9 16             	shr    $0x16,%ecx
f01008ec:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008ef:	a8 01                	test   $0x1,%al
f01008f1:	74 52                	je     f0100945 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008f8:	89 c1                	mov    %eax,%ecx
f01008fa:	c1 e9 0c             	shr    $0xc,%ecx
f01008fd:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f0100903:	72 1b                	jb     f0100920 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100905:	55                   	push   %ebp
f0100906:	89 e5                	mov    %esp,%ebp
f0100908:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010090b:	50                   	push   %eax
f010090c:	68 94 4e 10 f0       	push   $0xf0104e94
f0100911:	68 39 03 00 00       	push   $0x339
f0100916:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010091b:	e8 80 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100920:	c1 ea 0c             	shr    $0xc,%edx
f0100923:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100929:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100930:	89 c2                	mov    %eax,%edx
f0100932:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100935:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010093a:	85 d2                	test   %edx,%edx
f010093c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100941:	0f 44 c2             	cmove  %edx,%eax
f0100944:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100945:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010094a:	c3                   	ret    

f010094b <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f010094b:	55                   	push   %ebp
f010094c:	89 e5                	mov    %esp,%ebp
f010094e:	57                   	push   %edi
f010094f:	56                   	push   %esi
f0100950:	53                   	push   %ebx
f0100951:	83 ec 2c             	sub    $0x2c,%esp
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100954:	84 c0                	test   %al,%al
f0100956:	0f 85 72 02 00 00    	jne    f0100bce <check_page_free_list+0x283>
f010095c:	e9 7f 02 00 00       	jmp    f0100be0 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100961:	83 ec 04             	sub    $0x4,%esp
f0100964:	68 b8 4e 10 f0       	push   $0xf0104eb8
f0100969:	68 74 02 00 00       	push   $0x274
f010096e:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100973:	e8 28 f7 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100978:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010097b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010097e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100981:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100984:	89 c2                	mov    %eax,%edx
f0100986:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f010098c:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100992:	0f 95 c2             	setne  %dl
f0100995:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100998:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f010099c:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f010099e:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009a2:	8b 00                	mov    (%eax),%eax
f01009a4:	85 c0                	test   %eax,%eax
f01009a6:	75 dc                	jne    f0100984 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009ab:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009b4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009b7:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009b9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009bc:	a3 40 be 17 f0       	mov    %eax,0xf017be40
check_page_free_list(bool only_low_memory)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009c1:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009c6:	8b 1d 40 be 17 f0    	mov    0xf017be40,%ebx
f01009cc:	eb 53                	jmp    f0100a21 <check_page_free_list+0xd6>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009ce:	89 d8                	mov    %ebx,%eax
f01009d0:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01009d6:	c1 f8 03             	sar    $0x3,%eax
f01009d9:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009dc:	89 c2                	mov    %eax,%edx
f01009de:	c1 ea 16             	shr    $0x16,%edx
f01009e1:	39 f2                	cmp    %esi,%edx
f01009e3:	73 3a                	jae    f0100a1f <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009e5:	89 c2                	mov    %eax,%edx
f01009e7:	c1 ea 0c             	shr    $0xc,%edx
f01009ea:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01009f0:	72 12                	jb     f0100a04 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009f2:	50                   	push   %eax
f01009f3:	68 94 4e 10 f0       	push   $0xf0104e94
f01009f8:	6a 5c                	push   $0x5c
f01009fa:	68 98 4b 10 f0       	push   $0xf0104b98
f01009ff:	e8 9c f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a04:	83 ec 04             	sub    $0x4,%esp
f0100a07:	68 80 00 00 00       	push   $0x80
f0100a0c:	68 97 00 00 00       	push   $0x97
f0100a11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a16:	50                   	push   %eax
f0100a17:	e8 19 38 00 00       	call   f0104235 <memset>
f0100a1c:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a1f:	8b 1b                	mov    (%ebx),%ebx
f0100a21:	85 db                	test   %ebx,%ebx
f0100a23:	75 a9                	jne    f01009ce <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a25:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a2a:	e8 50 fe ff ff       	call   f010087f <boot_alloc>
f0100a2f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a32:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a38:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
		assert(pp < pages + npages);
f0100a3e:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0100a43:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a46:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a49:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a4c:	be 00 00 00 00       	mov    $0x0,%esi
f0100a51:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a54:	e9 30 01 00 00       	jmp    f0100b89 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a59:	39 ca                	cmp    %ecx,%edx
f0100a5b:	73 19                	jae    f0100a76 <check_page_free_list+0x12b>
f0100a5d:	68 a6 4b 10 f0       	push   $0xf0104ba6
f0100a62:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100a67:	68 91 02 00 00       	push   $0x291
f0100a6c:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100a71:	e8 2a f6 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100a76:	39 fa                	cmp    %edi,%edx
f0100a78:	72 19                	jb     f0100a93 <check_page_free_list+0x148>
f0100a7a:	68 c7 4b 10 f0       	push   $0xf0104bc7
f0100a7f:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100a84:	68 92 02 00 00       	push   $0x292
f0100a89:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100a8e:	e8 0d f6 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a93:	89 d0                	mov    %edx,%eax
f0100a95:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a98:	a8 07                	test   $0x7,%al
f0100a9a:	74 19                	je     f0100ab5 <check_page_free_list+0x16a>
f0100a9c:	68 dc 4e 10 f0       	push   $0xf0104edc
f0100aa1:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100aa6:	68 93 02 00 00       	push   $0x293
f0100aab:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100ab0:	e8 eb f5 ff ff       	call   f01000a0 <_panic>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ab5:	c1 f8 03             	sar    $0x3,%eax
f0100ab8:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100abb:	85 c0                	test   %eax,%eax
f0100abd:	75 19                	jne    f0100ad8 <check_page_free_list+0x18d>
f0100abf:	68 db 4b 10 f0       	push   $0xf0104bdb
f0100ac4:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100ac9:	68 96 02 00 00       	push   $0x296
f0100ace:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100ad3:	e8 c8 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ad8:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100add:	75 19                	jne    f0100af8 <check_page_free_list+0x1ad>
f0100adf:	68 ec 4b 10 f0       	push   $0xf0104bec
f0100ae4:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100ae9:	68 97 02 00 00       	push   $0x297
f0100aee:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100af3:	e8 a8 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100af8:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100afd:	75 19                	jne    f0100b18 <check_page_free_list+0x1cd>
f0100aff:	68 10 4f 10 f0       	push   $0xf0104f10
f0100b04:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100b09:	68 98 02 00 00       	push   $0x298
f0100b0e:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100b13:	e8 88 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b18:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b1d:	75 19                	jne    f0100b38 <check_page_free_list+0x1ed>
f0100b1f:	68 05 4c 10 f0       	push   $0xf0104c05
f0100b24:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100b29:	68 99 02 00 00       	push   $0x299
f0100b2e:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100b33:	e8 68 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b38:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b3d:	76 3f                	jbe    f0100b7e <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b3f:	89 c3                	mov    %eax,%ebx
f0100b41:	c1 eb 0c             	shr    $0xc,%ebx
f0100b44:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b47:	77 12                	ja     f0100b5b <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b49:	50                   	push   %eax
f0100b4a:	68 94 4e 10 f0       	push   $0xf0104e94
f0100b4f:	6a 5c                	push   $0x5c
f0100b51:	68 98 4b 10 f0       	push   $0xf0104b98
f0100b56:	e8 45 f5 ff ff       	call   f01000a0 <_panic>
f0100b5b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b60:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b63:	76 1e                	jbe    f0100b83 <check_page_free_list+0x238>
f0100b65:	68 34 4f 10 f0       	push   $0xf0104f34
f0100b6a:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100b6f:	68 9a 02 00 00       	push   $0x29a
f0100b74:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100b79:	e8 22 f5 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b7e:	83 c6 01             	add    $0x1,%esi
f0100b81:	eb 04                	jmp    f0100b87 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100b83:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b87:	8b 12                	mov    (%edx),%edx
f0100b89:	85 d2                	test   %edx,%edx
f0100b8b:	0f 85 c8 fe ff ff    	jne    f0100a59 <check_page_free_list+0x10e>
f0100b91:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100b94:	85 f6                	test   %esi,%esi
f0100b96:	7f 19                	jg     f0100bb1 <check_page_free_list+0x266>
f0100b98:	68 1f 4c 10 f0       	push   $0xf0104c1f
f0100b9d:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100ba2:	68 a2 02 00 00       	push   $0x2a2
f0100ba7:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100bac:	e8 ef f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100bb1:	85 db                	test   %ebx,%ebx
f0100bb3:	7f 42                	jg     f0100bf7 <check_page_free_list+0x2ac>
f0100bb5:	68 31 4c 10 f0       	push   $0xf0104c31
f0100bba:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100bbf:	68 a3 02 00 00       	push   $0x2a3
f0100bc4:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100bc9:	e8 d2 f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bce:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0100bd3:	85 c0                	test   %eax,%eax
f0100bd5:	0f 85 9d fd ff ff    	jne    f0100978 <check_page_free_list+0x2d>
f0100bdb:	e9 81 fd ff ff       	jmp    f0100961 <check_page_free_list+0x16>
f0100be0:	83 3d 40 be 17 f0 00 	cmpl   $0x0,0xf017be40
f0100be7:	0f 84 74 fd ff ff    	je     f0100961 <check_page_free_list+0x16>
check_page_free_list(bool only_low_memory)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bed:	be 00 04 00 00       	mov    $0x400,%esi
f0100bf2:	e9 cf fd ff ff       	jmp    f01009c6 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100bf7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bfa:	5b                   	pop    %ebx
f0100bfb:	5e                   	pop    %esi
f0100bfc:	5f                   	pop    %edi
f0100bfd:	5d                   	pop    %ebp
f0100bfe:	c3                   	ret    

f0100bff <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100bff:	55                   	push   %ebp
f0100c00:	89 e5                	mov    %esp,%ebp
f0100c02:	57                   	push   %edi
f0100c03:	56                   	push   %esi
f0100c04:	53                   	push   %ebx
f0100c05:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100c08:	c7 05 40 be 17 f0 00 	movl   $0x0,0xf017be40
f0100c0f:	00 00 00 
//	cprintf("kern_pgdir locates at %p\n", kern_pgdir);
//	cprintf("pages locates at %p\n", pages);
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
f0100c12:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c17:	e8 63 fc ff ff       	call   f010087f <boot_alloc>
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
		if(i == 0){       //Physical page 0 is in use.
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0100c1c:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
f0100c22:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c27:	c1 e8 0c             	shr    $0xc,%eax
f0100c2a:	8d 7c 06 60          	lea    0x60(%esi,%eax,1),%edi
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f0100c2e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c33:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c38:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c3d:	eb 50                	jmp    f0100c8f <page_init+0x90>
		if(i == 0){       //Physical page 0 is in use.
f0100c3f:	85 c0                	test   %eax,%eax
f0100c41:	75 0e                	jne    f0100c51 <page_init+0x52>
			pages[i].pp_ref = 1;
f0100c43:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0100c49:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
f0100c4f:	eb 3b                	jmp    f0100c8c <page_init+0x8d>
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0100c51:	39 f0                	cmp    %esi,%eax
f0100c53:	72 13                	jb     f0100c68 <page_init+0x69>
f0100c55:	39 f8                	cmp    %edi,%eax
f0100c57:	73 0f                	jae    f0100c68 <page_init+0x69>
			pages[i].pp_ref = 1;
f0100c59:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0100c5f:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
f0100c66:	eb 24                	jmp    f0100c8c <page_init+0x8d>
f0100c68:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		}
		else {
			pages[i].pp_ref = 0;
f0100c6f:	89 d1                	mov    %edx,%ecx
f0100c71:	03 0d 0c cb 17 f0    	add    0xf017cb0c,%ecx
f0100c77:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100c7d:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100c7f:	89 d3                	mov    %edx,%ebx
f0100c81:	03 1d 0c cb 17 f0    	add    0xf017cb0c,%ebx
f0100c87:	b9 01 00 00 00       	mov    $0x1,%ecx
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f0100c8c:	83 c0 01             	add    $0x1,%eax
f0100c8f:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0100c95:	72 a8                	jb     f0100c3f <page_init+0x40>
f0100c97:	84 c9                	test   %cl,%cl
f0100c99:	74 06                	je     f0100ca1 <page_init+0xa2>
f0100c9b:	89 1d 40 be 17 f0    	mov    %ebx,0xf017be40
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100ca1:	83 c4 0c             	add    $0xc,%esp
f0100ca4:	5b                   	pop    %ebx
f0100ca5:	5e                   	pop    %esi
f0100ca6:	5f                   	pop    %edi
f0100ca7:	5d                   	pop    %ebp
f0100ca8:	c3                   	ret    

f0100ca9 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ca9:	55                   	push   %ebp
f0100caa:	89 e5                	mov    %esp,%ebp
f0100cac:	53                   	push   %ebx
f0100cad:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo * result = page_free_list;
f0100cb0:	8b 1d 40 be 17 f0    	mov    0xf017be40,%ebx
	if(page_free_list == NULL)
f0100cb6:	85 db                	test   %ebx,%ebx
f0100cb8:	74 5c                	je     f0100d16 <page_alloc+0x6d>
		return NULL;
	page_free_list = page_free_list->pp_link;
f0100cba:	8b 03                	mov    (%ebx),%eax
f0100cbc:	a3 40 be 17 f0       	mov    %eax,0xf017be40

	result->pp_link = NULL;
f0100cc1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
		memset(page2kva(result), 0, PGSIZE);
	return result;
f0100cc7:	89 d8                	mov    %ebx,%eax
	if(page_free_list == NULL)
		return NULL;
	page_free_list = page_free_list->pp_link;

	result->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO)
f0100cc9:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ccd:	74 4c                	je     f0100d1b <page_alloc+0x72>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ccf:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100cd5:	c1 f8 03             	sar    $0x3,%eax
f0100cd8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cdb:	89 c2                	mov    %eax,%edx
f0100cdd:	c1 ea 0c             	shr    $0xc,%edx
f0100ce0:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100ce6:	72 12                	jb     f0100cfa <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce8:	50                   	push   %eax
f0100ce9:	68 94 4e 10 f0       	push   $0xf0104e94
f0100cee:	6a 5c                	push   $0x5c
f0100cf0:	68 98 4b 10 f0       	push   $0xf0104b98
f0100cf5:	e8 a6 f3 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(result), 0, PGSIZE);
f0100cfa:	83 ec 04             	sub    $0x4,%esp
f0100cfd:	68 00 10 00 00       	push   $0x1000
f0100d02:	6a 00                	push   $0x0
f0100d04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d09:	50                   	push   %eax
f0100d0a:	e8 26 35 00 00       	call   f0104235 <memset>
f0100d0f:	83 c4 10             	add    $0x10,%esp
	return result;
f0100d12:	89 d8                	mov    %ebx,%eax
f0100d14:	eb 05                	jmp    f0100d1b <page_alloc+0x72>
page_alloc(int alloc_flags)
{
	// Fill this function in
	struct PageInfo * result = page_free_list;
	if(page_free_list == NULL)
		return NULL;
f0100d16:	b8 00 00 00 00       	mov    $0x0,%eax

	result->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO)
		memset(page2kva(result), 0, PGSIZE);
	return result;
}
f0100d1b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d1e:	c9                   	leave  
f0100d1f:	c3                   	ret    

f0100d20 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d20:	55                   	push   %ebp
f0100d21:	89 e5                	mov    %esp,%ebp
f0100d23:	83 ec 08             	sub    $0x8,%esp
f0100d26:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0);
f0100d29:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d2e:	74 19                	je     f0100d49 <page_free+0x29>
f0100d30:	68 42 4c 10 f0       	push   $0xf0104c42
f0100d35:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100d3a:	68 51 01 00 00       	push   $0x151
f0100d3f:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100d44:	e8 57 f3 ff ff       	call   f01000a0 <_panic>
	assert(pp->pp_link == NULL);
f0100d49:	83 38 00             	cmpl   $0x0,(%eax)
f0100d4c:	74 19                	je     f0100d67 <page_free+0x47>
f0100d4e:	68 52 4c 10 f0       	push   $0xf0104c52
f0100d53:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0100d58:	68 52 01 00 00       	push   $0x152
f0100d5d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100d62:	e8 39 f3 ff ff       	call   f01000a0 <_panic>

	pp->pp_link = page_free_list;
f0100d67:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0100d6d:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100d6f:	a3 40 be 17 f0       	mov    %eax,0xf017be40
}
f0100d74:	c9                   	leave  
f0100d75:	c3                   	ret    

f0100d76 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d76:	55                   	push   %ebp
f0100d77:	89 e5                	mov    %esp,%ebp
f0100d79:	83 ec 08             	sub    $0x8,%esp
f0100d7c:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d7f:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d83:	83 e8 01             	sub    $0x1,%eax
f0100d86:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d8a:	66 85 c0             	test   %ax,%ax
f0100d8d:	75 0c                	jne    f0100d9b <page_decref+0x25>
		page_free(pp);
f0100d8f:	83 ec 0c             	sub    $0xc,%esp
f0100d92:	52                   	push   %edx
f0100d93:	e8 88 ff ff ff       	call   f0100d20 <page_free>
f0100d98:	83 c4 10             	add    $0x10,%esp
}
f0100d9b:	c9                   	leave  
f0100d9c:	c3                   	ret    

f0100d9d <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d9d:	55                   	push   %ebp
f0100d9e:	89 e5                	mov    %esp,%ebp
f0100da0:	56                   	push   %esi
f0100da1:	53                   	push   %ebx
f0100da2:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	unsigned int page_off;
	pte_t *page_base = NULL;
	struct PageInfo* new_page = NULL;
	unsigned int dic_off = PDX(va); 						 //The page directory index of this page table page.
	pde_t *dic_entry_ptr = pgdir + dic_off;        //The page directory entry of this page table page.
f0100da5:	89 f3                	mov    %esi,%ebx
f0100da7:	c1 eb 16             	shr    $0x16,%ebx
f0100daa:	c1 e3 02             	shl    $0x2,%ebx
f0100dad:	03 5d 08             	add    0x8(%ebp),%ebx
	if( !(*dic_entry_ptr) & PTE_P )                        //If this page table page exists.
f0100db0:	83 3b 00             	cmpl   $0x0,(%ebx)
f0100db3:	75 2d                	jne    f0100de2 <pgdir_walk+0x45>
	{
		if(create)								 //If create is true, then create a new page table page.
f0100db5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100db9:	74 62                	je     f0100e1d <pgdir_walk+0x80>
		{
			new_page = page_alloc(1);
f0100dbb:	83 ec 0c             	sub    $0xc,%esp
f0100dbe:	6a 01                	push   $0x1
f0100dc0:	e8 e4 fe ff ff       	call   f0100ca9 <page_alloc>
			if(new_page == NULL) return NULL;    //Allocation failed.
f0100dc5:	83 c4 10             	add    $0x10,%esp
f0100dc8:	85 c0                	test   %eax,%eax
f0100dca:	74 58                	je     f0100e24 <pgdir_walk+0x87>
			new_page->pp_ref++;
f0100dcc:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0100dd1:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100dd7:	c1 f8 03             	sar    $0x3,%eax
f0100dda:	c1 e0 0c             	shl    $0xc,%eax
f0100ddd:	83 c8 07             	or     $0x7,%eax
f0100de0:	89 03                	mov    %eax,(%ebx)
		}
		else
			return NULL; 
	}	
	page_off = PTX(va);						 //The page table index of this page.
f0100de2:	c1 ee 0c             	shr    $0xc,%esi
f0100de5:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100deb:	8b 03                	mov    (%ebx),%eax
f0100ded:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100df2:	89 c2                	mov    %eax,%edx
f0100df4:	c1 ea 0c             	shr    $0xc,%edx
f0100df7:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100dfd:	72 15                	jb     f0100e14 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dff:	50                   	push   %eax
f0100e00:	68 94 4e 10 f0       	push   $0xf0104e94
f0100e05:	68 8f 01 00 00       	push   $0x18f
f0100e0a:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0100e0f:	e8 8c f2 ff ff       	call   f01000a0 <_panic>
	return &page_base[page_off];
f0100e14:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e1b:	eb 0c                	jmp    f0100e29 <pgdir_walk+0x8c>
			if(new_page == NULL) return NULL;    //Allocation failed.
			new_page->pp_ref++;
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
		}
		else
			return NULL; 
f0100e1d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e22:	eb 05                	jmp    f0100e29 <pgdir_walk+0x8c>
	if( !(*dic_entry_ptr) & PTE_P )                        //If this page table page exists.
	{
		if(create)								 //If create is true, then create a new page table page.
		{
			new_page = page_alloc(1);
			if(new_page == NULL) return NULL;    //Allocation failed.
f0100e24:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL; 
	}	
	page_off = PTX(va);						 //The page table index of this page.
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[page_off];
}
f0100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e2c:	5b                   	pop    %ebx
f0100e2d:	5e                   	pop    %esi
f0100e2e:	5d                   	pop    %ebp
f0100e2f:	c3                   	ret    

f0100e30 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e30:	55                   	push   %ebp
f0100e31:	89 e5                	mov    %esp,%ebp
f0100e33:	57                   	push   %edi
f0100e34:	56                   	push   %esi
f0100e35:	53                   	push   %ebx
f0100e36:	83 ec 1c             	sub    $0x1c,%esp
f0100e39:	89 c7                	mov    %eax,%edi
f0100e3b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e3e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100e41:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
		*entry = (pa | perm | PTE_P);
f0100e46:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e49:	83 c8 01             	or     $0x1,%eax
f0100e4c:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100e4f:	eb 1f                	jmp    f0100e70 <boot_map_region+0x40>
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
f0100e51:	83 ec 04             	sub    $0x4,%esp
f0100e54:	6a 01                	push   $0x1
f0100e56:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e59:	01 d8                	add    %ebx,%eax
f0100e5b:	50                   	push   %eax
f0100e5c:	57                   	push   %edi
f0100e5d:	e8 3b ff ff ff       	call   f0100d9d <pgdir_walk>
		*entry = (pa | perm | PTE_P);
f0100e62:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100e65:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100e67:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100e6d:	83 c4 10             	add    $0x10,%esp
f0100e70:	89 de                	mov    %ebx,%esi
f0100e72:	03 75 08             	add    0x8(%ebp),%esi
f0100e75:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100e78:	77 d7                	ja     f0100e51 <boot_map_region+0x21>
		
		pa += PGSIZE;
		va += PGSIZE;
		
	}
}
f0100e7a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e7d:	5b                   	pop    %ebx
f0100e7e:	5e                   	pop    %esi
f0100e7f:	5f                   	pop    %edi
f0100e80:	5d                   	pop    %ebp
f0100e81:	c3                   	ret    

f0100e82 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e82:	55                   	push   %ebp
f0100e83:	89 e5                	mov    %esp,%ebp
f0100e85:	53                   	push   %ebx
f0100e86:	83 ec 08             	sub    $0x8,%esp
f0100e89:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
f0100e8c:	6a 00                	push   $0x0
f0100e8e:	ff 75 0c             	pushl  0xc(%ebp)
f0100e91:	ff 75 08             	pushl  0x8(%ebp)
f0100e94:	e8 04 ff ff ff       	call   f0100d9d <pgdir_walk>
	if(entry == NULL)
f0100e99:	83 c4 10             	add    $0x10,%esp
f0100e9c:	85 c0                	test   %eax,%eax
f0100e9e:	74 38                	je     f0100ed8 <page_lookup+0x56>
f0100ea0:	89 c1                	mov    %eax,%ecx
		return NULL;
	if(!(*entry & PTE_P))
f0100ea2:	8b 10                	mov    (%eax),%edx
f0100ea4:	f6 c2 01             	test   $0x1,%dl
f0100ea7:	74 36                	je     f0100edf <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ea9:	c1 ea 0c             	shr    $0xc,%edx
f0100eac:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100eb2:	72 14                	jb     f0100ec8 <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f0100eb4:	83 ec 04             	sub    $0x4,%esp
f0100eb7:	68 7c 4f 10 f0       	push   $0xf0104f7c
f0100ebc:	6a 55                	push   $0x55
f0100ebe:	68 98 4b 10 f0       	push   $0xf0104b98
f0100ec3:	e8 d8 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100ec8:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0100ecd:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		return NULL;
	
	ret = pa2page(PTE_ADDR(*entry));
	if(pte_store != NULL)
f0100ed0:	85 db                	test   %ebx,%ebx
f0100ed2:	74 10                	je     f0100ee4 <page_lookup+0x62>
	{
		*pte_store = entry;
f0100ed4:	89 0b                	mov    %ecx,(%ebx)
f0100ed6:	eb 0c                	jmp    f0100ee4 <page_lookup+0x62>
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
	if(entry == NULL)
		return NULL;
f0100ed8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100edd:	eb 05                	jmp    f0100ee4 <page_lookup+0x62>
	if(!(*entry & PTE_P))
		return NULL;
f0100edf:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store != NULL)
	{
		*pte_store = entry;
	}
	return ret;
}
f0100ee4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ee7:	c9                   	leave  
f0100ee8:	c3                   	ret    

f0100ee9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ee9:	55                   	push   %ebp
f0100eea:	89 e5                	mov    %esp,%ebp
f0100eec:	53                   	push   %ebx
f0100eed:	83 ec 18             	sub    $0x18,%esp
f0100ef0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte = NULL;
f0100ef3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &pte);
f0100efa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100efd:	50                   	push   %eax
f0100efe:	53                   	push   %ebx
f0100eff:	ff 75 08             	pushl  0x8(%ebp)
f0100f02:	e8 7b ff ff ff       	call   f0100e82 <page_lookup>
	if(page == NULL) return ;	
f0100f07:	83 c4 10             	add    $0x10,%esp
f0100f0a:	85 c0                	test   %eax,%eax
f0100f0c:	74 18                	je     f0100f26 <page_remove+0x3d>
	
	page_decref(page);
f0100f0e:	83 ec 0c             	sub    $0xc,%esp
f0100f11:	50                   	push   %eax
f0100f12:	e8 5f fe ff ff       	call   f0100d76 <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f17:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
	*pte = 0;
f0100f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f1d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f23:	83 c4 10             	add    $0x10,%esp
}
f0100f26:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f29:	c9                   	leave  
f0100f2a:	c3                   	ret    

f0100f2b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f2b:	55                   	push   %ebp
f0100f2c:	89 e5                	mov    %esp,%ebp
f0100f2e:	57                   	push   %edi
f0100f2f:	56                   	push   %esi
f0100f30:	53                   	push   %ebx
f0100f31:	83 ec 10             	sub    $0x10,%esp
f0100f34:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f37:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
f0100f3a:	6a 01                	push   $0x1
f0100f3c:	ff 75 10             	pushl  0x10(%ebp)
f0100f3f:	56                   	push   %esi
f0100f40:	e8 58 fe ff ff       	call   f0100d9d <pgdir_walk>
	if(entry == NULL) return -E_NO_MEM;
f0100f45:	83 c4 10             	add    $0x10,%esp
f0100f48:	85 c0                	test   %eax,%eax
f0100f4a:	74 4a                	je     f0100f96 <page_insert+0x6b>
f0100f4c:	89 c7                	mov    %eax,%edi

	pp->pp_ref++;
f0100f4e:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*entry) & PTE_P) 	        //If this virtual address is already mapped.
f0100f53:	f6 00 01             	testb  $0x1,(%eax)
f0100f56:	74 15                	je     f0100f6d <page_insert+0x42>
f0100f58:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f5b:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f0100f5e:	83 ec 08             	sub    $0x8,%esp
f0100f61:	ff 75 10             	pushl  0x10(%ebp)
f0100f64:	56                   	push   %esi
f0100f65:	e8 7f ff ff ff       	call   f0100ee9 <page_remove>
f0100f6a:	83 c4 10             	add    $0x10,%esp
	}
	*entry = (page2pa(pp) | perm | PTE_P);
f0100f6d:	2b 1d 0c cb 17 f0    	sub    0xf017cb0c,%ebx
f0100f73:	c1 fb 03             	sar    $0x3,%ebx
f0100f76:	c1 e3 0c             	shl    $0xc,%ebx
f0100f79:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f7c:	83 c8 01             	or     $0x1,%eax
f0100f7f:	09 c3                	or     %eax,%ebx
f0100f81:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;			      //Remember this step!
f0100f83:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f86:	c1 e8 16             	shr    $0x16,%eax
f0100f89:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f8c:	09 14 86             	or     %edx,(%esi,%eax,4)
		
	return 0;
f0100f8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f94:	eb 05                	jmp    f0100f9b <page_insert+0x70>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
	if(entry == NULL) return -E_NO_MEM;
f0100f96:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*entry = (page2pa(pp) | perm | PTE_P);
	pgdir[PDX(va)] |= perm;			      //Remember this step!
		
	return 0;
}
f0100f9b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f9e:	5b                   	pop    %ebx
f0100f9f:	5e                   	pop    %esi
f0100fa0:	5f                   	pop    %edi
f0100fa1:	5d                   	pop    %ebp
f0100fa2:	c3                   	ret    

f0100fa3 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100fa3:	55                   	push   %ebp
f0100fa4:	89 e5                	mov    %esp,%ebp
f0100fa6:	57                   	push   %edi
f0100fa7:	56                   	push   %esi
f0100fa8:	53                   	push   %ebx
f0100fa9:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100fac:	6a 15                	push   $0x15
f0100fae:	e8 b3 1e 00 00       	call   f0102e66 <mc146818_read>
f0100fb3:	89 c3                	mov    %eax,%ebx
f0100fb5:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100fbc:	e8 a5 1e 00 00       	call   f0102e66 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100fc1:	c1 e0 08             	shl    $0x8,%eax
f0100fc4:	09 d8                	or     %ebx,%eax
f0100fc6:	c1 e0 0a             	shl    $0xa,%eax
f0100fc9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100fcf:	85 c0                	test   %eax,%eax
f0100fd1:	0f 48 c2             	cmovs  %edx,%eax
f0100fd4:	c1 f8 0c             	sar    $0xc,%eax
f0100fd7:	a3 44 be 17 f0       	mov    %eax,0xf017be44
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100fdc:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100fe3:	e8 7e 1e 00 00       	call   f0102e66 <mc146818_read>
f0100fe8:	89 c3                	mov    %eax,%ebx
f0100fea:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100ff1:	e8 70 1e 00 00       	call   f0102e66 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100ff6:	c1 e0 08             	shl    $0x8,%eax
f0100ff9:	09 d8                	or     %ebx,%eax
f0100ffb:	c1 e0 0a             	shl    $0xa,%eax
f0100ffe:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101004:	83 c4 10             	add    $0x10,%esp
f0101007:	85 c0                	test   %eax,%eax
f0101009:	0f 48 c2             	cmovs  %edx,%eax
f010100c:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010100f:	85 c0                	test   %eax,%eax
f0101011:	74 0e                	je     f0101021 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101013:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101019:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04
f010101f:	eb 0c                	jmp    f010102d <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101021:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0101027:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010102d:	c1 e0 0c             	shl    $0xc,%eax
f0101030:	c1 e8 0a             	shr    $0xa,%eax
f0101033:	50                   	push   %eax
f0101034:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0101039:	c1 e0 0c             	shl    $0xc,%eax
f010103c:	c1 e8 0a             	shr    $0xa,%eax
f010103f:	50                   	push   %eax
f0101040:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0101045:	c1 e0 0c             	shl    $0xc,%eax
f0101048:	c1 e8 0a             	shr    $0xa,%eax
f010104b:	50                   	push   %eax
f010104c:	68 9c 4f 10 f0       	push   $0xf0104f9c
f0101051:	e8 77 1e 00 00       	call   f0102ecd <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101056:	b8 00 10 00 00       	mov    $0x1000,%eax
f010105b:	e8 1f f8 ff ff       	call   f010087f <boot_alloc>
f0101060:	a3 08 cb 17 f0       	mov    %eax,0xf017cb08
	memset(kern_pgdir, 0, PGSIZE);
f0101065:	83 c4 0c             	add    $0xc,%esp
f0101068:	68 00 10 00 00       	push   $0x1000
f010106d:	6a 00                	push   $0x0
f010106f:	50                   	push   %eax
f0101070:	e8 c0 31 00 00       	call   f0104235 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101075:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010107a:	83 c4 10             	add    $0x10,%esp
f010107d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101082:	77 15                	ja     f0101099 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101084:	50                   	push   %eax
f0101085:	68 d8 4f 10 f0       	push   $0xf0104fd8
f010108a:	68 90 00 00 00       	push   $0x90
f010108f:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101094:	e8 07 f0 ff ff       	call   f01000a0 <_panic>
f0101099:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010109f:	83 ca 05             	or     $0x5,%edx
f01010a2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f01010a8:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f01010ad:	c1 e0 03             	shl    $0x3,%eax
f01010b0:	e8 ca f7 ff ff       	call   f010087f <boot_alloc>
f01010b5:	a3 0c cb 17 f0       	mov    %eax,0xf017cb0c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01010ba:	83 ec 04             	sub    $0x4,%esp
f01010bd:	8b 3d 04 cb 17 f0    	mov    0xf017cb04,%edi
f01010c3:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01010ca:	52                   	push   %edx
f01010cb:	6a 00                	push   $0x0
f01010cd:	50                   	push   %eax
f01010ce:	e8 62 31 00 00       	call   f0104235 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f01010d3:	b8 00 80 01 00       	mov    $0x18000,%eax
f01010d8:	e8 a2 f7 ff ff       	call   f010087f <boot_alloc>
f01010dd:	a3 4c be 17 f0       	mov    %eax,0xf017be4c
	memset(envs, 0, NENV * sizeof(struct Env));
f01010e2:	83 c4 0c             	add    $0xc,%esp
f01010e5:	68 00 80 01 00       	push   $0x18000
f01010ea:	6a 00                	push   $0x0
f01010ec:	50                   	push   %eax
f01010ed:	e8 43 31 00 00       	call   f0104235 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01010f2:	e8 08 fb ff ff       	call   f0100bff <page_init>

	check_page_free_list(1);
f01010f7:	b8 01 00 00 00       	mov    $0x1,%eax
f01010fc:	e8 4a f8 ff ff       	call   f010094b <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101101:	83 c4 10             	add    $0x10,%esp
f0101104:	83 3d 0c cb 17 f0 00 	cmpl   $0x0,0xf017cb0c
f010110b:	75 17                	jne    f0101124 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010110d:	83 ec 04             	sub    $0x4,%esp
f0101110:	68 66 4c 10 f0       	push   $0xf0104c66
f0101115:	68 b4 02 00 00       	push   $0x2b4
f010111a:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010111f:	e8 7c ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101124:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0101129:	bb 00 00 00 00       	mov    $0x0,%ebx
f010112e:	eb 05                	jmp    f0101135 <mem_init+0x192>
		++nfree;
f0101130:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101133:	8b 00                	mov    (%eax),%eax
f0101135:	85 c0                	test   %eax,%eax
f0101137:	75 f7                	jne    f0101130 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101139:	83 ec 0c             	sub    $0xc,%esp
f010113c:	6a 00                	push   $0x0
f010113e:	e8 66 fb ff ff       	call   f0100ca9 <page_alloc>
f0101143:	89 c7                	mov    %eax,%edi
f0101145:	83 c4 10             	add    $0x10,%esp
f0101148:	85 c0                	test   %eax,%eax
f010114a:	75 19                	jne    f0101165 <mem_init+0x1c2>
f010114c:	68 81 4c 10 f0       	push   $0xf0104c81
f0101151:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101156:	68 bc 02 00 00       	push   $0x2bc
f010115b:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101160:	e8 3b ef ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101165:	83 ec 0c             	sub    $0xc,%esp
f0101168:	6a 00                	push   $0x0
f010116a:	e8 3a fb ff ff       	call   f0100ca9 <page_alloc>
f010116f:	89 c6                	mov    %eax,%esi
f0101171:	83 c4 10             	add    $0x10,%esp
f0101174:	85 c0                	test   %eax,%eax
f0101176:	75 19                	jne    f0101191 <mem_init+0x1ee>
f0101178:	68 97 4c 10 f0       	push   $0xf0104c97
f010117d:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101182:	68 bd 02 00 00       	push   $0x2bd
f0101187:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010118c:	e8 0f ef ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101191:	83 ec 0c             	sub    $0xc,%esp
f0101194:	6a 00                	push   $0x0
f0101196:	e8 0e fb ff ff       	call   f0100ca9 <page_alloc>
f010119b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010119e:	83 c4 10             	add    $0x10,%esp
f01011a1:	85 c0                	test   %eax,%eax
f01011a3:	75 19                	jne    f01011be <mem_init+0x21b>
f01011a5:	68 ad 4c 10 f0       	push   $0xf0104cad
f01011aa:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01011af:	68 be 02 00 00       	push   $0x2be
f01011b4:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01011b9:	e8 e2 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011be:	39 f7                	cmp    %esi,%edi
f01011c0:	75 19                	jne    f01011db <mem_init+0x238>
f01011c2:	68 c3 4c 10 f0       	push   $0xf0104cc3
f01011c7:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01011cc:	68 c1 02 00 00       	push   $0x2c1
f01011d1:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01011d6:	e8 c5 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011de:	39 c6                	cmp    %eax,%esi
f01011e0:	74 04                	je     f01011e6 <mem_init+0x243>
f01011e2:	39 c7                	cmp    %eax,%edi
f01011e4:	75 19                	jne    f01011ff <mem_init+0x25c>
f01011e6:	68 fc 4f 10 f0       	push   $0xf0104ffc
f01011eb:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01011f0:	68 c2 02 00 00       	push   $0x2c2
f01011f5:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01011fa:	e8 a1 ee ff ff       	call   f01000a0 <_panic>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011ff:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101205:	8b 15 04 cb 17 f0    	mov    0xf017cb04,%edx
f010120b:	c1 e2 0c             	shl    $0xc,%edx
f010120e:	89 f8                	mov    %edi,%eax
f0101210:	29 c8                	sub    %ecx,%eax
f0101212:	c1 f8 03             	sar    $0x3,%eax
f0101215:	c1 e0 0c             	shl    $0xc,%eax
f0101218:	39 d0                	cmp    %edx,%eax
f010121a:	72 19                	jb     f0101235 <mem_init+0x292>
f010121c:	68 d5 4c 10 f0       	push   $0xf0104cd5
f0101221:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101226:	68 c3 02 00 00       	push   $0x2c3
f010122b:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101230:	e8 6b ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101235:	89 f0                	mov    %esi,%eax
f0101237:	29 c8                	sub    %ecx,%eax
f0101239:	c1 f8 03             	sar    $0x3,%eax
f010123c:	c1 e0 0c             	shl    $0xc,%eax
f010123f:	39 c2                	cmp    %eax,%edx
f0101241:	77 19                	ja     f010125c <mem_init+0x2b9>
f0101243:	68 f2 4c 10 f0       	push   $0xf0104cf2
f0101248:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010124d:	68 c4 02 00 00       	push   $0x2c4
f0101252:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101257:	e8 44 ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010125c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010125f:	29 c8                	sub    %ecx,%eax
f0101261:	c1 f8 03             	sar    $0x3,%eax
f0101264:	c1 e0 0c             	shl    $0xc,%eax
f0101267:	39 c2                	cmp    %eax,%edx
f0101269:	77 19                	ja     f0101284 <mem_init+0x2e1>
f010126b:	68 0f 4d 10 f0       	push   $0xf0104d0f
f0101270:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101275:	68 c5 02 00 00       	push   $0x2c5
f010127a:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010127f:	e8 1c ee ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101284:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0101289:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010128c:	c7 05 40 be 17 f0 00 	movl   $0x0,0xf017be40
f0101293:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101296:	83 ec 0c             	sub    $0xc,%esp
f0101299:	6a 00                	push   $0x0
f010129b:	e8 09 fa ff ff       	call   f0100ca9 <page_alloc>
f01012a0:	83 c4 10             	add    $0x10,%esp
f01012a3:	85 c0                	test   %eax,%eax
f01012a5:	74 19                	je     f01012c0 <mem_init+0x31d>
f01012a7:	68 2c 4d 10 f0       	push   $0xf0104d2c
f01012ac:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01012b1:	68 cc 02 00 00       	push   $0x2cc
f01012b6:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01012bb:	e8 e0 ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012c0:	83 ec 0c             	sub    $0xc,%esp
f01012c3:	57                   	push   %edi
f01012c4:	e8 57 fa ff ff       	call   f0100d20 <page_free>
	page_free(pp1);
f01012c9:	89 34 24             	mov    %esi,(%esp)
f01012cc:	e8 4f fa ff ff       	call   f0100d20 <page_free>
	page_free(pp2);
f01012d1:	83 c4 04             	add    $0x4,%esp
f01012d4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012d7:	e8 44 fa ff ff       	call   f0100d20 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012e3:	e8 c1 f9 ff ff       	call   f0100ca9 <page_alloc>
f01012e8:	89 c6                	mov    %eax,%esi
f01012ea:	83 c4 10             	add    $0x10,%esp
f01012ed:	85 c0                	test   %eax,%eax
f01012ef:	75 19                	jne    f010130a <mem_init+0x367>
f01012f1:	68 81 4c 10 f0       	push   $0xf0104c81
f01012f6:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01012fb:	68 d3 02 00 00       	push   $0x2d3
f0101300:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101305:	e8 96 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010130a:	83 ec 0c             	sub    $0xc,%esp
f010130d:	6a 00                	push   $0x0
f010130f:	e8 95 f9 ff ff       	call   f0100ca9 <page_alloc>
f0101314:	89 c7                	mov    %eax,%edi
f0101316:	83 c4 10             	add    $0x10,%esp
f0101319:	85 c0                	test   %eax,%eax
f010131b:	75 19                	jne    f0101336 <mem_init+0x393>
f010131d:	68 97 4c 10 f0       	push   $0xf0104c97
f0101322:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101327:	68 d4 02 00 00       	push   $0x2d4
f010132c:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101331:	e8 6a ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101336:	83 ec 0c             	sub    $0xc,%esp
f0101339:	6a 00                	push   $0x0
f010133b:	e8 69 f9 ff ff       	call   f0100ca9 <page_alloc>
f0101340:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101343:	83 c4 10             	add    $0x10,%esp
f0101346:	85 c0                	test   %eax,%eax
f0101348:	75 19                	jne    f0101363 <mem_init+0x3c0>
f010134a:	68 ad 4c 10 f0       	push   $0xf0104cad
f010134f:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101354:	68 d5 02 00 00       	push   $0x2d5
f0101359:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010135e:	e8 3d ed ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101363:	39 fe                	cmp    %edi,%esi
f0101365:	75 19                	jne    f0101380 <mem_init+0x3dd>
f0101367:	68 c3 4c 10 f0       	push   $0xf0104cc3
f010136c:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101371:	68 d7 02 00 00       	push   $0x2d7
f0101376:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010137b:	e8 20 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101380:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101383:	39 c7                	cmp    %eax,%edi
f0101385:	74 04                	je     f010138b <mem_init+0x3e8>
f0101387:	39 c6                	cmp    %eax,%esi
f0101389:	75 19                	jne    f01013a4 <mem_init+0x401>
f010138b:	68 fc 4f 10 f0       	push   $0xf0104ffc
f0101390:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101395:	68 d8 02 00 00       	push   $0x2d8
f010139a:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010139f:	e8 fc ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01013a4:	83 ec 0c             	sub    $0xc,%esp
f01013a7:	6a 00                	push   $0x0
f01013a9:	e8 fb f8 ff ff       	call   f0100ca9 <page_alloc>
f01013ae:	83 c4 10             	add    $0x10,%esp
f01013b1:	85 c0                	test   %eax,%eax
f01013b3:	74 19                	je     f01013ce <mem_init+0x42b>
f01013b5:	68 2c 4d 10 f0       	push   $0xf0104d2c
f01013ba:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01013bf:	68 d9 02 00 00       	push   $0x2d9
f01013c4:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01013c9:	e8 d2 ec ff ff       	call   f01000a0 <_panic>
f01013ce:	89 f0                	mov    %esi,%eax
f01013d0:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01013d6:	c1 f8 03             	sar    $0x3,%eax
f01013d9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013dc:	89 c2                	mov    %eax,%edx
f01013de:	c1 ea 0c             	shr    $0xc,%edx
f01013e1:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01013e7:	72 12                	jb     f01013fb <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013e9:	50                   	push   %eax
f01013ea:	68 94 4e 10 f0       	push   $0xf0104e94
f01013ef:	6a 5c                	push   $0x5c
f01013f1:	68 98 4b 10 f0       	push   $0xf0104b98
f01013f6:	e8 a5 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01013fb:	83 ec 04             	sub    $0x4,%esp
f01013fe:	68 00 10 00 00       	push   $0x1000
f0101403:	6a 01                	push   $0x1
f0101405:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010140a:	50                   	push   %eax
f010140b:	e8 25 2e 00 00       	call   f0104235 <memset>
	page_free(pp0);
f0101410:	89 34 24             	mov    %esi,(%esp)
f0101413:	e8 08 f9 ff ff       	call   f0100d20 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101418:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010141f:	e8 85 f8 ff ff       	call   f0100ca9 <page_alloc>
f0101424:	83 c4 10             	add    $0x10,%esp
f0101427:	85 c0                	test   %eax,%eax
f0101429:	75 19                	jne    f0101444 <mem_init+0x4a1>
f010142b:	68 3b 4d 10 f0       	push   $0xf0104d3b
f0101430:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101435:	68 de 02 00 00       	push   $0x2de
f010143a:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010143f:	e8 5c ec ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f0101444:	39 c6                	cmp    %eax,%esi
f0101446:	74 19                	je     f0101461 <mem_init+0x4be>
f0101448:	68 59 4d 10 f0       	push   $0xf0104d59
f010144d:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101452:	68 df 02 00 00       	push   $0x2df
f0101457:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010145c:	e8 3f ec ff ff       	call   f01000a0 <_panic>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101461:	89 f0                	mov    %esi,%eax
f0101463:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101469:	c1 f8 03             	sar    $0x3,%eax
f010146c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010146f:	89 c2                	mov    %eax,%edx
f0101471:	c1 ea 0c             	shr    $0xc,%edx
f0101474:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010147a:	72 12                	jb     f010148e <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010147c:	50                   	push   %eax
f010147d:	68 94 4e 10 f0       	push   $0xf0104e94
f0101482:	6a 5c                	push   $0x5c
f0101484:	68 98 4b 10 f0       	push   $0xf0104b98
f0101489:	e8 12 ec ff ff       	call   f01000a0 <_panic>
f010148e:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101494:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010149a:	80 38 00             	cmpb   $0x0,(%eax)
f010149d:	74 19                	je     f01014b8 <mem_init+0x515>
f010149f:	68 69 4d 10 f0       	push   $0xf0104d69
f01014a4:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01014a9:	68 e2 02 00 00       	push   $0x2e2
f01014ae:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01014b3:	e8 e8 eb ff ff       	call   f01000a0 <_panic>
f01014b8:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014bb:	39 d0                	cmp    %edx,%eax
f01014bd:	75 db                	jne    f010149a <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014c2:	a3 40 be 17 f0       	mov    %eax,0xf017be40

	// free the pages we took
	page_free(pp0);
f01014c7:	83 ec 0c             	sub    $0xc,%esp
f01014ca:	56                   	push   %esi
f01014cb:	e8 50 f8 ff ff       	call   f0100d20 <page_free>
	page_free(pp1);
f01014d0:	89 3c 24             	mov    %edi,(%esp)
f01014d3:	e8 48 f8 ff ff       	call   f0100d20 <page_free>
	page_free(pp2);
f01014d8:	83 c4 04             	add    $0x4,%esp
f01014db:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014de:	e8 3d f8 ff ff       	call   f0100d20 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014e3:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f01014e8:	83 c4 10             	add    $0x10,%esp
f01014eb:	eb 05                	jmp    f01014f2 <mem_init+0x54f>
		--nfree;
f01014ed:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014f0:	8b 00                	mov    (%eax),%eax
f01014f2:	85 c0                	test   %eax,%eax
f01014f4:	75 f7                	jne    f01014ed <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01014f6:	85 db                	test   %ebx,%ebx
f01014f8:	74 19                	je     f0101513 <mem_init+0x570>
f01014fa:	68 73 4d 10 f0       	push   $0xf0104d73
f01014ff:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101504:	68 ef 02 00 00       	push   $0x2ef
f0101509:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010150e:	e8 8d eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101513:	83 ec 0c             	sub    $0xc,%esp
f0101516:	68 1c 50 10 f0       	push   $0xf010501c
f010151b:	e8 ad 19 00 00       	call   f0102ecd <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101520:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101527:	e8 7d f7 ff ff       	call   f0100ca9 <page_alloc>
f010152c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010152f:	83 c4 10             	add    $0x10,%esp
f0101532:	85 c0                	test   %eax,%eax
f0101534:	75 19                	jne    f010154f <mem_init+0x5ac>
f0101536:	68 81 4c 10 f0       	push   $0xf0104c81
f010153b:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101540:	68 4d 03 00 00       	push   $0x34d
f0101545:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010154a:	e8 51 eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010154f:	83 ec 0c             	sub    $0xc,%esp
f0101552:	6a 00                	push   $0x0
f0101554:	e8 50 f7 ff ff       	call   f0100ca9 <page_alloc>
f0101559:	89 c3                	mov    %eax,%ebx
f010155b:	83 c4 10             	add    $0x10,%esp
f010155e:	85 c0                	test   %eax,%eax
f0101560:	75 19                	jne    f010157b <mem_init+0x5d8>
f0101562:	68 97 4c 10 f0       	push   $0xf0104c97
f0101567:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010156c:	68 4e 03 00 00       	push   $0x34e
f0101571:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101576:	e8 25 eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010157b:	83 ec 0c             	sub    $0xc,%esp
f010157e:	6a 00                	push   $0x0
f0101580:	e8 24 f7 ff ff       	call   f0100ca9 <page_alloc>
f0101585:	89 c6                	mov    %eax,%esi
f0101587:	83 c4 10             	add    $0x10,%esp
f010158a:	85 c0                	test   %eax,%eax
f010158c:	75 19                	jne    f01015a7 <mem_init+0x604>
f010158e:	68 ad 4c 10 f0       	push   $0xf0104cad
f0101593:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101598:	68 4f 03 00 00       	push   $0x34f
f010159d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01015a2:	e8 f9 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015a7:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015aa:	75 19                	jne    f01015c5 <mem_init+0x622>
f01015ac:	68 c3 4c 10 f0       	push   $0xf0104cc3
f01015b1:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01015b6:	68 52 03 00 00       	push   $0x352
f01015bb:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01015c0:	e8 db ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015c5:	39 c3                	cmp    %eax,%ebx
f01015c7:	74 05                	je     f01015ce <mem_init+0x62b>
f01015c9:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015cc:	75 19                	jne    f01015e7 <mem_init+0x644>
f01015ce:	68 fc 4f 10 f0       	push   $0xf0104ffc
f01015d3:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01015d8:	68 53 03 00 00       	push   $0x353
f01015dd:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01015e2:	e8 b9 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015e7:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f01015ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015ef:	c7 05 40 be 17 f0 00 	movl   $0x0,0xf017be40
f01015f6:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015f9:	83 ec 0c             	sub    $0xc,%esp
f01015fc:	6a 00                	push   $0x0
f01015fe:	e8 a6 f6 ff ff       	call   f0100ca9 <page_alloc>
f0101603:	83 c4 10             	add    $0x10,%esp
f0101606:	85 c0                	test   %eax,%eax
f0101608:	74 19                	je     f0101623 <mem_init+0x680>
f010160a:	68 2c 4d 10 f0       	push   $0xf0104d2c
f010160f:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101614:	68 5a 03 00 00       	push   $0x35a
f0101619:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010161e:	e8 7d ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101623:	83 ec 04             	sub    $0x4,%esp
f0101626:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101629:	50                   	push   %eax
f010162a:	6a 00                	push   $0x0
f010162c:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101632:	e8 4b f8 ff ff       	call   f0100e82 <page_lookup>
f0101637:	83 c4 10             	add    $0x10,%esp
f010163a:	85 c0                	test   %eax,%eax
f010163c:	74 19                	je     f0101657 <mem_init+0x6b4>
f010163e:	68 3c 50 10 f0       	push   $0xf010503c
f0101643:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101648:	68 5d 03 00 00       	push   $0x35d
f010164d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101652:	e8 49 ea ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101657:	6a 02                	push   $0x2
f0101659:	6a 00                	push   $0x0
f010165b:	53                   	push   %ebx
f010165c:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101662:	e8 c4 f8 ff ff       	call   f0100f2b <page_insert>
f0101667:	83 c4 10             	add    $0x10,%esp
f010166a:	85 c0                	test   %eax,%eax
f010166c:	78 19                	js     f0101687 <mem_init+0x6e4>
f010166e:	68 74 50 10 f0       	push   $0xf0105074
f0101673:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101678:	68 60 03 00 00       	push   $0x360
f010167d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101682:	e8 19 ea ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101687:	83 ec 0c             	sub    $0xc,%esp
f010168a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010168d:	e8 8e f6 ff ff       	call   f0100d20 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101692:	6a 02                	push   $0x2
f0101694:	6a 00                	push   $0x0
f0101696:	53                   	push   %ebx
f0101697:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010169d:	e8 89 f8 ff ff       	call   f0100f2b <page_insert>
f01016a2:	83 c4 20             	add    $0x20,%esp
f01016a5:	85 c0                	test   %eax,%eax
f01016a7:	74 19                	je     f01016c2 <mem_init+0x71f>
f01016a9:	68 a4 50 10 f0       	push   $0xf01050a4
f01016ae:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01016b3:	68 64 03 00 00       	push   $0x364
f01016b8:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01016bd:	e8 de e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016c2:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016c8:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f01016cd:	89 c1                	mov    %eax,%ecx
f01016cf:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016d2:	8b 17                	mov    (%edi),%edx
f01016d4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016dd:	29 c8                	sub    %ecx,%eax
f01016df:	c1 f8 03             	sar    $0x3,%eax
f01016e2:	c1 e0 0c             	shl    $0xc,%eax
f01016e5:	39 c2                	cmp    %eax,%edx
f01016e7:	74 19                	je     f0101702 <mem_init+0x75f>
f01016e9:	68 d4 50 10 f0       	push   $0xf01050d4
f01016ee:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01016f3:	68 65 03 00 00       	push   $0x365
f01016f8:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01016fd:	e8 9e e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101702:	ba 00 00 00 00       	mov    $0x0,%edx
f0101707:	89 f8                	mov    %edi,%eax
f0101709:	e8 d9 f1 ff ff       	call   f01008e7 <check_va2pa>
f010170e:	89 da                	mov    %ebx,%edx
f0101710:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101713:	c1 fa 03             	sar    $0x3,%edx
f0101716:	c1 e2 0c             	shl    $0xc,%edx
f0101719:	39 d0                	cmp    %edx,%eax
f010171b:	74 19                	je     f0101736 <mem_init+0x793>
f010171d:	68 fc 50 10 f0       	push   $0xf01050fc
f0101722:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101727:	68 66 03 00 00       	push   $0x366
f010172c:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101731:	e8 6a e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101736:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010173b:	74 19                	je     f0101756 <mem_init+0x7b3>
f010173d:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0101742:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101747:	68 67 03 00 00       	push   $0x367
f010174c:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101751:	e8 4a e9 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101756:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101759:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010175e:	74 19                	je     f0101779 <mem_init+0x7d6>
f0101760:	68 8f 4d 10 f0       	push   $0xf0104d8f
f0101765:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010176a:	68 68 03 00 00       	push   $0x368
f010176f:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101774:	e8 27 e9 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101779:	6a 02                	push   $0x2
f010177b:	68 00 10 00 00       	push   $0x1000
f0101780:	56                   	push   %esi
f0101781:	57                   	push   %edi
f0101782:	e8 a4 f7 ff ff       	call   f0100f2b <page_insert>
f0101787:	83 c4 10             	add    $0x10,%esp
f010178a:	85 c0                	test   %eax,%eax
f010178c:	74 19                	je     f01017a7 <mem_init+0x804>
f010178e:	68 2c 51 10 f0       	push   $0xf010512c
f0101793:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101798:	68 6b 03 00 00       	push   $0x36b
f010179d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01017a2:	e8 f9 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017a7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017ac:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01017b1:	e8 31 f1 ff ff       	call   f01008e7 <check_va2pa>
f01017b6:	89 f2                	mov    %esi,%edx
f01017b8:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f01017be:	c1 fa 03             	sar    $0x3,%edx
f01017c1:	c1 e2 0c             	shl    $0xc,%edx
f01017c4:	39 d0                	cmp    %edx,%eax
f01017c6:	74 19                	je     f01017e1 <mem_init+0x83e>
f01017c8:	68 68 51 10 f0       	push   $0xf0105168
f01017cd:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01017d2:	68 6c 03 00 00       	push   $0x36c
f01017d7:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01017dc:	e8 bf e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01017e1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017e6:	74 19                	je     f0101801 <mem_init+0x85e>
f01017e8:	68 a0 4d 10 f0       	push   $0xf0104da0
f01017ed:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01017f2:	68 6d 03 00 00       	push   $0x36d
f01017f7:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01017fc:	e8 9f e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101801:	83 ec 0c             	sub    $0xc,%esp
f0101804:	6a 00                	push   $0x0
f0101806:	e8 9e f4 ff ff       	call   f0100ca9 <page_alloc>
f010180b:	83 c4 10             	add    $0x10,%esp
f010180e:	85 c0                	test   %eax,%eax
f0101810:	74 19                	je     f010182b <mem_init+0x888>
f0101812:	68 2c 4d 10 f0       	push   $0xf0104d2c
f0101817:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010181c:	68 70 03 00 00       	push   $0x370
f0101821:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101826:	e8 75 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010182b:	6a 02                	push   $0x2
f010182d:	68 00 10 00 00       	push   $0x1000
f0101832:	56                   	push   %esi
f0101833:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101839:	e8 ed f6 ff ff       	call   f0100f2b <page_insert>
f010183e:	83 c4 10             	add    $0x10,%esp
f0101841:	85 c0                	test   %eax,%eax
f0101843:	74 19                	je     f010185e <mem_init+0x8bb>
f0101845:	68 2c 51 10 f0       	push   $0xf010512c
f010184a:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010184f:	68 73 03 00 00       	push   $0x373
f0101854:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101859:	e8 42 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010185e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101863:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101868:	e8 7a f0 ff ff       	call   f01008e7 <check_va2pa>
f010186d:	89 f2                	mov    %esi,%edx
f010186f:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101875:	c1 fa 03             	sar    $0x3,%edx
f0101878:	c1 e2 0c             	shl    $0xc,%edx
f010187b:	39 d0                	cmp    %edx,%eax
f010187d:	74 19                	je     f0101898 <mem_init+0x8f5>
f010187f:	68 68 51 10 f0       	push   $0xf0105168
f0101884:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101889:	68 74 03 00 00       	push   $0x374
f010188e:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101893:	e8 08 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101898:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010189d:	74 19                	je     f01018b8 <mem_init+0x915>
f010189f:	68 a0 4d 10 f0       	push   $0xf0104da0
f01018a4:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01018a9:	68 75 03 00 00       	push   $0x375
f01018ae:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01018b3:	e8 e8 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018b8:	83 ec 0c             	sub    $0xc,%esp
f01018bb:	6a 00                	push   $0x0
f01018bd:	e8 e7 f3 ff ff       	call   f0100ca9 <page_alloc>
f01018c2:	83 c4 10             	add    $0x10,%esp
f01018c5:	85 c0                	test   %eax,%eax
f01018c7:	74 19                	je     f01018e2 <mem_init+0x93f>
f01018c9:	68 2c 4d 10 f0       	push   $0xf0104d2c
f01018ce:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01018d3:	68 79 03 00 00       	push   $0x379
f01018d8:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01018dd:	e8 be e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01018e2:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f01018e8:	8b 02                	mov    (%edx),%eax
f01018ea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018ef:	89 c1                	mov    %eax,%ecx
f01018f1:	c1 e9 0c             	shr    $0xc,%ecx
f01018f4:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f01018fa:	72 15                	jb     f0101911 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018fc:	50                   	push   %eax
f01018fd:	68 94 4e 10 f0       	push   $0xf0104e94
f0101902:	68 7c 03 00 00       	push   $0x37c
f0101907:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010190c:	e8 8f e7 ff ff       	call   f01000a0 <_panic>
f0101911:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101916:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101919:	83 ec 04             	sub    $0x4,%esp
f010191c:	6a 00                	push   $0x0
f010191e:	68 00 10 00 00       	push   $0x1000
f0101923:	52                   	push   %edx
f0101924:	e8 74 f4 ff ff       	call   f0100d9d <pgdir_walk>
f0101929:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010192c:	8d 57 04             	lea    0x4(%edi),%edx
f010192f:	83 c4 10             	add    $0x10,%esp
f0101932:	39 d0                	cmp    %edx,%eax
f0101934:	74 19                	je     f010194f <mem_init+0x9ac>
f0101936:	68 98 51 10 f0       	push   $0xf0105198
f010193b:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101940:	68 7d 03 00 00       	push   $0x37d
f0101945:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010194a:	e8 51 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010194f:	6a 06                	push   $0x6
f0101951:	68 00 10 00 00       	push   $0x1000
f0101956:	56                   	push   %esi
f0101957:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010195d:	e8 c9 f5 ff ff       	call   f0100f2b <page_insert>
f0101962:	83 c4 10             	add    $0x10,%esp
f0101965:	85 c0                	test   %eax,%eax
f0101967:	74 19                	je     f0101982 <mem_init+0x9df>
f0101969:	68 d8 51 10 f0       	push   $0xf01051d8
f010196e:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101973:	68 80 03 00 00       	push   $0x380
f0101978:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010197d:	e8 1e e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101982:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101988:	ba 00 10 00 00       	mov    $0x1000,%edx
f010198d:	89 f8                	mov    %edi,%eax
f010198f:	e8 53 ef ff ff       	call   f01008e7 <check_va2pa>
f0101994:	89 f2                	mov    %esi,%edx
f0101996:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f010199c:	c1 fa 03             	sar    $0x3,%edx
f010199f:	c1 e2 0c             	shl    $0xc,%edx
f01019a2:	39 d0                	cmp    %edx,%eax
f01019a4:	74 19                	je     f01019bf <mem_init+0xa1c>
f01019a6:	68 68 51 10 f0       	push   $0xf0105168
f01019ab:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01019b0:	68 81 03 00 00       	push   $0x381
f01019b5:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01019ba:	e8 e1 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01019bf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019c4:	74 19                	je     f01019df <mem_init+0xa3c>
f01019c6:	68 a0 4d 10 f0       	push   $0xf0104da0
f01019cb:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01019d0:	68 82 03 00 00       	push   $0x382
f01019d5:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01019da:	e8 c1 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01019df:	83 ec 04             	sub    $0x4,%esp
f01019e2:	6a 00                	push   $0x0
f01019e4:	68 00 10 00 00       	push   $0x1000
f01019e9:	57                   	push   %edi
f01019ea:	e8 ae f3 ff ff       	call   f0100d9d <pgdir_walk>
f01019ef:	83 c4 10             	add    $0x10,%esp
f01019f2:	f6 00 04             	testb  $0x4,(%eax)
f01019f5:	75 19                	jne    f0101a10 <mem_init+0xa6d>
f01019f7:	68 18 52 10 f0       	push   $0xf0105218
f01019fc:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101a01:	68 83 03 00 00       	push   $0x383
f0101a06:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101a0b:	e8 90 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a10:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101a15:	f6 00 04             	testb  $0x4,(%eax)
f0101a18:	75 19                	jne    f0101a33 <mem_init+0xa90>
f0101a1a:	68 b1 4d 10 f0       	push   $0xf0104db1
f0101a1f:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101a24:	68 84 03 00 00       	push   $0x384
f0101a29:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101a2e:	e8 6d e6 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a33:	6a 02                	push   $0x2
f0101a35:	68 00 10 00 00       	push   $0x1000
f0101a3a:	56                   	push   %esi
f0101a3b:	50                   	push   %eax
f0101a3c:	e8 ea f4 ff ff       	call   f0100f2b <page_insert>
f0101a41:	83 c4 10             	add    $0x10,%esp
f0101a44:	85 c0                	test   %eax,%eax
f0101a46:	74 19                	je     f0101a61 <mem_init+0xabe>
f0101a48:	68 2c 51 10 f0       	push   $0xf010512c
f0101a4d:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101a52:	68 87 03 00 00       	push   $0x387
f0101a57:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101a5c:	e8 3f e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a61:	83 ec 04             	sub    $0x4,%esp
f0101a64:	6a 00                	push   $0x0
f0101a66:	68 00 10 00 00       	push   $0x1000
f0101a6b:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a71:	e8 27 f3 ff ff       	call   f0100d9d <pgdir_walk>
f0101a76:	83 c4 10             	add    $0x10,%esp
f0101a79:	f6 00 02             	testb  $0x2,(%eax)
f0101a7c:	75 19                	jne    f0101a97 <mem_init+0xaf4>
f0101a7e:	68 4c 52 10 f0       	push   $0xf010524c
f0101a83:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101a88:	68 88 03 00 00       	push   $0x388
f0101a8d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101a92:	e8 09 e6 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a97:	83 ec 04             	sub    $0x4,%esp
f0101a9a:	6a 00                	push   $0x0
f0101a9c:	68 00 10 00 00       	push   $0x1000
f0101aa1:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101aa7:	e8 f1 f2 ff ff       	call   f0100d9d <pgdir_walk>
f0101aac:	83 c4 10             	add    $0x10,%esp
f0101aaf:	f6 00 04             	testb  $0x4,(%eax)
f0101ab2:	74 19                	je     f0101acd <mem_init+0xb2a>
f0101ab4:	68 80 52 10 f0       	push   $0xf0105280
f0101ab9:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101abe:	68 89 03 00 00       	push   $0x389
f0101ac3:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101ac8:	e8 d3 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101acd:	6a 02                	push   $0x2
f0101acf:	68 00 00 40 00       	push   $0x400000
f0101ad4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ad7:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101add:	e8 49 f4 ff ff       	call   f0100f2b <page_insert>
f0101ae2:	83 c4 10             	add    $0x10,%esp
f0101ae5:	85 c0                	test   %eax,%eax
f0101ae7:	78 19                	js     f0101b02 <mem_init+0xb5f>
f0101ae9:	68 b8 52 10 f0       	push   $0xf01052b8
f0101aee:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101af3:	68 8c 03 00 00       	push   $0x38c
f0101af8:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101afd:	e8 9e e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b02:	6a 02                	push   $0x2
f0101b04:	68 00 10 00 00       	push   $0x1000
f0101b09:	53                   	push   %ebx
f0101b0a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101b10:	e8 16 f4 ff ff       	call   f0100f2b <page_insert>
f0101b15:	83 c4 10             	add    $0x10,%esp
f0101b18:	85 c0                	test   %eax,%eax
f0101b1a:	74 19                	je     f0101b35 <mem_init+0xb92>
f0101b1c:	68 f0 52 10 f0       	push   $0xf01052f0
f0101b21:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101b26:	68 8f 03 00 00       	push   $0x38f
f0101b2b:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101b30:	e8 6b e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b35:	83 ec 04             	sub    $0x4,%esp
f0101b38:	6a 00                	push   $0x0
f0101b3a:	68 00 10 00 00       	push   $0x1000
f0101b3f:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101b45:	e8 53 f2 ff ff       	call   f0100d9d <pgdir_walk>
f0101b4a:	83 c4 10             	add    $0x10,%esp
f0101b4d:	f6 00 04             	testb  $0x4,(%eax)
f0101b50:	74 19                	je     f0101b6b <mem_init+0xbc8>
f0101b52:	68 80 52 10 f0       	push   $0xf0105280
f0101b57:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101b5c:	68 90 03 00 00       	push   $0x390
f0101b61:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101b66:	e8 35 e5 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b6b:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101b71:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b76:	89 f8                	mov    %edi,%eax
f0101b78:	e8 6a ed ff ff       	call   f01008e7 <check_va2pa>
f0101b7d:	89 c1                	mov    %eax,%ecx
f0101b7f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b82:	89 d8                	mov    %ebx,%eax
f0101b84:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101b8a:	c1 f8 03             	sar    $0x3,%eax
f0101b8d:	c1 e0 0c             	shl    $0xc,%eax
f0101b90:	39 c1                	cmp    %eax,%ecx
f0101b92:	74 19                	je     f0101bad <mem_init+0xc0a>
f0101b94:	68 2c 53 10 f0       	push   $0xf010532c
f0101b99:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101b9e:	68 93 03 00 00       	push   $0x393
f0101ba3:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101ba8:	e8 f3 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bad:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bb2:	89 f8                	mov    %edi,%eax
f0101bb4:	e8 2e ed ff ff       	call   f01008e7 <check_va2pa>
f0101bb9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bbc:	74 19                	je     f0101bd7 <mem_init+0xc34>
f0101bbe:	68 58 53 10 f0       	push   $0xf0105358
f0101bc3:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101bc8:	68 94 03 00 00       	push   $0x394
f0101bcd:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101bd2:	e8 c9 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101bd7:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101bdc:	74 19                	je     f0101bf7 <mem_init+0xc54>
f0101bde:	68 c7 4d 10 f0       	push   $0xf0104dc7
f0101be3:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101be8:	68 96 03 00 00       	push   $0x396
f0101bed:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101bf2:	e8 a9 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101bf7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101bfc:	74 19                	je     f0101c17 <mem_init+0xc74>
f0101bfe:	68 d8 4d 10 f0       	push   $0xf0104dd8
f0101c03:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101c08:	68 97 03 00 00       	push   $0x397
f0101c0d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101c12:	e8 89 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c17:	83 ec 0c             	sub    $0xc,%esp
f0101c1a:	6a 00                	push   $0x0
f0101c1c:	e8 88 f0 ff ff       	call   f0100ca9 <page_alloc>
f0101c21:	83 c4 10             	add    $0x10,%esp
f0101c24:	85 c0                	test   %eax,%eax
f0101c26:	74 04                	je     f0101c2c <mem_init+0xc89>
f0101c28:	39 c6                	cmp    %eax,%esi
f0101c2a:	74 19                	je     f0101c45 <mem_init+0xca2>
f0101c2c:	68 88 53 10 f0       	push   $0xf0105388
f0101c31:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101c36:	68 9a 03 00 00       	push   $0x39a
f0101c3b:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101c40:	e8 5b e4 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c45:	83 ec 08             	sub    $0x8,%esp
f0101c48:	6a 00                	push   $0x0
f0101c4a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101c50:	e8 94 f2 ff ff       	call   f0100ee9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c55:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101c5b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c60:	89 f8                	mov    %edi,%eax
f0101c62:	e8 80 ec ff ff       	call   f01008e7 <check_va2pa>
f0101c67:	83 c4 10             	add    $0x10,%esp
f0101c6a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c6d:	74 19                	je     f0101c88 <mem_init+0xce5>
f0101c6f:	68 ac 53 10 f0       	push   $0xf01053ac
f0101c74:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101c79:	68 9e 03 00 00       	push   $0x39e
f0101c7e:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101c83:	e8 18 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c88:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c8d:	89 f8                	mov    %edi,%eax
f0101c8f:	e8 53 ec ff ff       	call   f01008e7 <check_va2pa>
f0101c94:	89 da                	mov    %ebx,%edx
f0101c96:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101c9c:	c1 fa 03             	sar    $0x3,%edx
f0101c9f:	c1 e2 0c             	shl    $0xc,%edx
f0101ca2:	39 d0                	cmp    %edx,%eax
f0101ca4:	74 19                	je     f0101cbf <mem_init+0xd1c>
f0101ca6:	68 58 53 10 f0       	push   $0xf0105358
f0101cab:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101cb0:	68 9f 03 00 00       	push   $0x39f
f0101cb5:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101cba:	e8 e1 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101cbf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xd3c>
f0101cc6:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0101ccb:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101cd0:	68 a0 03 00 00       	push   $0x3a0
f0101cd5:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101cda:	e8 c1 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101cdf:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ce4:	74 19                	je     f0101cff <mem_init+0xd5c>
f0101ce6:	68 d8 4d 10 f0       	push   $0xf0104dd8
f0101ceb:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101cf0:	68 a1 03 00 00       	push   $0x3a1
f0101cf5:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101cfa:	e8 a1 e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101cff:	6a 00                	push   $0x0
f0101d01:	68 00 10 00 00       	push   $0x1000
f0101d06:	53                   	push   %ebx
f0101d07:	57                   	push   %edi
f0101d08:	e8 1e f2 ff ff       	call   f0100f2b <page_insert>
f0101d0d:	83 c4 10             	add    $0x10,%esp
f0101d10:	85 c0                	test   %eax,%eax
f0101d12:	74 19                	je     f0101d2d <mem_init+0xd8a>
f0101d14:	68 d0 53 10 f0       	push   $0xf01053d0
f0101d19:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101d1e:	68 a4 03 00 00       	push   $0x3a4
f0101d23:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101d28:	e8 73 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101d2d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d32:	75 19                	jne    f0101d4d <mem_init+0xdaa>
f0101d34:	68 e9 4d 10 f0       	push   $0xf0104de9
f0101d39:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101d3e:	68 a5 03 00 00       	push   $0x3a5
f0101d43:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101d48:	e8 53 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101d4d:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d50:	74 19                	je     f0101d6b <mem_init+0xdc8>
f0101d52:	68 f5 4d 10 f0       	push   $0xf0104df5
f0101d57:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101d5c:	68 a6 03 00 00       	push   $0x3a6
f0101d61:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101d66:	e8 35 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d6b:	83 ec 08             	sub    $0x8,%esp
f0101d6e:	68 00 10 00 00       	push   $0x1000
f0101d73:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101d79:	e8 6b f1 ff ff       	call   f0100ee9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d7e:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101d84:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d89:	89 f8                	mov    %edi,%eax
f0101d8b:	e8 57 eb ff ff       	call   f01008e7 <check_va2pa>
f0101d90:	83 c4 10             	add    $0x10,%esp
f0101d93:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d96:	74 19                	je     f0101db1 <mem_init+0xe0e>
f0101d98:	68 ac 53 10 f0       	push   $0xf01053ac
f0101d9d:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101da2:	68 aa 03 00 00       	push   $0x3aa
f0101da7:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101dac:	e8 ef e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101db1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101db6:	89 f8                	mov    %edi,%eax
f0101db8:	e8 2a eb ff ff       	call   f01008e7 <check_va2pa>
f0101dbd:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dc0:	74 19                	je     f0101ddb <mem_init+0xe38>
f0101dc2:	68 08 54 10 f0       	push   $0xf0105408
f0101dc7:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101dcc:	68 ab 03 00 00       	push   $0x3ab
f0101dd1:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101dd6:	e8 c5 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101ddb:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101de0:	74 19                	je     f0101dfb <mem_init+0xe58>
f0101de2:	68 0a 4e 10 f0       	push   $0xf0104e0a
f0101de7:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101dec:	68 ac 03 00 00       	push   $0x3ac
f0101df1:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101df6:	e8 a5 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101dfb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e00:	74 19                	je     f0101e1b <mem_init+0xe78>
f0101e02:	68 d8 4d 10 f0       	push   $0xf0104dd8
f0101e07:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101e0c:	68 ad 03 00 00       	push   $0x3ad
f0101e11:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101e16:	e8 85 e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e1b:	83 ec 0c             	sub    $0xc,%esp
f0101e1e:	6a 00                	push   $0x0
f0101e20:	e8 84 ee ff ff       	call   f0100ca9 <page_alloc>
f0101e25:	83 c4 10             	add    $0x10,%esp
f0101e28:	39 c3                	cmp    %eax,%ebx
f0101e2a:	75 04                	jne    f0101e30 <mem_init+0xe8d>
f0101e2c:	85 c0                	test   %eax,%eax
f0101e2e:	75 19                	jne    f0101e49 <mem_init+0xea6>
f0101e30:	68 30 54 10 f0       	push   $0xf0105430
f0101e35:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101e3a:	68 b0 03 00 00       	push   $0x3b0
f0101e3f:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101e44:	e8 57 e2 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e49:	83 ec 0c             	sub    $0xc,%esp
f0101e4c:	6a 00                	push   $0x0
f0101e4e:	e8 56 ee ff ff       	call   f0100ca9 <page_alloc>
f0101e53:	83 c4 10             	add    $0x10,%esp
f0101e56:	85 c0                	test   %eax,%eax
f0101e58:	74 19                	je     f0101e73 <mem_init+0xed0>
f0101e5a:	68 2c 4d 10 f0       	push   $0xf0104d2c
f0101e5f:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101e64:	68 b3 03 00 00       	push   $0x3b3
f0101e69:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101e6e:	e8 2d e2 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e73:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0101e79:	8b 11                	mov    (%ecx),%edx
f0101e7b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e81:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e84:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101e8a:	c1 f8 03             	sar    $0x3,%eax
f0101e8d:	c1 e0 0c             	shl    $0xc,%eax
f0101e90:	39 c2                	cmp    %eax,%edx
f0101e92:	74 19                	je     f0101ead <mem_init+0xf0a>
f0101e94:	68 d4 50 10 f0       	push   $0xf01050d4
f0101e99:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101e9e:	68 b6 03 00 00       	push   $0x3b6
f0101ea3:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101ea8:	e8 f3 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101ead:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eb3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eb6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ebb:	74 19                	je     f0101ed6 <mem_init+0xf33>
f0101ebd:	68 8f 4d 10 f0       	push   $0xf0104d8f
f0101ec2:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101ec7:	68 b8 03 00 00       	push   $0x3b8
f0101ecc:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101ed1:	e8 ca e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101ed6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ed9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101edf:	83 ec 0c             	sub    $0xc,%esp
f0101ee2:	50                   	push   %eax
f0101ee3:	e8 38 ee ff ff       	call   f0100d20 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ee8:	83 c4 0c             	add    $0xc,%esp
f0101eeb:	6a 01                	push   $0x1
f0101eed:	68 00 10 40 00       	push   $0x401000
f0101ef2:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101ef8:	e8 a0 ee ff ff       	call   f0100d9d <pgdir_walk>
f0101efd:	89 c7                	mov    %eax,%edi
f0101eff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f02:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101f07:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f0a:	8b 40 04             	mov    0x4(%eax),%eax
f0101f0d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f12:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f0101f18:	89 c2                	mov    %eax,%edx
f0101f1a:	c1 ea 0c             	shr    $0xc,%edx
f0101f1d:	83 c4 10             	add    $0x10,%esp
f0101f20:	39 ca                	cmp    %ecx,%edx
f0101f22:	72 15                	jb     f0101f39 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f24:	50                   	push   %eax
f0101f25:	68 94 4e 10 f0       	push   $0xf0104e94
f0101f2a:	68 bf 03 00 00       	push   $0x3bf
f0101f2f:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101f34:	e8 67 e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f39:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f3e:	39 c7                	cmp    %eax,%edi
f0101f40:	74 19                	je     f0101f5b <mem_init+0xfb8>
f0101f42:	68 1b 4e 10 f0       	push   $0xf0104e1b
f0101f47:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0101f4c:	68 c0 03 00 00       	push   $0x3c0
f0101f51:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0101f56:	e8 45 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f5b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f5e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f68:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f6e:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101f74:	c1 f8 03             	sar    $0x3,%eax
f0101f77:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f7a:	89 c2                	mov    %eax,%edx
f0101f7c:	c1 ea 0c             	shr    $0xc,%edx
f0101f7f:	39 d1                	cmp    %edx,%ecx
f0101f81:	77 12                	ja     f0101f95 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f83:	50                   	push   %eax
f0101f84:	68 94 4e 10 f0       	push   $0xf0104e94
f0101f89:	6a 5c                	push   $0x5c
f0101f8b:	68 98 4b 10 f0       	push   $0xf0104b98
f0101f90:	e8 0b e1 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f95:	83 ec 04             	sub    $0x4,%esp
f0101f98:	68 00 10 00 00       	push   $0x1000
f0101f9d:	68 ff 00 00 00       	push   $0xff
f0101fa2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fa7:	50                   	push   %eax
f0101fa8:	e8 88 22 00 00       	call   f0104235 <memset>
	page_free(pp0);
f0101fad:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fb0:	89 3c 24             	mov    %edi,(%esp)
f0101fb3:	e8 68 ed ff ff       	call   f0100d20 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fb8:	83 c4 0c             	add    $0xc,%esp
f0101fbb:	6a 01                	push   $0x1
f0101fbd:	6a 00                	push   $0x0
f0101fbf:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101fc5:	e8 d3 ed ff ff       	call   f0100d9d <pgdir_walk>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fca:	89 fa                	mov    %edi,%edx
f0101fcc:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101fd2:	c1 fa 03             	sar    $0x3,%edx
f0101fd5:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fd8:	89 d0                	mov    %edx,%eax
f0101fda:	c1 e8 0c             	shr    $0xc,%eax
f0101fdd:	83 c4 10             	add    $0x10,%esp
f0101fe0:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0101fe6:	72 12                	jb     f0101ffa <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe8:	52                   	push   %edx
f0101fe9:	68 94 4e 10 f0       	push   $0xf0104e94
f0101fee:	6a 5c                	push   $0x5c
f0101ff0:	68 98 4b 10 f0       	push   $0xf0104b98
f0101ff5:	e8 a6 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0101ffa:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102000:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102003:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102009:	f6 00 01             	testb  $0x1,(%eax)
f010200c:	74 19                	je     f0102027 <mem_init+0x1084>
f010200e:	68 33 4e 10 f0       	push   $0xf0104e33
f0102013:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102018:	68 ca 03 00 00       	push   $0x3ca
f010201d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102022:	e8 79 e0 ff ff       	call   f01000a0 <_panic>
f0102027:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010202a:	39 c2                	cmp    %eax,%edx
f010202c:	75 db                	jne    f0102009 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010202e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102033:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102039:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010203c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102042:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102045:	89 3d 40 be 17 f0    	mov    %edi,0xf017be40

	// free the pages we took
	page_free(pp0);
f010204b:	83 ec 0c             	sub    $0xc,%esp
f010204e:	50                   	push   %eax
f010204f:	e8 cc ec ff ff       	call   f0100d20 <page_free>
	page_free(pp1);
f0102054:	89 1c 24             	mov    %ebx,(%esp)
f0102057:	e8 c4 ec ff ff       	call   f0100d20 <page_free>
	page_free(pp2);
f010205c:	89 34 24             	mov    %esi,(%esp)
f010205f:	e8 bc ec ff ff       	call   f0100d20 <page_free>

	cprintf("check_page() succeeded!\n");
f0102064:	c7 04 24 4a 4e 10 f0 	movl   $0xf0104e4a,(%esp)
f010206b:	e8 5d 0e 00 00       	call   f0102ecd <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102070:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102075:	83 c4 10             	add    $0x10,%esp
f0102078:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010207d:	77 15                	ja     f0102094 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010207f:	50                   	push   %eax
f0102080:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0102085:	68 b8 00 00 00       	push   $0xb8
f010208a:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010208f:	e8 0c e0 ff ff       	call   f01000a0 <_panic>
f0102094:	83 ec 08             	sub    $0x8,%esp
f0102097:	6a 04                	push   $0x4
f0102099:	05 00 00 00 10       	add    $0x10000000,%eax
f010209e:	50                   	push   %eax
f010209f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020a4:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020a9:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020ae:	e8 7d ed ff ff       	call   f0100e30 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);	
f01020b3:	a1 4c be 17 f0       	mov    0xf017be4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020b8:	83 c4 10             	add    $0x10,%esp
f01020bb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020c0:	77 15                	ja     f01020d7 <mem_init+0x1134>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020c2:	50                   	push   %eax
f01020c3:	68 d8 4f 10 f0       	push   $0xf0104fd8
f01020c8:	68 c1 00 00 00       	push   $0xc1
f01020cd:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01020d2:	e8 c9 df ff ff       	call   f01000a0 <_panic>
f01020d7:	83 ec 08             	sub    $0x8,%esp
f01020da:	6a 04                	push   $0x4
f01020dc:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e1:	50                   	push   %eax
f01020e2:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020e7:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01020ec:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020f1:	e8 3a ed ff ff       	call   f0100e30 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020f6:	83 c4 10             	add    $0x10,%esp
f01020f9:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01020fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102103:	77 15                	ja     f010211a <mem_init+0x1177>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102105:	50                   	push   %eax
f0102106:	68 d8 4f 10 f0       	push   $0xf0104fd8
f010210b:	68 ce 00 00 00       	push   $0xce
f0102110:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102115:	e8 86 df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010211a:	83 ec 08             	sub    $0x8,%esp
f010211d:	6a 02                	push   $0x2
f010211f:	68 00 00 11 00       	push   $0x110000
f0102124:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102129:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010212e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102133:	e8 f8 ec ff ff       	call   f0100e30 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f0102138:	83 c4 08             	add    $0x8,%esp
f010213b:	6a 02                	push   $0x2
f010213d:	6a 00                	push   $0x0
f010213f:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102144:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102149:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f010214e:	e8 dd ec ff ff       	call   f0100e30 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102153:	8b 1d 08 cb 17 f0    	mov    0xf017cb08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102159:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f010215e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102161:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102168:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010216d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102170:	8b 3d 0c cb 17 f0    	mov    0xf017cb0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102176:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102179:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010217c:	be 00 00 00 00       	mov    $0x0,%esi
f0102181:	eb 55                	jmp    f01021d8 <mem_init+0x1235>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102183:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102189:	89 d8                	mov    %ebx,%eax
f010218b:	e8 57 e7 ff ff       	call   f01008e7 <check_va2pa>
f0102190:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102197:	77 15                	ja     f01021ae <mem_init+0x120b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102199:	57                   	push   %edi
f010219a:	68 d8 4f 10 f0       	push   $0xf0104fd8
f010219f:	68 07 03 00 00       	push   $0x307
f01021a4:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01021a9:	e8 f2 de ff ff       	call   f01000a0 <_panic>
f01021ae:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01021b5:	39 d0                	cmp    %edx,%eax
f01021b7:	74 19                	je     f01021d2 <mem_init+0x122f>
f01021b9:	68 54 54 10 f0       	push   $0xf0105454
f01021be:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01021c3:	68 07 03 00 00       	push   $0x307
f01021c8:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01021cd:	e8 ce de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021d2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01021d8:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01021db:	77 a6                	ja     f0102183 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01021dd:	8b 3d 4c be 17 f0    	mov    0xf017be4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021e3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01021e6:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01021eb:	89 f2                	mov    %esi,%edx
f01021ed:	89 d8                	mov    %ebx,%eax
f01021ef:	e8 f3 e6 ff ff       	call   f01008e7 <check_va2pa>
f01021f4:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01021fb:	77 15                	ja     f0102212 <mem_init+0x126f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021fd:	57                   	push   %edi
f01021fe:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0102203:	68 0c 03 00 00       	push   $0x30c
f0102208:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010220d:	e8 8e de ff ff       	call   f01000a0 <_panic>
f0102212:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102219:	39 c2                	cmp    %eax,%edx
f010221b:	74 19                	je     f0102236 <mem_init+0x1293>
f010221d:	68 88 54 10 f0       	push   $0xf0105488
f0102222:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102227:	68 0c 03 00 00       	push   $0x30c
f010222c:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102231:	e8 6a de ff ff       	call   f01000a0 <_panic>
f0102236:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010223c:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102242:	75 a7                	jne    f01021eb <mem_init+0x1248>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102244:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102247:	c1 e7 0c             	shl    $0xc,%edi
f010224a:	be 00 00 00 00       	mov    $0x0,%esi
f010224f:	eb 30                	jmp    f0102281 <mem_init+0x12de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102251:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102257:	89 d8                	mov    %ebx,%eax
f0102259:	e8 89 e6 ff ff       	call   f01008e7 <check_va2pa>
f010225e:	39 c6                	cmp    %eax,%esi
f0102260:	74 19                	je     f010227b <mem_init+0x12d8>
f0102262:	68 bc 54 10 f0       	push   $0xf01054bc
f0102267:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010226c:	68 10 03 00 00       	push   $0x310
f0102271:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102276:	e8 25 de ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010227b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102281:	39 fe                	cmp    %edi,%esi
f0102283:	72 cc                	jb     f0102251 <mem_init+0x12ae>
f0102285:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010228a:	89 f2                	mov    %esi,%edx
f010228c:	89 d8                	mov    %ebx,%eax
f010228e:	e8 54 e6 ff ff       	call   f01008e7 <check_va2pa>
f0102293:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f0102299:	39 c2                	cmp    %eax,%edx
f010229b:	74 19                	je     f01022b6 <mem_init+0x1313>
f010229d:	68 e4 54 10 f0       	push   $0xf01054e4
f01022a2:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01022a7:	68 14 03 00 00       	push   $0x314
f01022ac:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01022b1:	e8 ea dd ff ff       	call   f01000a0 <_panic>
f01022b6:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022bc:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01022c2:	75 c6                	jne    f010228a <mem_init+0x12e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022c4:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022c9:	89 d8                	mov    %ebx,%eax
f01022cb:	e8 17 e6 ff ff       	call   f01008e7 <check_va2pa>
f01022d0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022d3:	74 51                	je     f0102326 <mem_init+0x1383>
f01022d5:	68 2c 55 10 f0       	push   $0xf010552c
f01022da:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01022df:	68 15 03 00 00       	push   $0x315
f01022e4:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01022e9:	e8 b2 dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022ee:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01022f3:	72 36                	jb     f010232b <mem_init+0x1388>
f01022f5:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022fa:	76 07                	jbe    f0102303 <mem_init+0x1360>
f01022fc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102301:	75 28                	jne    f010232b <mem_init+0x1388>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102303:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102307:	0f 85 83 00 00 00    	jne    f0102390 <mem_init+0x13ed>
f010230d:	68 63 4e 10 f0       	push   $0xf0104e63
f0102312:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102317:	68 1e 03 00 00       	push   $0x31e
f010231c:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102321:	e8 7a dd ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102326:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010232b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102330:	76 3f                	jbe    f0102371 <mem_init+0x13ce>
				assert(pgdir[i] & PTE_P);
f0102332:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102335:	f6 c2 01             	test   $0x1,%dl
f0102338:	75 19                	jne    f0102353 <mem_init+0x13b0>
f010233a:	68 63 4e 10 f0       	push   $0xf0104e63
f010233f:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102344:	68 22 03 00 00       	push   $0x322
f0102349:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010234e:	e8 4d dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102353:	f6 c2 02             	test   $0x2,%dl
f0102356:	75 38                	jne    f0102390 <mem_init+0x13ed>
f0102358:	68 74 4e 10 f0       	push   $0xf0104e74
f010235d:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102362:	68 23 03 00 00       	push   $0x323
f0102367:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010236c:	e8 2f dd ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102371:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102375:	74 19                	je     f0102390 <mem_init+0x13ed>
f0102377:	68 85 4e 10 f0       	push   $0xf0104e85
f010237c:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102381:	68 25 03 00 00       	push   $0x325
f0102386:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010238b:	e8 10 dd ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102390:	83 c0 01             	add    $0x1,%eax
f0102393:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102398:	0f 86 50 ff ff ff    	jbe    f01022ee <mem_init+0x134b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010239e:	83 ec 0c             	sub    $0xc,%esp
f01023a1:	68 5c 55 10 f0       	push   $0xf010555c
f01023a6:	e8 22 0b 00 00       	call   f0102ecd <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023ab:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023b0:	83 c4 10             	add    $0x10,%esp
f01023b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023b8:	77 15                	ja     f01023cf <mem_init+0x142c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023ba:	50                   	push   %eax
f01023bb:	68 d8 4f 10 f0       	push   $0xf0104fd8
f01023c0:	68 e5 00 00 00       	push   $0xe5
f01023c5:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01023ca:	e8 d1 dc ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01023cf:	05 00 00 00 10       	add    $0x10000000,%eax
f01023d4:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01023dc:	e8 6a e5 ff ff       	call   f010094b <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01023e1:	0f 20 c0             	mov    %cr0,%eax
f01023e4:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01023e7:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023ec:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023ef:	83 ec 0c             	sub    $0xc,%esp
f01023f2:	6a 00                	push   $0x0
f01023f4:	e8 b0 e8 ff ff       	call   f0100ca9 <page_alloc>
f01023f9:	89 c3                	mov    %eax,%ebx
f01023fb:	83 c4 10             	add    $0x10,%esp
f01023fe:	85 c0                	test   %eax,%eax
f0102400:	75 19                	jne    f010241b <mem_init+0x1478>
f0102402:	68 81 4c 10 f0       	push   $0xf0104c81
f0102407:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010240c:	68 e5 03 00 00       	push   $0x3e5
f0102411:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102416:	e8 85 dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010241b:	83 ec 0c             	sub    $0xc,%esp
f010241e:	6a 00                	push   $0x0
f0102420:	e8 84 e8 ff ff       	call   f0100ca9 <page_alloc>
f0102425:	89 c7                	mov    %eax,%edi
f0102427:	83 c4 10             	add    $0x10,%esp
f010242a:	85 c0                	test   %eax,%eax
f010242c:	75 19                	jne    f0102447 <mem_init+0x14a4>
f010242e:	68 97 4c 10 f0       	push   $0xf0104c97
f0102433:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102438:	68 e6 03 00 00       	push   $0x3e6
f010243d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102442:	e8 59 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102447:	83 ec 0c             	sub    $0xc,%esp
f010244a:	6a 00                	push   $0x0
f010244c:	e8 58 e8 ff ff       	call   f0100ca9 <page_alloc>
f0102451:	89 c6                	mov    %eax,%esi
f0102453:	83 c4 10             	add    $0x10,%esp
f0102456:	85 c0                	test   %eax,%eax
f0102458:	75 19                	jne    f0102473 <mem_init+0x14d0>
f010245a:	68 ad 4c 10 f0       	push   $0xf0104cad
f010245f:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102464:	68 e7 03 00 00       	push   $0x3e7
f0102469:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010246e:	e8 2d dc ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102473:	83 ec 0c             	sub    $0xc,%esp
f0102476:	53                   	push   %ebx
f0102477:	e8 a4 e8 ff ff       	call   f0100d20 <page_free>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010247c:	89 f8                	mov    %edi,%eax
f010247e:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102484:	c1 f8 03             	sar    $0x3,%eax
f0102487:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010248a:	89 c2                	mov    %eax,%edx
f010248c:	c1 ea 0c             	shr    $0xc,%edx
f010248f:	83 c4 10             	add    $0x10,%esp
f0102492:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102498:	72 12                	jb     f01024ac <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010249a:	50                   	push   %eax
f010249b:	68 94 4e 10 f0       	push   $0xf0104e94
f01024a0:	6a 5c                	push   $0x5c
f01024a2:	68 98 4b 10 f0       	push   $0xf0104b98
f01024a7:	e8 f4 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024ac:	83 ec 04             	sub    $0x4,%esp
f01024af:	68 00 10 00 00       	push   $0x1000
f01024b4:	6a 01                	push   $0x1
f01024b6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024bb:	50                   	push   %eax
f01024bc:	e8 74 1d 00 00       	call   f0104235 <memset>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c1:	89 f0                	mov    %esi,%eax
f01024c3:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01024c9:	c1 f8 03             	sar    $0x3,%eax
f01024cc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024cf:	89 c2                	mov    %eax,%edx
f01024d1:	c1 ea 0c             	shr    $0xc,%edx
f01024d4:	83 c4 10             	add    $0x10,%esp
f01024d7:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01024dd:	72 12                	jb     f01024f1 <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024df:	50                   	push   %eax
f01024e0:	68 94 4e 10 f0       	push   $0xf0104e94
f01024e5:	6a 5c                	push   $0x5c
f01024e7:	68 98 4b 10 f0       	push   $0xf0104b98
f01024ec:	e8 af db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024f1:	83 ec 04             	sub    $0x4,%esp
f01024f4:	68 00 10 00 00       	push   $0x1000
f01024f9:	6a 02                	push   $0x2
f01024fb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102500:	50                   	push   %eax
f0102501:	e8 2f 1d 00 00       	call   f0104235 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102506:	6a 02                	push   $0x2
f0102508:	68 00 10 00 00       	push   $0x1000
f010250d:	57                   	push   %edi
f010250e:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102514:	e8 12 ea ff ff       	call   f0100f2b <page_insert>
	assert(pp1->pp_ref == 1);
f0102519:	83 c4 20             	add    $0x20,%esp
f010251c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102521:	74 19                	je     f010253c <mem_init+0x1599>
f0102523:	68 7e 4d 10 f0       	push   $0xf0104d7e
f0102528:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010252d:	68 ec 03 00 00       	push   $0x3ec
f0102532:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102537:	e8 64 db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010253c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102543:	01 01 01 
f0102546:	74 19                	je     f0102561 <mem_init+0x15be>
f0102548:	68 7c 55 10 f0       	push   $0xf010557c
f010254d:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102552:	68 ed 03 00 00       	push   $0x3ed
f0102557:	68 8c 4b 10 f0       	push   $0xf0104b8c
f010255c:	e8 3f db ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102561:	6a 02                	push   $0x2
f0102563:	68 00 10 00 00       	push   $0x1000
f0102568:	56                   	push   %esi
f0102569:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010256f:	e8 b7 e9 ff ff       	call   f0100f2b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102574:	83 c4 10             	add    $0x10,%esp
f0102577:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010257e:	02 02 02 
f0102581:	74 19                	je     f010259c <mem_init+0x15f9>
f0102583:	68 a0 55 10 f0       	push   $0xf01055a0
f0102588:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010258d:	68 ef 03 00 00       	push   $0x3ef
f0102592:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102597:	e8 04 db ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010259c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025a1:	74 19                	je     f01025bc <mem_init+0x1619>
f01025a3:	68 a0 4d 10 f0       	push   $0xf0104da0
f01025a8:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01025ad:	68 f0 03 00 00       	push   $0x3f0
f01025b2:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01025b7:	e8 e4 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01025bc:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025c1:	74 19                	je     f01025dc <mem_init+0x1639>
f01025c3:	68 0a 4e 10 f0       	push   $0xf0104e0a
f01025c8:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01025cd:	68 f1 03 00 00       	push   $0x3f1
f01025d2:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01025d7:	e8 c4 da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025dc:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025e3:	03 03 03 


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025e6:	89 f0                	mov    %esi,%eax
f01025e8:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01025ee:	c1 f8 03             	sar    $0x3,%eax
f01025f1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025f4:	89 c2                	mov    %eax,%edx
f01025f6:	c1 ea 0c             	shr    $0xc,%edx
f01025f9:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01025ff:	72 12                	jb     f0102613 <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102601:	50                   	push   %eax
f0102602:	68 94 4e 10 f0       	push   $0xf0104e94
f0102607:	6a 5c                	push   $0x5c
f0102609:	68 98 4b 10 f0       	push   $0xf0104b98
f010260e:	e8 8d da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102613:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010261a:	03 03 03 
f010261d:	74 19                	je     f0102638 <mem_init+0x1695>
f010261f:	68 c4 55 10 f0       	push   $0xf01055c4
f0102624:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102629:	68 f3 03 00 00       	push   $0x3f3
f010262e:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102633:	e8 68 da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102638:	83 ec 08             	sub    $0x8,%esp
f010263b:	68 00 10 00 00       	push   $0x1000
f0102640:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102646:	e8 9e e8 ff ff       	call   f0100ee9 <page_remove>
	assert(pp2->pp_ref == 0);
f010264b:	83 c4 10             	add    $0x10,%esp
f010264e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102653:	74 19                	je     f010266e <mem_init+0x16cb>
f0102655:	68 d8 4d 10 f0       	push   $0xf0104dd8
f010265a:	68 b2 4b 10 f0       	push   $0xf0104bb2
f010265f:	68 f5 03 00 00       	push   $0x3f5
f0102664:	68 8c 4b 10 f0       	push   $0xf0104b8c
f0102669:	e8 32 da ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010266e:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0102674:	8b 11                	mov    (%ecx),%edx
f0102676:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010267c:	89 d8                	mov    %ebx,%eax
f010267e:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102684:	c1 f8 03             	sar    $0x3,%eax
f0102687:	c1 e0 0c             	shl    $0xc,%eax
f010268a:	39 c2                	cmp    %eax,%edx
f010268c:	74 19                	je     f01026a7 <mem_init+0x1704>
f010268e:	68 d4 50 10 f0       	push   $0xf01050d4
f0102693:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0102698:	68 f8 03 00 00       	push   $0x3f8
f010269d:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01026a2:	e8 f9 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01026a7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026ad:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026b2:	74 19                	je     f01026cd <mem_init+0x172a>
f01026b4:	68 8f 4d 10 f0       	push   $0xf0104d8f
f01026b9:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01026be:	68 fa 03 00 00       	push   $0x3fa
f01026c3:	68 8c 4b 10 f0       	push   $0xf0104b8c
f01026c8:	e8 d3 d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01026cd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026d3:	83 ec 0c             	sub    $0xc,%esp
f01026d6:	53                   	push   %ebx
f01026d7:	e8 44 e6 ff ff       	call   f0100d20 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026dc:	c7 04 24 f0 55 10 f0 	movl   $0xf01055f0,(%esp)
f01026e3:	e8 e5 07 00 00       	call   f0102ecd <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026e8:	83 c4 10             	add    $0x10,%esp
f01026eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026ee:	5b                   	pop    %ebx
f01026ef:	5e                   	pop    %esi
f01026f0:	5f                   	pop    %edi
f01026f1:	5d                   	pop    %ebp
f01026f2:	c3                   	ret    

f01026f3 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026f3:	55                   	push   %ebp
f01026f4:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026f9:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026fc:	5d                   	pop    %ebp
f01026fd:	c3                   	ret    

f01026fe <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01026fe:	55                   	push   %ebp
f01026ff:	89 e5                	mov    %esp,%ebp
f0102701:	57                   	push   %edi
f0102702:	56                   	push   %esi
f0102703:	53                   	push   %ebx
f0102704:	83 ec 1c             	sub    $0x1c,%esp
f0102707:	8b 7d 08             	mov    0x8(%ebp),%edi
f010270a:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	char * end = NULL;
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
f010270d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102710:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102715:	89 c3                	mov    %eax,%ebx
f0102717:	89 45 e0             	mov    %eax,-0x20(%ebp)
	end = ROUNDUP((char *)(va + len), PGSIZE);
f010271a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010271d:	03 45 10             	add    0x10(%ebp),%eax
f0102720:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102725:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010272a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f010272d:	eb 4e                	jmp    f010277d <user_mem_check+0x7f>
		cur = pgdir_walk(env->env_pgdir, (void *)start, 0);
f010272f:	83 ec 04             	sub    $0x4,%esp
f0102732:	6a 00                	push   $0x0
f0102734:	53                   	push   %ebx
f0102735:	ff 77 5c             	pushl  0x5c(%edi)
f0102738:	e8 60 e6 ff ff       	call   f0100d9d <pgdir_walk>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
f010273d:	89 da                	mov    %ebx,%edx
f010273f:	83 c4 10             	add    $0x10,%esp
f0102742:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f0102748:	77 0c                	ja     f0102756 <user_mem_check+0x58>
f010274a:	85 c0                	test   %eax,%eax
f010274c:	74 08                	je     f0102756 <user_mem_check+0x58>
f010274e:	89 f1                	mov    %esi,%ecx
f0102750:	23 08                	and    (%eax),%ecx
f0102752:	39 ce                	cmp    %ecx,%esi
f0102754:	74 21                	je     f0102777 <user_mem_check+0x79>
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
f0102756:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0102759:	75 0f                	jne    f010276a <user_mem_check+0x6c>
					user_mem_check_addr = (uintptr_t)va;
f010275b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010275e:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
			  }
			  return -E_FAULT;
f0102763:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102768:	eb 1d                	jmp    f0102787 <user_mem_check+0x89>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
					user_mem_check_addr = (uintptr_t)va;
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
f010276a:	89 15 3c be 17 f0    	mov    %edx,0xf017be3c
			  }
			  return -E_FAULT;
f0102770:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102775:	eb 10                	jmp    f0102787 <user_mem_check+0x89>
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
	end = ROUNDUP((char *)(va + len), PGSIZE);
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f0102777:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010277d:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102780:	72 ad                	jb     f010272f <user_mem_check+0x31>
			  return -E_FAULT;
		}
		
	}
		
	return 0;
f0102782:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102787:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010278a:	5b                   	pop    %ebx
f010278b:	5e                   	pop    %esi
f010278c:	5f                   	pop    %edi
f010278d:	5d                   	pop    %ebp
f010278e:	c3                   	ret    

f010278f <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010278f:	55                   	push   %ebp
f0102790:	89 e5                	mov    %esp,%ebp
f0102792:	53                   	push   %ebx
f0102793:	83 ec 04             	sub    $0x4,%esp
f0102796:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102799:	8b 45 14             	mov    0x14(%ebp),%eax
f010279c:	83 c8 04             	or     $0x4,%eax
f010279f:	50                   	push   %eax
f01027a0:	ff 75 10             	pushl  0x10(%ebp)
f01027a3:	ff 75 0c             	pushl  0xc(%ebp)
f01027a6:	53                   	push   %ebx
f01027a7:	e8 52 ff ff ff       	call   f01026fe <user_mem_check>
f01027ac:	83 c4 10             	add    $0x10,%esp
f01027af:	85 c0                	test   %eax,%eax
f01027b1:	79 21                	jns    f01027d4 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01027b3:	83 ec 04             	sub    $0x4,%esp
f01027b6:	ff 35 3c be 17 f0    	pushl  0xf017be3c
f01027bc:	ff 73 48             	pushl  0x48(%ebx)
f01027bf:	68 1c 56 10 f0       	push   $0xf010561c
f01027c4:	e8 04 07 00 00       	call   f0102ecd <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01027c9:	89 1c 24             	mov    %ebx,(%esp)
f01027cc:	e8 e3 05 00 00       	call   f0102db4 <env_destroy>
f01027d1:	83 c4 10             	add    $0x10,%esp
	}
}
f01027d4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01027d7:	c9                   	leave  
f01027d8:	c3                   	ret    

f01027d9 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01027d9:	55                   	push   %ebp
f01027da:	89 e5                	mov    %esp,%ebp
f01027dc:	57                   	push   %edi
f01027dd:	56                   	push   %esi
f01027de:	53                   	push   %ebx
f01027df:	83 ec 0c             	sub    $0xc,%esp
f01027e2:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
f01027e4:	89 d3                	mov    %edx,%ebx
f01027e6:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
f01027ec:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01027f3:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f01027f9:	eb 58                	jmp    f0102853 <region_alloc+0x7a>
		p = page_alloc(0);
f01027fb:	83 ec 0c             	sub    $0xc,%esp
f01027fe:	6a 00                	push   $0x0
f0102800:	e8 a4 e4 ff ff       	call   f0100ca9 <page_alloc>
		if(p == NULL)
f0102805:	83 c4 10             	add    $0x10,%esp
f0102808:	85 c0                	test   %eax,%eax
f010280a:	75 17                	jne    f0102823 <region_alloc+0x4a>
			panic(" region alloc, allocation failed.");
f010280c:	83 ec 04             	sub    $0x4,%esp
f010280f:	68 54 56 10 f0       	push   $0xf0105654
f0102814:	68 22 01 00 00       	push   $0x122
f0102819:	68 3e 57 10 f0       	push   $0xf010573e
f010281e:	e8 7d d8 ff ff       	call   f01000a0 <_panic>

		r = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
f0102823:	6a 06                	push   $0x6
f0102825:	53                   	push   %ebx
f0102826:	50                   	push   %eax
f0102827:	ff 77 5c             	pushl  0x5c(%edi)
f010282a:	e8 fc e6 ff ff       	call   f0100f2b <page_insert>
		if(r != 0) {
f010282f:	83 c4 10             	add    $0x10,%esp
f0102832:	85 c0                	test   %eax,%eax
f0102834:	74 17                	je     f010284d <region_alloc+0x74>
			panic("region alloc error");
f0102836:	83 ec 04             	sub    $0x4,%esp
f0102839:	68 49 57 10 f0       	push   $0xf0105749
f010283e:	68 26 01 00 00       	push   $0x126
f0102843:	68 3e 57 10 f0       	push   $0xf010573e
f0102848:	e8 53 d8 ff ff       	call   f01000a0 <_panic>
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f010284d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102853:	39 f3                	cmp    %esi,%ebx
f0102855:	72 a4                	jb     f01027fb <region_alloc+0x22>
	}
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f0102857:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010285a:	5b                   	pop    %ebx
f010285b:	5e                   	pop    %esi
f010285c:	5f                   	pop    %edi
f010285d:	5d                   	pop    %ebp
f010285e:	c3                   	ret    

f010285f <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010285f:	55                   	push   %ebp
f0102860:	89 e5                	mov    %esp,%ebp
f0102862:	8b 55 08             	mov    0x8(%ebp),%edx
f0102865:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102868:	85 d2                	test   %edx,%edx
f010286a:	75 11                	jne    f010287d <envid2env+0x1e>
		*env_store = curenv;
f010286c:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f0102871:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102874:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102876:	b8 00 00 00 00       	mov    $0x0,%eax
f010287b:	eb 5e                	jmp    f01028db <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010287d:	89 d0                	mov    %edx,%eax
f010287f:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102884:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102887:	c1 e0 05             	shl    $0x5,%eax
f010288a:	03 05 4c be 17 f0    	add    0xf017be4c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102890:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102894:	74 05                	je     f010289b <envid2env+0x3c>
f0102896:	3b 50 48             	cmp    0x48(%eax),%edx
f0102899:	74 10                	je     f01028ab <envid2env+0x4c>
		*env_store = 0;
f010289b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010289e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028a4:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028a9:	eb 30                	jmp    f01028db <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01028ab:	84 c9                	test   %cl,%cl
f01028ad:	74 22                	je     f01028d1 <envid2env+0x72>
f01028af:	8b 15 48 be 17 f0    	mov    0xf017be48,%edx
f01028b5:	39 d0                	cmp    %edx,%eax
f01028b7:	74 18                	je     f01028d1 <envid2env+0x72>
f01028b9:	8b 4a 48             	mov    0x48(%edx),%ecx
f01028bc:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01028bf:	74 10                	je     f01028d1 <envid2env+0x72>
		*env_store = 0;
f01028c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028c4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028ca:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028cf:	eb 0a                	jmp    f01028db <envid2env+0x7c>
	}

	*env_store = e;
f01028d1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028d4:	89 01                	mov    %eax,(%ecx)
	return 0;
f01028d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028db:	5d                   	pop    %ebp
f01028dc:	c3                   	ret    

f01028dd <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01028dd:	55                   	push   %ebp
f01028de:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01028e0:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01028e5:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01028e8:	b8 23 00 00 00       	mov    $0x23,%eax
f01028ed:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01028ef:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01028f1:	b8 10 00 00 00       	mov    $0x10,%eax
f01028f6:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01028f8:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01028fa:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01028fc:	ea 03 29 10 f0 08 00 	ljmp   $0x8,$0xf0102903
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102903:	b8 00 00 00 00       	mov    $0x0,%eax
f0102908:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010290b:	5d                   	pop    %ebp
f010290c:	c3                   	ret    

f010290d <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010290d:	55                   	push   %ebp
f010290e:	89 e5                	mov    %esp,%ebp
f0102910:	56                   	push   %esi
f0102911:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
		envs[i].env_id = 0;
f0102912:	8b 35 4c be 17 f0    	mov    0xf017be4c,%esi
f0102918:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010291e:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102921:	ba 00 00 00 00       	mov    $0x0,%edx
f0102926:	89 c1                	mov    %eax,%ecx
f0102928:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f010292f:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0102936:	89 50 44             	mov    %edx,0x44(%eax)
f0102939:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f010293c:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
f010293e:	39 d8                	cmp    %ebx,%eax
f0102940:	75 e4                	jne    f0102926 <env_init+0x19>
f0102942:	89 35 50 be 17 f0    	mov    %esi,0xf017be50
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102948:	e8 90 ff ff ff       	call   f01028dd <env_init_percpu>
}
f010294d:	5b                   	pop    %ebx
f010294e:	5e                   	pop    %esi
f010294f:	5d                   	pop    %ebp
f0102950:	c3                   	ret    

f0102951 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102951:	55                   	push   %ebp
f0102952:	89 e5                	mov    %esp,%ebp
f0102954:	53                   	push   %ebx
f0102955:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102958:	8b 1d 50 be 17 f0    	mov    0xf017be50,%ebx
f010295e:	85 db                	test   %ebx,%ebx
f0102960:	0f 84 61 01 00 00    	je     f0102ac7 <env_alloc+0x176>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102966:	83 ec 0c             	sub    $0xc,%esp
f0102969:	6a 01                	push   $0x1
f010296b:	e8 39 e3 ff ff       	call   f0100ca9 <page_alloc>
f0102970:	83 c4 10             	add    $0x10,%esp
f0102973:	85 c0                	test   %eax,%eax
f0102975:	0f 84 53 01 00 00    	je     f0102ace <env_alloc+0x17d>


static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010297b:	89 c2                	mov    %eax,%edx
f010297d:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0102983:	c1 fa 03             	sar    $0x3,%edx
f0102986:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102989:	89 d1                	mov    %edx,%ecx
f010298b:	c1 e9 0c             	shr    $0xc,%ecx
f010298e:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f0102994:	72 12                	jb     f01029a8 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102996:	52                   	push   %edx
f0102997:	68 94 4e 10 f0       	push   $0xf0104e94
f010299c:	6a 5c                	push   $0x5c
f010299e:	68 98 4b 10 f0       	push   $0xf0104b98
f01029a3:	e8 f8 d6 ff ff       	call   f01000a0 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
f01029a8:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01029ae:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f01029b1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f01029b6:	b8 00 00 00 00       	mov    $0x0,%eax

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
		e->env_pgdir[i] = 0;		
f01029bb:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01029be:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f01029c5:	83 c0 04             	add    $0x4,%eax
	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
f01029c8:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01029cd:	75 ec                	jne    f01029bb <env_alloc+0x6a>
		e->env_pgdir[i] = 0;		
	}
	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
		e->env_pgdir[i] = kern_pgdir[i];
f01029cf:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f01029d5:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01029d8:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01029db:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01029de:	83 c0 04             	add    $0x4,%eax
	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
		e->env_pgdir[i] = 0;		
	}
	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
f01029e1:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01029e6:	75 e7                	jne    f01029cf <env_alloc+0x7e>
		e->env_pgdir[i] = kern_pgdir[i];
	}	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01029e8:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029eb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029f0:	77 15                	ja     f0102a07 <env_alloc+0xb6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029f2:	50                   	push   %eax
f01029f3:	68 d8 4f 10 f0       	push   $0xf0104fd8
f01029f8:	68 ca 00 00 00       	push   $0xca
f01029fd:	68 3e 57 10 f0       	push   $0xf010573e
f0102a02:	e8 99 d6 ff ff       	call   f01000a0 <_panic>
f0102a07:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102a0d:	83 ca 05             	or     $0x5,%edx
f0102a10:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a16:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a19:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a1e:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a23:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a28:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a2b:	89 da                	mov    %ebx,%edx
f0102a2d:	2b 15 4c be 17 f0    	sub    0xf017be4c,%edx
f0102a33:	c1 fa 05             	sar    $0x5,%edx
f0102a36:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a3c:	09 d0                	or     %edx,%eax
f0102a3e:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a41:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a44:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a47:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a4e:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a55:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a5c:	83 ec 04             	sub    $0x4,%esp
f0102a5f:	6a 44                	push   $0x44
f0102a61:	6a 00                	push   $0x0
f0102a63:	53                   	push   %ebx
f0102a64:	e8 cc 17 00 00       	call   f0104235 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a69:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a6f:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a75:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a7b:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a82:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a88:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a8b:	a3 50 be 17 f0       	mov    %eax,0xf017be50
	*newenv_store = e;
f0102a90:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a93:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a95:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a98:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f0102a9d:	83 c4 10             	add    $0x10,%esp
f0102aa0:	85 c0                	test   %eax,%eax
f0102aa2:	74 05                	je     f0102aa9 <env_alloc+0x158>
f0102aa4:	8b 40 48             	mov    0x48(%eax),%eax
f0102aa7:	eb 05                	jmp    f0102aae <env_alloc+0x15d>
f0102aa9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aae:	83 ec 04             	sub    $0x4,%esp
f0102ab1:	52                   	push   %edx
f0102ab2:	50                   	push   %eax
f0102ab3:	68 5c 57 10 f0       	push   $0xf010575c
f0102ab8:	e8 10 04 00 00       	call   f0102ecd <cprintf>
	return 0;
f0102abd:	83 c4 10             	add    $0x10,%esp
f0102ac0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ac5:	eb 0c                	jmp    f0102ad3 <env_alloc+0x182>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102ac7:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102acc:	eb 05                	jmp    f0102ad3 <env_alloc+0x182>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102ace:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102ad3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ad6:	c9                   	leave  
f0102ad7:	c3                   	ret    

f0102ad8 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102ad8:	55                   	push   %ebp
f0102ad9:	89 e5                	mov    %esp,%ebp
f0102adb:	57                   	push   %edi
f0102adc:	56                   	push   %esi
f0102add:	53                   	push   %ebx
f0102ade:	83 ec 34             	sub    $0x34,%esp
f0102ae1:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int rc;
	if((rc = env_alloc(&e, 0)) != 0) {
f0102ae4:	6a 00                	push   $0x0
f0102ae6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102ae9:	50                   	push   %eax
f0102aea:	e8 62 fe ff ff       	call   f0102951 <env_alloc>
f0102aef:	83 c4 10             	add    $0x10,%esp
f0102af2:	85 c0                	test   %eax,%eax
f0102af4:	74 17                	je     f0102b0d <env_create+0x35>
		panic("env_create failed: env_alloc failed.\n");
f0102af6:	83 ec 04             	sub    $0x4,%esp
f0102af9:	68 78 56 10 f0       	push   $0xf0105678
f0102afe:	68 97 01 00 00       	push   $0x197
f0102b03:	68 3e 57 10 f0       	push   $0xf010573e
f0102b08:	e8 93 d5 ff ff       	call   f01000a0 <_panic>
	}

	load_icode(e, binary);
f0102b0d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b10:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf* header = (struct Elf*)binary;
	
	if(header->e_magic != ELF_MAGIC) {
f0102b13:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102b19:	74 17                	je     f0102b32 <env_create+0x5a>
		panic("load_icode failed: The binary we load is not elf.\n");
f0102b1b:	83 ec 04             	sub    $0x4,%esp
f0102b1e:	68 a0 56 10 f0       	push   $0xf01056a0
f0102b23:	68 68 01 00 00       	push   $0x168
f0102b28:	68 3e 57 10 f0       	push   $0xf010573e
f0102b2d:	e8 6e d5 ff ff       	call   f01000a0 <_panic>
	}

	if(header->e_entry == 0){
f0102b32:	8b 47 18             	mov    0x18(%edi),%eax
f0102b35:	85 c0                	test   %eax,%eax
f0102b37:	75 17                	jne    f0102b50 <env_create+0x78>
		panic("load_icode failed: The elf file can't be excuterd.\n");
f0102b39:	83 ec 04             	sub    $0x4,%esp
f0102b3c:	68 d4 56 10 f0       	push   $0xf01056d4
f0102b41:	68 6c 01 00 00       	push   $0x16c
f0102b46:	68 3e 57 10 f0       	push   $0xf010573e
f0102b4b:	e8 50 d5 ff ff       	call   f01000a0 <_panic>
	}

	e->env_tf.tf_eip = header->e_entry;
f0102b50:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102b53:	89 41 30             	mov    %eax,0x30(%ecx)

	lcr3(PADDR(e->env_pgdir));
f0102b56:	8b 41 5c             	mov    0x5c(%ecx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b59:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b5e:	77 15                	ja     f0102b75 <env_create+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b60:	50                   	push   %eax
f0102b61:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0102b66:	68 71 01 00 00       	push   $0x171
f0102b6b:	68 3e 57 10 f0       	push   $0xf010573e
f0102b70:	e8 2b d5 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b75:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b7a:	0f 22 d8             	mov    %eax,%cr3

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
f0102b7d:	89 fb                	mov    %edi,%ebx
f0102b7f:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + header->e_phnum;
f0102b82:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b86:	c1 e6 05             	shl    $0x5,%esi
f0102b89:	01 de                	add    %ebx,%esi
f0102b8b:	eb 44                	jmp    f0102bd1 <env_create+0xf9>
	for(; ph < eph; ph++) {
		if(ph->p_type == ELF_PROG_LOAD) {
f0102b8d:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b90:	75 3c                	jne    f0102bce <env_create+0xf6>
			if(ph->p_memsz - ph->p_filesz < 0) {
				panic("load icode failed : p_memsz < p_filesz.\n");
			}

			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102b92:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b95:	8b 53 08             	mov    0x8(%ebx),%edx
f0102b98:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b9b:	e8 39 fc ff ff       	call   f01027d9 <region_alloc>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102ba0:	83 ec 04             	sub    $0x4,%esp
f0102ba3:	ff 73 10             	pushl  0x10(%ebx)
f0102ba6:	89 f8                	mov    %edi,%eax
f0102ba8:	03 43 04             	add    0x4(%ebx),%eax
f0102bab:	50                   	push   %eax
f0102bac:	ff 73 08             	pushl  0x8(%ebx)
f0102baf:	e8 ce 16 00 00       	call   f0104282 <memmove>
			memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f0102bb4:	8b 43 10             	mov    0x10(%ebx),%eax
f0102bb7:	83 c4 0c             	add    $0xc,%esp
f0102bba:	8b 53 14             	mov    0x14(%ebx),%edx
f0102bbd:	29 c2                	sub    %eax,%edx
f0102bbf:	52                   	push   %edx
f0102bc0:	6a 00                	push   $0x0
f0102bc2:	03 43 08             	add    0x8(%ebx),%eax
f0102bc5:	50                   	push   %eax
f0102bc6:	e8 6a 16 00 00       	call   f0104235 <memset>
f0102bcb:	83 c4 10             	add    $0x10,%esp
	lcr3(PADDR(e->env_pgdir));

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
	eph = ph + header->e_phnum;
	for(; ph < eph; ph++) {
f0102bce:	83 c3 20             	add    $0x20,%ebx
f0102bd1:	39 de                	cmp    %ebx,%esi
f0102bd3:	77 b8                	ja     f0102b8d <env_create+0xb5>
	} 
	 
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP-PGSIZE), PGSIZE);
f0102bd5:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102bda:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102bdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102be2:	e8 f2 fb ff ff       	call   f01027d9 <region_alloc>
	if((rc = env_alloc(&e, 0)) != 0) {
		panic("env_create failed: env_alloc failed.\n");
	}

	load_icode(e, binary);
	e->env_type = type;
f0102be7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102bea:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102bed:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102bf0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bf3:	5b                   	pop    %ebx
f0102bf4:	5e                   	pop    %esi
f0102bf5:	5f                   	pop    %edi
f0102bf6:	5d                   	pop    %ebp
f0102bf7:	c3                   	ret    

f0102bf8 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102bf8:	55                   	push   %ebp
f0102bf9:	89 e5                	mov    %esp,%ebp
f0102bfb:	57                   	push   %edi
f0102bfc:	56                   	push   %esi
f0102bfd:	53                   	push   %ebx
f0102bfe:	83 ec 1c             	sub    $0x1c,%esp
f0102c01:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102c04:	8b 15 48 be 17 f0    	mov    0xf017be48,%edx
f0102c0a:	39 fa                	cmp    %edi,%edx
f0102c0c:	75 29                	jne    f0102c37 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c0e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c13:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c18:	77 15                	ja     f0102c2f <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c1a:	50                   	push   %eax
f0102c1b:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0102c20:	68 ac 01 00 00       	push   $0x1ac
f0102c25:	68 3e 57 10 f0       	push   $0xf010573e
f0102c2a:	e8 71 d4 ff ff       	call   f01000a0 <_panic>
f0102c2f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c34:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c37:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c3a:	85 d2                	test   %edx,%edx
f0102c3c:	74 05                	je     f0102c43 <env_free+0x4b>
f0102c3e:	8b 42 48             	mov    0x48(%edx),%eax
f0102c41:	eb 05                	jmp    f0102c48 <env_free+0x50>
f0102c43:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c48:	83 ec 04             	sub    $0x4,%esp
f0102c4b:	51                   	push   %ecx
f0102c4c:	50                   	push   %eax
f0102c4d:	68 71 57 10 f0       	push   $0xf0105771
f0102c52:	e8 76 02 00 00       	call   f0102ecd <cprintf>
f0102c57:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c5a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102c61:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102c64:	89 d0                	mov    %edx,%eax
f0102c66:	c1 e0 02             	shl    $0x2,%eax
f0102c69:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102c6c:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c6f:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102c72:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102c78:	0f 84 a8 00 00 00    	je     f0102d26 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102c7e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c84:	89 f0                	mov    %esi,%eax
f0102c86:	c1 e8 0c             	shr    $0xc,%eax
f0102c89:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c8c:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102c92:	77 15                	ja     f0102ca9 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c94:	56                   	push   %esi
f0102c95:	68 94 4e 10 f0       	push   $0xf0104e94
f0102c9a:	68 bb 01 00 00       	push   $0x1bb
f0102c9f:	68 3e 57 10 f0       	push   $0xf010573e
f0102ca4:	e8 f7 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102ca9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cac:	c1 e0 16             	shl    $0x16,%eax
f0102caf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102cb2:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102cb7:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102cbe:	01 
f0102cbf:	74 17                	je     f0102cd8 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cc1:	83 ec 08             	sub    $0x8,%esp
f0102cc4:	89 d8                	mov    %ebx,%eax
f0102cc6:	c1 e0 0c             	shl    $0xc,%eax
f0102cc9:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102ccc:	50                   	push   %eax
f0102ccd:	ff 77 5c             	pushl  0x5c(%edi)
f0102cd0:	e8 14 e2 ff ff       	call   f0100ee9 <page_remove>
f0102cd5:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102cd8:	83 c3 01             	add    $0x1,%ebx
f0102cdb:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102ce1:	75 d4                	jne    f0102cb7 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102ce3:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102ce6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ce9:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cf0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102cf3:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102cf9:	72 14                	jb     f0102d0f <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102cfb:	83 ec 04             	sub    $0x4,%esp
f0102cfe:	68 7c 4f 10 f0       	push   $0xf0104f7c
f0102d03:	6a 55                	push   $0x55
f0102d05:	68 98 4b 10 f0       	push   $0xf0104b98
f0102d0a:	e8 91 d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d0f:	83 ec 0c             	sub    $0xc,%esp
f0102d12:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102d17:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d1a:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d1d:	50                   	push   %eax
f0102d1e:	e8 53 e0 ff ff       	call   f0100d76 <page_decref>
f0102d23:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d26:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d2d:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d32:	0f 85 29 ff ff ff    	jne    f0102c61 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d38:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d3b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d40:	77 15                	ja     f0102d57 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d42:	50                   	push   %eax
f0102d43:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0102d48:	68 c9 01 00 00       	push   $0x1c9
f0102d4d:	68 3e 57 10 f0       	push   $0xf010573e
f0102d52:	e8 49 d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102d57:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d5e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d63:	c1 e8 0c             	shr    $0xc,%eax
f0102d66:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102d6c:	72 14                	jb     f0102d82 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102d6e:	83 ec 04             	sub    $0x4,%esp
f0102d71:	68 7c 4f 10 f0       	push   $0xf0104f7c
f0102d76:	6a 55                	push   $0x55
f0102d78:	68 98 4b 10 f0       	push   $0xf0104b98
f0102d7d:	e8 1e d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102d82:	83 ec 0c             	sub    $0xc,%esp
f0102d85:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102d8b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102d8e:	50                   	push   %eax
f0102d8f:	e8 e2 df ff ff       	call   f0100d76 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d94:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102d9b:	a1 50 be 17 f0       	mov    0xf017be50,%eax
f0102da0:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102da3:	89 3d 50 be 17 f0    	mov    %edi,0xf017be50
}
f0102da9:	83 c4 10             	add    $0x10,%esp
f0102dac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102daf:	5b                   	pop    %ebx
f0102db0:	5e                   	pop    %esi
f0102db1:	5f                   	pop    %edi
f0102db2:	5d                   	pop    %ebp
f0102db3:	c3                   	ret    

f0102db4 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102db4:	55                   	push   %ebp
f0102db5:	89 e5                	mov    %esp,%ebp
f0102db7:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102dba:	ff 75 08             	pushl  0x8(%ebp)
f0102dbd:	e8 36 fe ff ff       	call   f0102bf8 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102dc2:	c7 04 24 08 57 10 f0 	movl   $0xf0105708,(%esp)
f0102dc9:	e8 ff 00 00 00       	call   f0102ecd <cprintf>
f0102dce:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102dd1:	83 ec 0c             	sub    $0xc,%esp
f0102dd4:	6a 00                	push   $0x0
f0102dd6:	e8 49 d9 ff ff       	call   f0100724 <monitor>
f0102ddb:	83 c4 10             	add    $0x10,%esp
f0102dde:	eb f1                	jmp    f0102dd1 <env_destroy+0x1d>

f0102de0 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102de0:	55                   	push   %ebp
f0102de1:	89 e5                	mov    %esp,%ebp
f0102de3:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102de6:	8b 65 08             	mov    0x8(%ebp),%esp
f0102de9:	61                   	popa   
f0102dea:	07                   	pop    %es
f0102deb:	1f                   	pop    %ds
f0102dec:	83 c4 08             	add    $0x8,%esp
f0102def:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102df0:	68 87 57 10 f0       	push   $0xf0105787
f0102df5:	68 f1 01 00 00       	push   $0x1f1
f0102dfa:	68 3e 57 10 f0       	push   $0xf010573e
f0102dff:	e8 9c d2 ff ff       	call   f01000a0 <_panic>

f0102e04 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e04:	55                   	push   %ebp
f0102e05:	89 e5                	mov    %esp,%ebp
f0102e07:	83 ec 08             	sub    $0x8,%esp
f0102e0a:	8b 45 08             	mov    0x8(%ebp),%eax
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING) {
f0102e0d:	8b 15 48 be 17 f0    	mov    0xf017be48,%edx
f0102e13:	85 d2                	test   %edx,%edx
f0102e15:	74 0d                	je     f0102e24 <env_run+0x20>
f0102e17:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102e1b:	75 07                	jne    f0102e24 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0102e1d:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e;
f0102e24:	a3 48 be 17 f0       	mov    %eax,0xf017be48
	curenv->env_status = ENV_RUNNING;
f0102e29:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0102e30:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0102e34:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e37:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102e3d:	77 15                	ja     f0102e54 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e3f:	52                   	push   %edx
f0102e40:	68 d8 4f 10 f0       	push   $0xf0104fd8
f0102e45:	68 0e 02 00 00       	push   $0x20e
f0102e4a:	68 3e 57 10 f0       	push   $0xf010573e
f0102e4f:	e8 4c d2 ff ff       	call   f01000a0 <_panic>
f0102e54:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102e5a:	0f 22 da             	mov    %edx,%cr3
	// Hint: This function loads the new environment's state from
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	env_pop_tf(&curenv->env_tf);
f0102e5d:	83 ec 0c             	sub    $0xc,%esp
f0102e60:	50                   	push   %eax
f0102e61:	e8 7a ff ff ff       	call   f0102de0 <env_pop_tf>

f0102e66 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e66:	55                   	push   %ebp
f0102e67:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e69:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e71:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e72:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e77:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e78:	0f b6 c0             	movzbl %al,%eax
}
f0102e7b:	5d                   	pop    %ebp
f0102e7c:	c3                   	ret    

f0102e7d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e7d:	55                   	push   %ebp
f0102e7e:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e80:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e85:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e88:	ee                   	out    %al,(%dx)
f0102e89:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e8e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e91:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e92:	5d                   	pop    %ebp
f0102e93:	c3                   	ret    

f0102e94 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e94:	55                   	push   %ebp
f0102e95:	89 e5                	mov    %esp,%ebp
f0102e97:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102e9a:	ff 75 08             	pushl  0x8(%ebp)
f0102e9d:	e8 65 d7 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102ea2:	83 c4 10             	add    $0x10,%esp
f0102ea5:	c9                   	leave  
f0102ea6:	c3                   	ret    

f0102ea7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ea7:	55                   	push   %ebp
f0102ea8:	89 e5                	mov    %esp,%ebp
f0102eaa:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102ead:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102eb4:	ff 75 0c             	pushl  0xc(%ebp)
f0102eb7:	ff 75 08             	pushl  0x8(%ebp)
f0102eba:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ebd:	50                   	push   %eax
f0102ebe:	68 94 2e 10 f0       	push   $0xf0102e94
f0102ec3:	e8 48 0c 00 00       	call   f0103b10 <vprintfmt>
	return cnt;
}
f0102ec8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ecb:	c9                   	leave  
f0102ecc:	c3                   	ret    

f0102ecd <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102ecd:	55                   	push   %ebp
f0102ece:	89 e5                	mov    %esp,%ebp
f0102ed0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102ed3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102ed6:	50                   	push   %eax
f0102ed7:	ff 75 08             	pushl  0x8(%ebp)
f0102eda:	e8 c8 ff ff ff       	call   f0102ea7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102edf:	c9                   	leave  
f0102ee0:	c3                   	ret    

f0102ee1 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102ee1:	55                   	push   %ebp
f0102ee2:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102ee4:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102ee9:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102ef0:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102ef3:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102efa:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102efc:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102f03:	67 00 
f0102f05:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102f0b:	89 c2                	mov    %eax,%edx
f0102f0d:	c1 ea 10             	shr    $0x10,%edx
f0102f10:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102f16:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102f1d:	c1 e8 18             	shr    $0x18,%eax
f0102f20:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f25:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102f2c:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f31:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102f34:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102f39:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f3c:	5d                   	pop    %ebp
f0102f3d:	c3                   	ret    

f0102f3e <trap_init>:
}


void
trap_init(void)
{
f0102f3e:	55                   	push   %ebp
f0102f3f:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0102f41:	b8 1c 36 10 f0       	mov    $0xf010361c,%eax
f0102f46:	66 a3 60 be 17 f0    	mov    %ax,0xf017be60
f0102f4c:	66 c7 05 62 be 17 f0 	movw   $0x8,0xf017be62
f0102f53:	08 00 
f0102f55:	c6 05 64 be 17 f0 00 	movb   $0x0,0xf017be64
f0102f5c:	c6 05 65 be 17 f0 8e 	movb   $0x8e,0xf017be65
f0102f63:	c1 e8 10             	shr    $0x10,%eax
f0102f66:	66 a3 66 be 17 f0    	mov    %ax,0xf017be66
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0102f6c:	b8 22 36 10 f0       	mov    $0xf0103622,%eax
f0102f71:	66 a3 68 be 17 f0    	mov    %ax,0xf017be68
f0102f77:	66 c7 05 6a be 17 f0 	movw   $0x8,0xf017be6a
f0102f7e:	08 00 
f0102f80:	c6 05 6c be 17 f0 00 	movb   $0x0,0xf017be6c
f0102f87:	c6 05 6d be 17 f0 8e 	movb   $0x8e,0xf017be6d
f0102f8e:	c1 e8 10             	shr    $0x10,%eax
f0102f91:	66 a3 6e be 17 f0    	mov    %ax,0xf017be6e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f0102f97:	b8 28 36 10 f0       	mov    $0xf0103628,%eax
f0102f9c:	66 a3 70 be 17 f0    	mov    %ax,0xf017be70
f0102fa2:	66 c7 05 72 be 17 f0 	movw   $0x8,0xf017be72
f0102fa9:	08 00 
f0102fab:	c6 05 74 be 17 f0 00 	movb   $0x0,0xf017be74
f0102fb2:	c6 05 75 be 17 f0 8e 	movb   $0x8e,0xf017be75
f0102fb9:	c1 e8 10             	shr    $0x10,%eax
f0102fbc:	66 a3 76 be 17 f0    	mov    %ax,0xf017be76
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f0102fc2:	b8 2e 36 10 f0       	mov    $0xf010362e,%eax
f0102fc7:	66 a3 78 be 17 f0    	mov    %ax,0xf017be78
f0102fcd:	66 c7 05 7a be 17 f0 	movw   $0x8,0xf017be7a
f0102fd4:	08 00 
f0102fd6:	c6 05 7c be 17 f0 00 	movb   $0x0,0xf017be7c
f0102fdd:	c6 05 7d be 17 f0 ee 	movb   $0xee,0xf017be7d
f0102fe4:	c1 e8 10             	shr    $0x10,%eax
f0102fe7:	66 a3 7e be 17 f0    	mov    %ax,0xf017be7e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f0102fed:	b8 34 36 10 f0       	mov    $0xf0103634,%eax
f0102ff2:	66 a3 80 be 17 f0    	mov    %ax,0xf017be80
f0102ff8:	66 c7 05 82 be 17 f0 	movw   $0x8,0xf017be82
f0102fff:	08 00 
f0103001:	c6 05 84 be 17 f0 00 	movb   $0x0,0xf017be84
f0103008:	c6 05 85 be 17 f0 8e 	movb   $0x8e,0xf017be85
f010300f:	c1 e8 10             	shr    $0x10,%eax
f0103012:	66 a3 86 be 17 f0    	mov    %ax,0xf017be86
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f0103018:	b8 3a 36 10 f0       	mov    $0xf010363a,%eax
f010301d:	66 a3 88 be 17 f0    	mov    %ax,0xf017be88
f0103023:	66 c7 05 8a be 17 f0 	movw   $0x8,0xf017be8a
f010302a:	08 00 
f010302c:	c6 05 8c be 17 f0 00 	movb   $0x0,0xf017be8c
f0103033:	c6 05 8d be 17 f0 8e 	movb   $0x8e,0xf017be8d
f010303a:	c1 e8 10             	shr    $0x10,%eax
f010303d:	66 a3 8e be 17 f0    	mov    %ax,0xf017be8e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103043:	b8 40 36 10 f0       	mov    $0xf0103640,%eax
f0103048:	66 a3 90 be 17 f0    	mov    %ax,0xf017be90
f010304e:	66 c7 05 92 be 17 f0 	movw   $0x8,0xf017be92
f0103055:	08 00 
f0103057:	c6 05 94 be 17 f0 00 	movb   $0x0,0xf017be94
f010305e:	c6 05 95 be 17 f0 8e 	movb   $0x8e,0xf017be95
f0103065:	c1 e8 10             	shr    $0x10,%eax
f0103068:	66 a3 96 be 17 f0    	mov    %ax,0xf017be96
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f010306e:	b8 46 36 10 f0       	mov    $0xf0103646,%eax
f0103073:	66 a3 98 be 17 f0    	mov    %ax,0xf017be98
f0103079:	66 c7 05 9a be 17 f0 	movw   $0x8,0xf017be9a
f0103080:	08 00 
f0103082:	c6 05 9c be 17 f0 00 	movb   $0x0,0xf017be9c
f0103089:	c6 05 9d be 17 f0 8e 	movb   $0x8e,0xf017be9d
f0103090:	c1 e8 10             	shr    $0x10,%eax
f0103093:	66 a3 9e be 17 f0    	mov    %ax,0xf017be9e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f0103099:	b8 4c 36 10 f0       	mov    $0xf010364c,%eax
f010309e:	66 a3 a0 be 17 f0    	mov    %ax,0xf017bea0
f01030a4:	66 c7 05 a2 be 17 f0 	movw   $0x8,0xf017bea2
f01030ab:	08 00 
f01030ad:	c6 05 a4 be 17 f0 00 	movb   $0x0,0xf017bea4
f01030b4:	c6 05 a5 be 17 f0 8e 	movb   $0x8e,0xf017bea5
f01030bb:	c1 e8 10             	shr    $0x10,%eax
f01030be:	66 a3 a6 be 17 f0    	mov    %ax,0xf017bea6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01030c4:	b8 50 36 10 f0       	mov    $0xf0103650,%eax
f01030c9:	66 a3 b0 be 17 f0    	mov    %ax,0xf017beb0
f01030cf:	66 c7 05 b2 be 17 f0 	movw   $0x8,0xf017beb2
f01030d6:	08 00 
f01030d8:	c6 05 b4 be 17 f0 00 	movb   $0x0,0xf017beb4
f01030df:	c6 05 b5 be 17 f0 8e 	movb   $0x8e,0xf017beb5
f01030e6:	c1 e8 10             	shr    $0x10,%eax
f01030e9:	66 a3 b6 be 17 f0    	mov    %ax,0xf017beb6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01030ef:	b8 54 36 10 f0       	mov    $0xf0103654,%eax
f01030f4:	66 a3 b8 be 17 f0    	mov    %ax,0xf017beb8
f01030fa:	66 c7 05 ba be 17 f0 	movw   $0x8,0xf017beba
f0103101:	08 00 
f0103103:	c6 05 bc be 17 f0 00 	movb   $0x0,0xf017bebc
f010310a:	c6 05 bd be 17 f0 8e 	movb   $0x8e,0xf017bebd
f0103111:	c1 e8 10             	shr    $0x10,%eax
f0103114:	66 a3 be be 17 f0    	mov    %ax,0xf017bebe
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f010311a:	b8 58 36 10 f0       	mov    $0xf0103658,%eax
f010311f:	66 a3 c0 be 17 f0    	mov    %ax,0xf017bec0
f0103125:	66 c7 05 c2 be 17 f0 	movw   $0x8,0xf017bec2
f010312c:	08 00 
f010312e:	c6 05 c4 be 17 f0 00 	movb   $0x0,0xf017bec4
f0103135:	c6 05 c5 be 17 f0 8e 	movb   $0x8e,0xf017bec5
f010313c:	c1 e8 10             	shr    $0x10,%eax
f010313f:	66 a3 c6 be 17 f0    	mov    %ax,0xf017bec6
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103145:	b8 5c 36 10 f0       	mov    $0xf010365c,%eax
f010314a:	66 a3 c8 be 17 f0    	mov    %ax,0xf017bec8
f0103150:	66 c7 05 ca be 17 f0 	movw   $0x8,0xf017beca
f0103157:	08 00 
f0103159:	c6 05 cc be 17 f0 00 	movb   $0x0,0xf017becc
f0103160:	c6 05 cd be 17 f0 8e 	movb   $0x8e,0xf017becd
f0103167:	c1 e8 10             	shr    $0x10,%eax
f010316a:	66 a3 ce be 17 f0    	mov    %ax,0xf017bece
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103170:	b8 60 36 10 f0       	mov    $0xf0103660,%eax
f0103175:	66 a3 d0 be 17 f0    	mov    %ax,0xf017bed0
f010317b:	66 c7 05 d2 be 17 f0 	movw   $0x8,0xf017bed2
f0103182:	08 00 
f0103184:	c6 05 d4 be 17 f0 00 	movb   $0x0,0xf017bed4
f010318b:	c6 05 d5 be 17 f0 8e 	movb   $0x8e,0xf017bed5
f0103192:	c1 e8 10             	shr    $0x10,%eax
f0103195:	66 a3 d6 be 17 f0    	mov    %ax,0xf017bed6
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f010319b:	b8 64 36 10 f0       	mov    $0xf0103664,%eax
f01031a0:	66 a3 e0 be 17 f0    	mov    %ax,0xf017bee0
f01031a6:	66 c7 05 e2 be 17 f0 	movw   $0x8,0xf017bee2
f01031ad:	08 00 
f01031af:	c6 05 e4 be 17 f0 00 	movb   $0x0,0xf017bee4
f01031b6:	c6 05 e5 be 17 f0 8e 	movb   $0x8e,0xf017bee5
f01031bd:	c1 e8 10             	shr    $0x10,%eax
f01031c0:	66 a3 e6 be 17 f0    	mov    %ax,0xf017bee6
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01031c6:	b8 6a 36 10 f0       	mov    $0xf010366a,%eax
f01031cb:	66 a3 e8 be 17 f0    	mov    %ax,0xf017bee8
f01031d1:	66 c7 05 ea be 17 f0 	movw   $0x8,0xf017beea
f01031d8:	08 00 
f01031da:	c6 05 ec be 17 f0 00 	movb   $0x0,0xf017beec
f01031e1:	c6 05 ed be 17 f0 8e 	movb   $0x8e,0xf017beed
f01031e8:	c1 e8 10             	shr    $0x10,%eax
f01031eb:	66 a3 ee be 17 f0    	mov    %ax,0xf017beee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01031f1:	b8 6e 36 10 f0       	mov    $0xf010366e,%eax
f01031f6:	66 a3 f0 be 17 f0    	mov    %ax,0xf017bef0
f01031fc:	66 c7 05 f2 be 17 f0 	movw   $0x8,0xf017bef2
f0103203:	08 00 
f0103205:	c6 05 f4 be 17 f0 00 	movb   $0x0,0xf017bef4
f010320c:	c6 05 f5 be 17 f0 8e 	movb   $0x8e,0xf017bef5
f0103213:	c1 e8 10             	shr    $0x10,%eax
f0103216:	66 a3 f6 be 17 f0    	mov    %ax,0xf017bef6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f010321c:	b8 74 36 10 f0       	mov    $0xf0103674,%eax
f0103221:	66 a3 f8 be 17 f0    	mov    %ax,0xf017bef8
f0103227:	66 c7 05 fa be 17 f0 	movw   $0x8,0xf017befa
f010322e:	08 00 
f0103230:	c6 05 fc be 17 f0 00 	movb   $0x0,0xf017befc
f0103237:	c6 05 fd be 17 f0 8e 	movb   $0x8e,0xf017befd
f010323e:	c1 e8 10             	shr    $0x10,%eax
f0103241:	66 a3 fe be 17 f0    	mov    %ax,0xf017befe
	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103247:	b8 7a 36 10 f0       	mov    $0xf010367a,%eax
f010324c:	66 a3 e0 bf 17 f0    	mov    %ax,0xf017bfe0
f0103252:	66 c7 05 e2 bf 17 f0 	movw   $0x8,0xf017bfe2
f0103259:	08 00 
f010325b:	c6 05 e4 bf 17 f0 00 	movb   $0x0,0xf017bfe4
f0103262:	c6 05 e5 bf 17 f0 ee 	movb   $0xee,0xf017bfe5
f0103269:	c1 e8 10             	shr    $0x10,%eax
f010326c:	66 a3 e6 bf 17 f0    	mov    %ax,0xf017bfe6
	// Per-CPU setup 
	trap_init_percpu();
f0103272:	e8 6a fc ff ff       	call   f0102ee1 <trap_init_percpu>
}
f0103277:	5d                   	pop    %ebp
f0103278:	c3                   	ret    

f0103279 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103279:	55                   	push   %ebp
f010327a:	89 e5                	mov    %esp,%ebp
f010327c:	53                   	push   %ebx
f010327d:	83 ec 0c             	sub    $0xc,%esp
f0103280:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103283:	ff 33                	pushl  (%ebx)
f0103285:	68 93 57 10 f0       	push   $0xf0105793
f010328a:	e8 3e fc ff ff       	call   f0102ecd <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010328f:	83 c4 08             	add    $0x8,%esp
f0103292:	ff 73 04             	pushl  0x4(%ebx)
f0103295:	68 a2 57 10 f0       	push   $0xf01057a2
f010329a:	e8 2e fc ff ff       	call   f0102ecd <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010329f:	83 c4 08             	add    $0x8,%esp
f01032a2:	ff 73 08             	pushl  0x8(%ebx)
f01032a5:	68 b1 57 10 f0       	push   $0xf01057b1
f01032aa:	e8 1e fc ff ff       	call   f0102ecd <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01032af:	83 c4 08             	add    $0x8,%esp
f01032b2:	ff 73 0c             	pushl  0xc(%ebx)
f01032b5:	68 c0 57 10 f0       	push   $0xf01057c0
f01032ba:	e8 0e fc ff ff       	call   f0102ecd <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01032bf:	83 c4 08             	add    $0x8,%esp
f01032c2:	ff 73 10             	pushl  0x10(%ebx)
f01032c5:	68 cf 57 10 f0       	push   $0xf01057cf
f01032ca:	e8 fe fb ff ff       	call   f0102ecd <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01032cf:	83 c4 08             	add    $0x8,%esp
f01032d2:	ff 73 14             	pushl  0x14(%ebx)
f01032d5:	68 de 57 10 f0       	push   $0xf01057de
f01032da:	e8 ee fb ff ff       	call   f0102ecd <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01032df:	83 c4 08             	add    $0x8,%esp
f01032e2:	ff 73 18             	pushl  0x18(%ebx)
f01032e5:	68 ed 57 10 f0       	push   $0xf01057ed
f01032ea:	e8 de fb ff ff       	call   f0102ecd <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01032ef:	83 c4 08             	add    $0x8,%esp
f01032f2:	ff 73 1c             	pushl  0x1c(%ebx)
f01032f5:	68 fc 57 10 f0       	push   $0xf01057fc
f01032fa:	e8 ce fb ff ff       	call   f0102ecd <cprintf>
}
f01032ff:	83 c4 10             	add    $0x10,%esp
f0103302:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103305:	c9                   	leave  
f0103306:	c3                   	ret    

f0103307 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103307:	55                   	push   %ebp
f0103308:	89 e5                	mov    %esp,%ebp
f010330a:	56                   	push   %esi
f010330b:	53                   	push   %ebx
f010330c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010330f:	83 ec 08             	sub    $0x8,%esp
f0103312:	53                   	push   %ebx
f0103313:	68 32 59 10 f0       	push   $0xf0105932
f0103318:	e8 b0 fb ff ff       	call   f0102ecd <cprintf>
	print_regs(&tf->tf_regs);
f010331d:	89 1c 24             	mov    %ebx,(%esp)
f0103320:	e8 54 ff ff ff       	call   f0103279 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103325:	83 c4 08             	add    $0x8,%esp
f0103328:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010332c:	50                   	push   %eax
f010332d:	68 4d 58 10 f0       	push   $0xf010584d
f0103332:	e8 96 fb ff ff       	call   f0102ecd <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103337:	83 c4 08             	add    $0x8,%esp
f010333a:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010333e:	50                   	push   %eax
f010333f:	68 60 58 10 f0       	push   $0xf0105860
f0103344:	e8 84 fb ff ff       	call   f0102ecd <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103349:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f010334c:	83 c4 10             	add    $0x10,%esp
f010334f:	83 f8 13             	cmp    $0x13,%eax
f0103352:	77 09                	ja     f010335d <print_trapframe+0x56>
		return excnames[trapno];
f0103354:	8b 14 85 00 5b 10 f0 	mov    -0xfefa500(,%eax,4),%edx
f010335b:	eb 10                	jmp    f010336d <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f010335d:	83 f8 30             	cmp    $0x30,%eax
f0103360:	b9 17 58 10 f0       	mov    $0xf0105817,%ecx
f0103365:	ba 0b 58 10 f0       	mov    $0xf010580b,%edx
f010336a:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010336d:	83 ec 04             	sub    $0x4,%esp
f0103370:	52                   	push   %edx
f0103371:	50                   	push   %eax
f0103372:	68 73 58 10 f0       	push   $0xf0105873
f0103377:	e8 51 fb ff ff       	call   f0102ecd <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010337c:	83 c4 10             	add    $0x10,%esp
f010337f:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f0103385:	75 1a                	jne    f01033a1 <print_trapframe+0x9a>
f0103387:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010338b:	75 14                	jne    f01033a1 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f010338d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103390:	83 ec 08             	sub    $0x8,%esp
f0103393:	50                   	push   %eax
f0103394:	68 85 58 10 f0       	push   $0xf0105885
f0103399:	e8 2f fb ff ff       	call   f0102ecd <cprintf>
f010339e:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01033a1:	83 ec 08             	sub    $0x8,%esp
f01033a4:	ff 73 2c             	pushl  0x2c(%ebx)
f01033a7:	68 94 58 10 f0       	push   $0xf0105894
f01033ac:	e8 1c fb ff ff       	call   f0102ecd <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01033b1:	83 c4 10             	add    $0x10,%esp
f01033b4:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033b8:	75 49                	jne    f0103403 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01033ba:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01033bd:	89 c2                	mov    %eax,%edx
f01033bf:	83 e2 01             	and    $0x1,%edx
f01033c2:	ba 31 58 10 f0       	mov    $0xf0105831,%edx
f01033c7:	b9 26 58 10 f0       	mov    $0xf0105826,%ecx
f01033cc:	0f 44 ca             	cmove  %edx,%ecx
f01033cf:	89 c2                	mov    %eax,%edx
f01033d1:	83 e2 02             	and    $0x2,%edx
f01033d4:	ba 43 58 10 f0       	mov    $0xf0105843,%edx
f01033d9:	be 3d 58 10 f0       	mov    $0xf010583d,%esi
f01033de:	0f 45 d6             	cmovne %esi,%edx
f01033e1:	83 e0 04             	and    $0x4,%eax
f01033e4:	be 5d 59 10 f0       	mov    $0xf010595d,%esi
f01033e9:	b8 48 58 10 f0       	mov    $0xf0105848,%eax
f01033ee:	0f 44 c6             	cmove  %esi,%eax
f01033f1:	51                   	push   %ecx
f01033f2:	52                   	push   %edx
f01033f3:	50                   	push   %eax
f01033f4:	68 a2 58 10 f0       	push   $0xf01058a2
f01033f9:	e8 cf fa ff ff       	call   f0102ecd <cprintf>
f01033fe:	83 c4 10             	add    $0x10,%esp
f0103401:	eb 10                	jmp    f0103413 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103403:	83 ec 0c             	sub    $0xc,%esp
f0103406:	68 61 4e 10 f0       	push   $0xf0104e61
f010340b:	e8 bd fa ff ff       	call   f0102ecd <cprintf>
f0103410:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103413:	83 ec 08             	sub    $0x8,%esp
f0103416:	ff 73 30             	pushl  0x30(%ebx)
f0103419:	68 b1 58 10 f0       	push   $0xf01058b1
f010341e:	e8 aa fa ff ff       	call   f0102ecd <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103423:	83 c4 08             	add    $0x8,%esp
f0103426:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010342a:	50                   	push   %eax
f010342b:	68 c0 58 10 f0       	push   $0xf01058c0
f0103430:	e8 98 fa ff ff       	call   f0102ecd <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103435:	83 c4 08             	add    $0x8,%esp
f0103438:	ff 73 38             	pushl  0x38(%ebx)
f010343b:	68 d3 58 10 f0       	push   $0xf01058d3
f0103440:	e8 88 fa ff ff       	call   f0102ecd <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103445:	83 c4 10             	add    $0x10,%esp
f0103448:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010344c:	74 25                	je     f0103473 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010344e:	83 ec 08             	sub    $0x8,%esp
f0103451:	ff 73 3c             	pushl  0x3c(%ebx)
f0103454:	68 e2 58 10 f0       	push   $0xf01058e2
f0103459:	e8 6f fa ff ff       	call   f0102ecd <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010345e:	83 c4 08             	add    $0x8,%esp
f0103461:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103465:	50                   	push   %eax
f0103466:	68 f1 58 10 f0       	push   $0xf01058f1
f010346b:	e8 5d fa ff ff       	call   f0102ecd <cprintf>
f0103470:	83 c4 10             	add    $0x10,%esp
	}
}
f0103473:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103476:	5b                   	pop    %ebx
f0103477:	5e                   	pop    %esi
f0103478:	5d                   	pop    %ebp
f0103479:	c3                   	ret    

f010347a <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010347a:	55                   	push   %ebp
f010347b:	89 e5                	mov    %esp,%ebp
f010347d:	53                   	push   %ebx
f010347e:	83 ec 04             	sub    $0x4,%esp
f0103481:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103484:	0f 20 d0             	mov    %cr2,%eax
	
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103487:	ff 73 30             	pushl  0x30(%ebx)
f010348a:	50                   	push   %eax
f010348b:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f0103490:	ff 70 48             	pushl  0x48(%eax)
f0103493:	68 a8 5a 10 f0       	push   $0xf0105aa8
f0103498:	e8 30 fa ff ff       	call   f0102ecd <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010349d:	89 1c 24             	mov    %ebx,(%esp)
f01034a0:	e8 62 fe ff ff       	call   f0103307 <print_trapframe>
	env_destroy(curenv);
f01034a5:	83 c4 04             	add    $0x4,%esp
f01034a8:	ff 35 48 be 17 f0    	pushl  0xf017be48
f01034ae:	e8 01 f9 ff ff       	call   f0102db4 <env_destroy>
}
f01034b3:	83 c4 10             	add    $0x10,%esp
f01034b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034b9:	c9                   	leave  
f01034ba:	c3                   	ret    

f01034bb <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01034bb:	55                   	push   %ebp
f01034bc:	89 e5                	mov    %esp,%ebp
f01034be:	57                   	push   %edi
f01034bf:	56                   	push   %esi
f01034c0:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01034c3:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01034c4:	9c                   	pushf  
f01034c5:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01034c6:	f6 c4 02             	test   $0x2,%ah
f01034c9:	74 19                	je     f01034e4 <trap+0x29>
f01034cb:	68 04 59 10 f0       	push   $0xf0105904
f01034d0:	68 b2 4b 10 f0       	push   $0xf0104bb2
f01034d5:	68 e4 00 00 00       	push   $0xe4
f01034da:	68 1d 59 10 f0       	push   $0xf010591d
f01034df:	e8 bc cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01034e4:	83 ec 08             	sub    $0x8,%esp
f01034e7:	56                   	push   %esi
f01034e8:	68 29 59 10 f0       	push   $0xf0105929
f01034ed:	e8 db f9 ff ff       	call   f0102ecd <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01034f2:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01034f6:	83 e0 03             	and    $0x3,%eax
f01034f9:	83 c4 10             	add    $0x10,%esp
f01034fc:	66 83 f8 03          	cmp    $0x3,%ax
f0103500:	75 31                	jne    f0103533 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103502:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f0103507:	85 c0                	test   %eax,%eax
f0103509:	75 19                	jne    f0103524 <trap+0x69>
f010350b:	68 44 59 10 f0       	push   $0xf0105944
f0103510:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0103515:	68 ea 00 00 00       	push   $0xea
f010351a:	68 1d 59 10 f0       	push   $0xf010591d
f010351f:	e8 7c cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103524:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103529:	89 c7                	mov    %eax,%edi
f010352b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010352d:	8b 35 48 be 17 f0    	mov    0xf017be48,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103533:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
trap_dispatch(struct Trapframe *tf)
{
	int32_t ret_code;
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno) {
f0103539:	8b 46 28             	mov    0x28(%esi),%eax
f010353c:	83 f8 03             	cmp    $0x3,%eax
f010353f:	74 29                	je     f010356a <trap+0xaf>
f0103541:	83 f8 03             	cmp    $0x3,%eax
f0103544:	77 07                	ja     f010354d <trap+0x92>
f0103546:	83 f8 01             	cmp    $0x1,%eax
f0103549:	74 35                	je     f0103580 <trap+0xc5>
f010354b:	eb 62                	jmp    f01035af <trap+0xf4>
f010354d:	83 f8 0e             	cmp    $0xe,%eax
f0103550:	74 07                	je     f0103559 <trap+0x9e>
f0103552:	83 f8 30             	cmp    $0x30,%eax
f0103555:	74 37                	je     f010358e <trap+0xd3>
f0103557:	eb 56                	jmp    f01035af <trap+0xf4>
		case (T_PGFLT):
			page_fault_handler(tf);
f0103559:	83 ec 0c             	sub    $0xc,%esp
f010355c:	56                   	push   %esi
f010355d:	e8 18 ff ff ff       	call   f010347a <page_fault_handler>
f0103562:	83 c4 10             	add    $0x10,%esp
f0103565:	e9 80 00 00 00       	jmp    f01035ea <trap+0x12f>
			break; 
		case (T_BRKPT):
			print_trapframe(tf);
f010356a:	83 ec 0c             	sub    $0xc,%esp
f010356d:	56                   	push   %esi
f010356e:	e8 94 fd ff ff       	call   f0103307 <print_trapframe>
			monitor(tf);		
f0103573:	89 34 24             	mov    %esi,(%esp)
f0103576:	e8 a9 d1 ff ff       	call   f0100724 <monitor>
f010357b:	83 c4 10             	add    $0x10,%esp
f010357e:	eb 6a                	jmp    f01035ea <trap+0x12f>
			break;
		case (T_DEBUG):
			monitor(tf);
f0103580:	83 ec 0c             	sub    $0xc,%esp
f0103583:	56                   	push   %esi
f0103584:	e8 9b d1 ff ff       	call   f0100724 <monitor>
f0103589:	83 c4 10             	add    $0x10,%esp
f010358c:	eb 5c                	jmp    f01035ea <trap+0x12f>
			break;
		case (T_SYSCALL):
			ret_code = syscall(
f010358e:	83 ec 08             	sub    $0x8,%esp
f0103591:	ff 76 04             	pushl  0x4(%esi)
f0103594:	ff 36                	pushl  (%esi)
f0103596:	ff 76 10             	pushl  0x10(%esi)
f0103599:	ff 76 18             	pushl  0x18(%esi)
f010359c:	ff 76 14             	pushl  0x14(%esi)
f010359f:	ff 76 1c             	pushl  0x1c(%esi)
f01035a2:	e8 eb 00 00 00       	call   f0103692 <syscall>
					tf->tf_regs.reg_edx,
					tf->tf_regs.reg_ecx,
					tf->tf_regs.reg_ebx,
					tf->tf_regs.reg_edi,
					tf->tf_regs.reg_esi);
			tf->tf_regs.reg_eax = ret_code;
f01035a7:	89 46 1c             	mov    %eax,0x1c(%esi)
f01035aa:	83 c4 20             	add    $0x20,%esp
f01035ad:	eb 3b                	jmp    f01035ea <trap+0x12f>
			break;
 		default:
			// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f01035af:	83 ec 0c             	sub    $0xc,%esp
f01035b2:	56                   	push   %esi
f01035b3:	e8 4f fd ff ff       	call   f0103307 <print_trapframe>
			if (tf->tf_cs == GD_KT)
f01035b8:	83 c4 10             	add    $0x10,%esp
f01035bb:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01035c0:	75 17                	jne    f01035d9 <trap+0x11e>
				panic("unhandled trap in kernel");
f01035c2:	83 ec 04             	sub    $0x4,%esp
f01035c5:	68 4b 59 10 f0       	push   $0xf010594b
f01035ca:	68 d2 00 00 00       	push   $0xd2
f01035cf:	68 1d 59 10 f0       	push   $0xf010591d
f01035d4:	e8 c7 ca ff ff       	call   f01000a0 <_panic>
			else {
				env_destroy(curenv);
f01035d9:	83 ec 0c             	sub    $0xc,%esp
f01035dc:	ff 35 48 be 17 f0    	pushl  0xf017be48
f01035e2:	e8 cd f7 ff ff       	call   f0102db4 <env_destroy>
f01035e7:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01035ea:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f01035ef:	85 c0                	test   %eax,%eax
f01035f1:	74 06                	je     f01035f9 <trap+0x13e>
f01035f3:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01035f7:	74 19                	je     f0103612 <trap+0x157>
f01035f9:	68 cc 5a 10 f0       	push   $0xf0105acc
f01035fe:	68 b2 4b 10 f0       	push   $0xf0104bb2
f0103603:	68 fc 00 00 00       	push   $0xfc
f0103608:	68 1d 59 10 f0       	push   $0xf010591d
f010360d:	e8 8e ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103612:	83 ec 0c             	sub    $0xc,%esp
f0103615:	50                   	push   %eax
f0103616:	e8 e9 f7 ff ff       	call   f0102e04 <env_run>
f010361b:	90                   	nop

f010361c <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f010361c:	6a 00                	push   $0x0
f010361e:	6a 00                	push   $0x0
f0103620:	eb 5e                	jmp    f0103680 <_alltraps>

f0103622 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f0103622:	6a 00                	push   $0x0
f0103624:	6a 01                	push   $0x1
f0103626:	eb 58                	jmp    f0103680 <_alltraps>

f0103628 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f0103628:	6a 00                	push   $0x0
f010362a:	6a 02                	push   $0x2
f010362c:	eb 52                	jmp    f0103680 <_alltraps>

f010362e <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f010362e:	6a 00                	push   $0x0
f0103630:	6a 03                	push   $0x3
f0103632:	eb 4c                	jmp    f0103680 <_alltraps>

f0103634 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f0103634:	6a 00                	push   $0x0
f0103636:	6a 04                	push   $0x4
f0103638:	eb 46                	jmp    f0103680 <_alltraps>

f010363a <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f010363a:	6a 00                	push   $0x0
f010363c:	6a 05                	push   $0x5
f010363e:	eb 40                	jmp    f0103680 <_alltraps>

f0103640 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f0103640:	6a 00                	push   $0x0
f0103642:	6a 06                	push   $0x6
f0103644:	eb 3a                	jmp    f0103680 <_alltraps>

f0103646 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f0103646:	6a 00                	push   $0x0
f0103648:	6a 07                	push   $0x7
f010364a:	eb 34                	jmp    f0103680 <_alltraps>

f010364c <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f010364c:	6a 08                	push   $0x8
f010364e:	eb 30                	jmp    f0103680 <_alltraps>

f0103650 <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f0103650:	6a 0a                	push   $0xa
f0103652:	eb 2c                	jmp    f0103680 <_alltraps>

f0103654 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f0103654:	6a 0b                	push   $0xb
f0103656:	eb 28                	jmp    f0103680 <_alltraps>

f0103658 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f0103658:	6a 0c                	push   $0xc
f010365a:	eb 24                	jmp    f0103680 <_alltraps>

f010365c <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f010365c:	6a 0d                	push   $0xd
f010365e:	eb 20                	jmp    f0103680 <_alltraps>

f0103660 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f0103660:	6a 0e                	push   $0xe
f0103662:	eb 1c                	jmp    f0103680 <_alltraps>

f0103664 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f0103664:	6a 00                	push   $0x0
f0103666:	6a 10                	push   $0x10
f0103668:	eb 16                	jmp    f0103680 <_alltraps>

f010366a <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f010366a:	6a 11                	push   $0x11
f010366c:	eb 12                	jmp    f0103680 <_alltraps>

f010366e <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f010366e:	6a 00                	push   $0x0
f0103670:	6a 12                	push   $0x12
f0103672:	eb 0c                	jmp    f0103680 <_alltraps>

f0103674 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f0103674:	6a 00                	push   $0x0
f0103676:	6a 13                	push   $0x13
f0103678:	eb 06                	jmp    f0103680 <_alltraps>

f010367a <t_syscall>:

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f010367a:	6a 00                	push   $0x0
f010367c:	6a 30                	push   $0x30
f010367e:	eb 00                	jmp    f0103680 <_alltraps>

f0103680 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f0103680:	1e                   	push   %ds
	pushl %es
f0103681:	06                   	push   %es
	pushal 
f0103682:	60                   	pusha  

	movl $GD_KD, %eax 
f0103683:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax, %ds
f0103688:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010368a:	8e c0                	mov    %eax,%es

	push %esp
f010368c:	54                   	push   %esp
	call trap
f010368d:	e8 29 fe ff ff       	call   f01034bb <trap>

f0103692 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103692:	55                   	push   %ebp
f0103693:	89 e5                	mov    %esp,%ebp
f0103695:	83 ec 18             	sub    $0x18,%esp
f0103698:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//	panic("syscall not implemented");

	switch (syscallno) {
f010369b:	83 f8 01             	cmp    $0x1,%eax
f010369e:	74 44                	je     f01036e4 <syscall+0x52>
f01036a0:	83 f8 01             	cmp    $0x1,%eax
f01036a3:	72 0f                	jb     f01036b4 <syscall+0x22>
f01036a5:	83 f8 02             	cmp    $0x2,%eax
f01036a8:	74 41                	je     f01036eb <syscall+0x59>
f01036aa:	83 f8 03             	cmp    $0x3,%eax
f01036ad:	74 46                	je     f01036f5 <syscall+0x63>
f01036af:	e9 a6 00 00 00       	jmp    f010375a <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not:.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, 0);
f01036b4:	6a 00                	push   $0x0
f01036b6:	ff 75 10             	pushl  0x10(%ebp)
f01036b9:	ff 75 0c             	pushl  0xc(%ebp)
f01036bc:	ff 35 48 be 17 f0    	pushl  0xf017be48
f01036c2:	e8 c8 f0 ff ff       	call   f010278f <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01036c7:	83 c4 0c             	add    $0xc,%esp
f01036ca:	ff 75 0c             	pushl  0xc(%ebp)
f01036cd:	ff 75 10             	pushl  0x10(%ebp)
f01036d0:	68 50 5b 10 f0       	push   $0xf0105b50
f01036d5:	e8 f3 f7 ff ff       	call   f0102ecd <cprintf>
f01036da:	83 c4 10             	add    $0x10,%esp
	//	panic("syscall not implemented");

	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
f01036dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01036e2:	eb 7b                	jmp    f010375f <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01036e4:	e8 cc cd ff ff       	call   f01004b5 <cons_getc>
	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
f01036e9:	eb 74                	jmp    f010375f <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01036eb:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f01036f0:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
		case (SYS_getenvid):
			return sys_getenvid();
f01036f3:	eb 6a                	jmp    f010375f <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01036f5:	83 ec 04             	sub    $0x4,%esp
f01036f8:	6a 01                	push   $0x1
f01036fa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036fd:	50                   	push   %eax
f01036fe:	ff 75 0c             	pushl  0xc(%ebp)
f0103701:	e8 59 f1 ff ff       	call   f010285f <envid2env>
f0103706:	83 c4 10             	add    $0x10,%esp
f0103709:	85 c0                	test   %eax,%eax
f010370b:	78 52                	js     f010375f <syscall+0xcd>
		return r;
	if (e == curenv)
f010370d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103710:	8b 15 48 be 17 f0    	mov    0xf017be48,%edx
f0103716:	39 d0                	cmp    %edx,%eax
f0103718:	75 15                	jne    f010372f <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010371a:	83 ec 08             	sub    $0x8,%esp
f010371d:	ff 70 48             	pushl  0x48(%eax)
f0103720:	68 55 5b 10 f0       	push   $0xf0105b55
f0103725:	e8 a3 f7 ff ff       	call   f0102ecd <cprintf>
f010372a:	83 c4 10             	add    $0x10,%esp
f010372d:	eb 16                	jmp    f0103745 <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010372f:	83 ec 04             	sub    $0x4,%esp
f0103732:	ff 70 48             	pushl  0x48(%eax)
f0103735:	ff 72 48             	pushl  0x48(%edx)
f0103738:	68 70 5b 10 f0       	push   $0xf0105b70
f010373d:	e8 8b f7 ff ff       	call   f0102ecd <cprintf>
f0103742:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103745:	83 ec 0c             	sub    $0xc,%esp
f0103748:	ff 75 f4             	pushl  -0xc(%ebp)
f010374b:	e8 64 f6 ff ff       	call   f0102db4 <env_destroy>
f0103750:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103753:	b8 00 00 00 00       	mov    $0x0,%eax
f0103758:	eb 05                	jmp    f010375f <syscall+0xcd>
		case (SYS_getenvid):
			return sys_getenvid();
		case (SYS_env_destroy):
			return sys_env_destroy(a1);
		default:
			return -E_INVAL;
f010375a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f010375f:	c9                   	leave  
f0103760:	c3                   	ret    

f0103761 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103761:	55                   	push   %ebp
f0103762:	89 e5                	mov    %esp,%ebp
f0103764:	57                   	push   %edi
f0103765:	56                   	push   %esi
f0103766:	53                   	push   %ebx
f0103767:	83 ec 14             	sub    $0x14,%esp
f010376a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010376d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103770:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103773:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103776:	8b 1a                	mov    (%edx),%ebx
f0103778:	8b 01                	mov    (%ecx),%eax
f010377a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010377d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103784:	eb 7f                	jmp    f0103805 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103786:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103789:	01 d8                	add    %ebx,%eax
f010378b:	89 c6                	mov    %eax,%esi
f010378d:	c1 ee 1f             	shr    $0x1f,%esi
f0103790:	01 c6                	add    %eax,%esi
f0103792:	d1 fe                	sar    %esi
f0103794:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103797:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010379a:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010379d:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010379f:	eb 03                	jmp    f01037a4 <stab_binsearch+0x43>
			m--;
f01037a1:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037a4:	39 c3                	cmp    %eax,%ebx
f01037a6:	7f 0d                	jg     f01037b5 <stab_binsearch+0x54>
f01037a8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01037ac:	83 ea 0c             	sub    $0xc,%edx
f01037af:	39 f9                	cmp    %edi,%ecx
f01037b1:	75 ee                	jne    f01037a1 <stab_binsearch+0x40>
f01037b3:	eb 05                	jmp    f01037ba <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01037b5:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01037b8:	eb 4b                	jmp    f0103805 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01037ba:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01037bd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037c0:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01037c4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01037c7:	76 11                	jbe    f01037da <stab_binsearch+0x79>
			*region_left = m;
f01037c9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01037cc:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01037ce:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037d1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01037d8:	eb 2b                	jmp    f0103805 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01037da:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01037dd:	73 14                	jae    f01037f3 <stab_binsearch+0x92>
			*region_right = m - 1;
f01037df:	83 e8 01             	sub    $0x1,%eax
f01037e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037e5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01037e8:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037ea:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01037f1:	eb 12                	jmp    f0103805 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01037f3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01037f6:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01037f8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01037fc:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037fe:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103805:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103808:	0f 8e 78 ff ff ff    	jle    f0103786 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010380e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103812:	75 0f                	jne    f0103823 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103814:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103817:	8b 00                	mov    (%eax),%eax
f0103819:	83 e8 01             	sub    $0x1,%eax
f010381c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010381f:	89 06                	mov    %eax,(%esi)
f0103821:	eb 2c                	jmp    f010384f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103823:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103826:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103828:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010382b:	8b 0e                	mov    (%esi),%ecx
f010382d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103830:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103833:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103836:	eb 03                	jmp    f010383b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103838:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010383b:	39 c8                	cmp    %ecx,%eax
f010383d:	7e 0b                	jle    f010384a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010383f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103843:	83 ea 0c             	sub    $0xc,%edx
f0103846:	39 df                	cmp    %ebx,%edi
f0103848:	75 ee                	jne    f0103838 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010384a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010384d:	89 06                	mov    %eax,(%esi)
	}
}
f010384f:	83 c4 14             	add    $0x14,%esp
f0103852:	5b                   	pop    %ebx
f0103853:	5e                   	pop    %esi
f0103854:	5f                   	pop    %edi
f0103855:	5d                   	pop    %ebp
f0103856:	c3                   	ret    

f0103857 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103857:	55                   	push   %ebp
f0103858:	89 e5                	mov    %esp,%ebp
f010385a:	57                   	push   %edi
f010385b:	56                   	push   %esi
f010385c:	53                   	push   %ebx
f010385d:	83 ec 2c             	sub    $0x2c,%esp
f0103860:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103863:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103866:	c7 06 88 5b 10 f0    	movl   $0xf0105b88,(%esi)
	info->eip_line = 0;
f010386c:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103873:	c7 46 08 88 5b 10 f0 	movl   $0xf0105b88,0x8(%esi)
	info->eip_fn_namelen = 9;
f010387a:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103881:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103884:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010388b:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103891:	77 21                	ja     f01038b4 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103893:	a1 00 00 20 00       	mov    0x200000,%eax
f0103898:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f010389b:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01038a0:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01038a6:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01038a9:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f01038af:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01038b2:	eb 1a                	jmp    f01038ce <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01038b4:	c7 45 d0 7f fe 10 f0 	movl   $0xf010fe7f,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01038bb:	c7 45 cc 49 d4 10 f0 	movl   $0xf010d449,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01038c2:	b8 48 d4 10 f0       	mov    $0xf010d448,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01038c7:	c7 45 d4 b0 5d 10 f0 	movl   $0xf0105db0,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01038ce:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01038d1:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f01038d4:	0f 83 2b 01 00 00    	jae    f0103a05 <debuginfo_eip+0x1ae>
f01038da:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01038de:	0f 85 28 01 00 00    	jne    f0103a0c <debuginfo_eip+0x1b5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01038e4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01038eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01038ee:	29 d8                	sub    %ebx,%eax
f01038f0:	c1 f8 02             	sar    $0x2,%eax
f01038f3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01038f9:	83 e8 01             	sub    $0x1,%eax
f01038fc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01038ff:	57                   	push   %edi
f0103900:	6a 64                	push   $0x64
f0103902:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103905:	89 c1                	mov    %eax,%ecx
f0103907:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010390a:	89 d8                	mov    %ebx,%eax
f010390c:	e8 50 fe ff ff       	call   f0103761 <stab_binsearch>
	if (lfile == 0)
f0103911:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103914:	83 c4 08             	add    $0x8,%esp
f0103917:	85 c0                	test   %eax,%eax
f0103919:	0f 84 f4 00 00 00    	je     f0103a13 <debuginfo_eip+0x1bc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010391f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103922:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103925:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103928:	57                   	push   %edi
f0103929:	6a 24                	push   $0x24
f010392b:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010392e:	89 c1                	mov    %eax,%ecx
f0103930:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103933:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0103936:	89 d8                	mov    %ebx,%eax
f0103938:	e8 24 fe ff ff       	call   f0103761 <stab_binsearch>

	if (lfun <= rfun) {
f010393d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103940:	83 c4 08             	add    $0x8,%esp
f0103943:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103946:	7f 24                	jg     f010396c <debuginfo_eip+0x115>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103948:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010394b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010394e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103951:	8b 02                	mov    (%edx),%eax
f0103953:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103956:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103959:	29 f9                	sub    %edi,%ecx
f010395b:	39 c8                	cmp    %ecx,%eax
f010395d:	73 05                	jae    f0103964 <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010395f:	01 f8                	add    %edi,%eax
f0103961:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103964:	8b 42 08             	mov    0x8(%edx),%eax
f0103967:	89 46 10             	mov    %eax,0x10(%esi)
f010396a:	eb 06                	jmp    f0103972 <debuginfo_eip+0x11b>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010396c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010396f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103972:	83 ec 08             	sub    $0x8,%esp
f0103975:	6a 3a                	push   $0x3a
f0103977:	ff 76 08             	pushl  0x8(%esi)
f010397a:	e8 9a 08 00 00       	call   f0104219 <strfind>
f010397f:	2b 46 08             	sub    0x8(%esi),%eax
f0103982:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103985:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103988:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010398b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010398e:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0103991:	83 c4 10             	add    $0x10,%esp
f0103994:	eb 06                	jmp    f010399c <debuginfo_eip+0x145>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103996:	83 eb 01             	sub    $0x1,%ebx
f0103999:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010399c:	39 fb                	cmp    %edi,%ebx
f010399e:	7c 2d                	jl     f01039cd <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01039a0:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01039a4:	80 fa 84             	cmp    $0x84,%dl
f01039a7:	74 0b                	je     f01039b4 <debuginfo_eip+0x15d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01039a9:	80 fa 64             	cmp    $0x64,%dl
f01039ac:	75 e8                	jne    f0103996 <debuginfo_eip+0x13f>
f01039ae:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01039b2:	74 e2                	je     f0103996 <debuginfo_eip+0x13f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01039b4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01039b7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01039ba:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01039bd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01039c0:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01039c3:	29 f8                	sub    %edi,%eax
f01039c5:	39 c2                	cmp    %eax,%edx
f01039c7:	73 04                	jae    f01039cd <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01039c9:	01 fa                	add    %edi,%edx
f01039cb:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01039cd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01039d0:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01039d3:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01039d8:	39 cb                	cmp    %ecx,%ebx
f01039da:	7d 43                	jge    f0103a1f <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
f01039dc:	8d 53 01             	lea    0x1(%ebx),%edx
f01039df:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01039e2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01039e5:	8d 04 87             	lea    (%edi,%eax,4),%eax
f01039e8:	eb 07                	jmp    f01039f1 <debuginfo_eip+0x19a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01039ea:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01039ee:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01039f1:	39 ca                	cmp    %ecx,%edx
f01039f3:	74 25                	je     f0103a1a <debuginfo_eip+0x1c3>
f01039f5:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01039f8:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01039fc:	74 ec                	je     f01039ea <debuginfo_eip+0x193>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01039fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a03:	eb 1a                	jmp    f0103a1f <debuginfo_eip+0x1c8>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103a05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a0a:	eb 13                	jmp    f0103a1f <debuginfo_eip+0x1c8>
f0103a0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a11:	eb 0c                	jmp    f0103a1f <debuginfo_eip+0x1c8>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103a13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a18:	eb 05                	jmp    f0103a1f <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103a1a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a22:	5b                   	pop    %ebx
f0103a23:	5e                   	pop    %esi
f0103a24:	5f                   	pop    %edi
f0103a25:	5d                   	pop    %ebp
f0103a26:	c3                   	ret    

f0103a27 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103a27:	55                   	push   %ebp
f0103a28:	89 e5                	mov    %esp,%ebp
f0103a2a:	57                   	push   %edi
f0103a2b:	56                   	push   %esi
f0103a2c:	53                   	push   %ebx
f0103a2d:	83 ec 1c             	sub    $0x1c,%esp
f0103a30:	89 c7                	mov    %eax,%edi
f0103a32:	89 d6                	mov    %edx,%esi
f0103a34:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a37:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a3a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a3d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103a40:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103a43:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a48:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103a4b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103a4e:	39 d3                	cmp    %edx,%ebx
f0103a50:	72 05                	jb     f0103a57 <printnum+0x30>
f0103a52:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103a55:	77 45                	ja     f0103a9c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103a57:	83 ec 0c             	sub    $0xc,%esp
f0103a5a:	ff 75 18             	pushl  0x18(%ebp)
f0103a5d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a60:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103a63:	53                   	push   %ebx
f0103a64:	ff 75 10             	pushl  0x10(%ebp)
f0103a67:	83 ec 08             	sub    $0x8,%esp
f0103a6a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a6d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a70:	ff 75 dc             	pushl  -0x24(%ebp)
f0103a73:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a76:	e8 c5 09 00 00       	call   f0104440 <__udivdi3>
f0103a7b:	83 c4 18             	add    $0x18,%esp
f0103a7e:	52                   	push   %edx
f0103a7f:	50                   	push   %eax
f0103a80:	89 f2                	mov    %esi,%edx
f0103a82:	89 f8                	mov    %edi,%eax
f0103a84:	e8 9e ff ff ff       	call   f0103a27 <printnum>
f0103a89:	83 c4 20             	add    $0x20,%esp
f0103a8c:	eb 18                	jmp    f0103aa6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103a8e:	83 ec 08             	sub    $0x8,%esp
f0103a91:	56                   	push   %esi
f0103a92:	ff 75 18             	pushl  0x18(%ebp)
f0103a95:	ff d7                	call   *%edi
f0103a97:	83 c4 10             	add    $0x10,%esp
f0103a9a:	eb 03                	jmp    f0103a9f <printnum+0x78>
f0103a9c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103a9f:	83 eb 01             	sub    $0x1,%ebx
f0103aa2:	85 db                	test   %ebx,%ebx
f0103aa4:	7f e8                	jg     f0103a8e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103aa6:	83 ec 08             	sub    $0x8,%esp
f0103aa9:	56                   	push   %esi
f0103aaa:	83 ec 04             	sub    $0x4,%esp
f0103aad:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103ab0:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ab3:	ff 75 dc             	pushl  -0x24(%ebp)
f0103ab6:	ff 75 d8             	pushl  -0x28(%ebp)
f0103ab9:	e8 b2 0a 00 00       	call   f0104570 <__umoddi3>
f0103abe:	83 c4 14             	add    $0x14,%esp
f0103ac1:	0f be 80 92 5b 10 f0 	movsbl -0xfefa46e(%eax),%eax
f0103ac8:	50                   	push   %eax
f0103ac9:	ff d7                	call   *%edi
}
f0103acb:	83 c4 10             	add    $0x10,%esp
f0103ace:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ad1:	5b                   	pop    %ebx
f0103ad2:	5e                   	pop    %esi
f0103ad3:	5f                   	pop    %edi
f0103ad4:	5d                   	pop    %ebp
f0103ad5:	c3                   	ret    

f0103ad6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103ad6:	55                   	push   %ebp
f0103ad7:	89 e5                	mov    %esp,%ebp
f0103ad9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103adc:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103ae0:	8b 10                	mov    (%eax),%edx
f0103ae2:	3b 50 04             	cmp    0x4(%eax),%edx
f0103ae5:	73 0a                	jae    f0103af1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103ae7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103aea:	89 08                	mov    %ecx,(%eax)
f0103aec:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aef:	88 02                	mov    %al,(%edx)
}
f0103af1:	5d                   	pop    %ebp
f0103af2:	c3                   	ret    

f0103af3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103af3:	55                   	push   %ebp
f0103af4:	89 e5                	mov    %esp,%ebp
f0103af6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103af9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103afc:	50                   	push   %eax
f0103afd:	ff 75 10             	pushl  0x10(%ebp)
f0103b00:	ff 75 0c             	pushl  0xc(%ebp)
f0103b03:	ff 75 08             	pushl  0x8(%ebp)
f0103b06:	e8 05 00 00 00       	call   f0103b10 <vprintfmt>
	va_end(ap);
}
f0103b0b:	83 c4 10             	add    $0x10,%esp
f0103b0e:	c9                   	leave  
f0103b0f:	c3                   	ret    

f0103b10 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103b10:	55                   	push   %ebp
f0103b11:	89 e5                	mov    %esp,%ebp
f0103b13:	57                   	push   %edi
f0103b14:	56                   	push   %esi
f0103b15:	53                   	push   %ebx
f0103b16:	83 ec 2c             	sub    $0x2c,%esp
f0103b19:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b1c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b1f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103b22:	eb 12                	jmp    f0103b36 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103b24:	85 c0                	test   %eax,%eax
f0103b26:	0f 84 42 04 00 00    	je     f0103f6e <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103b2c:	83 ec 08             	sub    $0x8,%esp
f0103b2f:	53                   	push   %ebx
f0103b30:	50                   	push   %eax
f0103b31:	ff d6                	call   *%esi
f0103b33:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103b36:	83 c7 01             	add    $0x1,%edi
f0103b39:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103b3d:	83 f8 25             	cmp    $0x25,%eax
f0103b40:	75 e2                	jne    f0103b24 <vprintfmt+0x14>
f0103b42:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103b46:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103b4d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103b54:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103b5b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103b60:	eb 07                	jmp    f0103b69 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b62:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103b65:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b69:	8d 47 01             	lea    0x1(%edi),%eax
f0103b6c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b6f:	0f b6 07             	movzbl (%edi),%eax
f0103b72:	0f b6 d0             	movzbl %al,%edx
f0103b75:	83 e8 23             	sub    $0x23,%eax
f0103b78:	3c 55                	cmp    $0x55,%al
f0103b7a:	0f 87 d3 03 00 00    	ja     f0103f53 <vprintfmt+0x443>
f0103b80:	0f b6 c0             	movzbl %al,%eax
f0103b83:	ff 24 85 20 5c 10 f0 	jmp    *-0xfefa3e0(,%eax,4)
f0103b8a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103b8d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103b91:	eb d6                	jmp    f0103b69 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b96:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b9b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103b9e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103ba1:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103ba5:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103ba8:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103bab:	83 f9 09             	cmp    $0x9,%ecx
f0103bae:	77 3f                	ja     f0103bef <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103bb0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103bb3:	eb e9                	jmp    f0103b9e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103bb5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bb8:	8b 00                	mov    (%eax),%eax
f0103bba:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103bbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bc0:	8d 40 04             	lea    0x4(%eax),%eax
f0103bc3:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bc6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103bc9:	eb 2a                	jmp    f0103bf5 <vprintfmt+0xe5>
f0103bcb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bce:	85 c0                	test   %eax,%eax
f0103bd0:	ba 00 00 00 00       	mov    $0x0,%edx
f0103bd5:	0f 49 d0             	cmovns %eax,%edx
f0103bd8:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bdb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103bde:	eb 89                	jmp    f0103b69 <vprintfmt+0x59>
f0103be0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103be3:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103bea:	e9 7a ff ff ff       	jmp    f0103b69 <vprintfmt+0x59>
f0103bef:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103bf2:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103bf5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103bf9:	0f 89 6a ff ff ff    	jns    f0103b69 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103bff:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103c02:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103c05:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103c0c:	e9 58 ff ff ff       	jmp    f0103b69 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103c11:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c14:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103c17:	e9 4d ff ff ff       	jmp    f0103b69 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103c1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c1f:	8d 78 04             	lea    0x4(%eax),%edi
f0103c22:	83 ec 08             	sub    $0x8,%esp
f0103c25:	53                   	push   %ebx
f0103c26:	ff 30                	pushl  (%eax)
f0103c28:	ff d6                	call   *%esi
			break;
f0103c2a:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103c2d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103c33:	e9 fe fe ff ff       	jmp    f0103b36 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103c38:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c3b:	8d 78 04             	lea    0x4(%eax),%edi
f0103c3e:	8b 00                	mov    (%eax),%eax
f0103c40:	99                   	cltd   
f0103c41:	31 d0                	xor    %edx,%eax
f0103c43:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103c45:	83 f8 07             	cmp    $0x7,%eax
f0103c48:	7f 0b                	jg     f0103c55 <vprintfmt+0x145>
f0103c4a:	8b 14 85 80 5d 10 f0 	mov    -0xfefa280(,%eax,4),%edx
f0103c51:	85 d2                	test   %edx,%edx
f0103c53:	75 1b                	jne    f0103c70 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103c55:	50                   	push   %eax
f0103c56:	68 aa 5b 10 f0       	push   $0xf0105baa
f0103c5b:	53                   	push   %ebx
f0103c5c:	56                   	push   %esi
f0103c5d:	e8 91 fe ff ff       	call   f0103af3 <printfmt>
f0103c62:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103c65:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103c6b:	e9 c6 fe ff ff       	jmp    f0103b36 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103c70:	52                   	push   %edx
f0103c71:	68 c4 4b 10 f0       	push   $0xf0104bc4
f0103c76:	53                   	push   %ebx
f0103c77:	56                   	push   %esi
f0103c78:	e8 76 fe ff ff       	call   f0103af3 <printfmt>
f0103c7d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103c80:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c86:	e9 ab fe ff ff       	jmp    f0103b36 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103c8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c8e:	83 c0 04             	add    $0x4,%eax
f0103c91:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103c94:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c97:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103c99:	85 ff                	test   %edi,%edi
f0103c9b:	b8 a3 5b 10 f0       	mov    $0xf0105ba3,%eax
f0103ca0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103ca3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103ca7:	0f 8e 94 00 00 00    	jle    f0103d41 <vprintfmt+0x231>
f0103cad:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103cb1:	0f 84 98 00 00 00    	je     f0103d4f <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103cb7:	83 ec 08             	sub    $0x8,%esp
f0103cba:	ff 75 d0             	pushl  -0x30(%ebp)
f0103cbd:	57                   	push   %edi
f0103cbe:	e8 0c 04 00 00       	call   f01040cf <strnlen>
f0103cc3:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103cc6:	29 c1                	sub    %eax,%ecx
f0103cc8:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103ccb:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103cce:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103cd2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103cd5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103cd8:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103cda:	eb 0f                	jmp    f0103ceb <vprintfmt+0x1db>
					putch(padc, putdat);
f0103cdc:	83 ec 08             	sub    $0x8,%esp
f0103cdf:	53                   	push   %ebx
f0103ce0:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ce3:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ce5:	83 ef 01             	sub    $0x1,%edi
f0103ce8:	83 c4 10             	add    $0x10,%esp
f0103ceb:	85 ff                	test   %edi,%edi
f0103ced:	7f ed                	jg     f0103cdc <vprintfmt+0x1cc>
f0103cef:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103cf2:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103cf5:	85 c9                	test   %ecx,%ecx
f0103cf7:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cfc:	0f 49 c1             	cmovns %ecx,%eax
f0103cff:	29 c1                	sub    %eax,%ecx
f0103d01:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d04:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d07:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d0a:	89 cb                	mov    %ecx,%ebx
f0103d0c:	eb 4d                	jmp    f0103d5b <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103d0e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103d12:	74 1b                	je     f0103d2f <vprintfmt+0x21f>
f0103d14:	0f be c0             	movsbl %al,%eax
f0103d17:	83 e8 20             	sub    $0x20,%eax
f0103d1a:	83 f8 5e             	cmp    $0x5e,%eax
f0103d1d:	76 10                	jbe    f0103d2f <vprintfmt+0x21f>
					putch('?', putdat);
f0103d1f:	83 ec 08             	sub    $0x8,%esp
f0103d22:	ff 75 0c             	pushl  0xc(%ebp)
f0103d25:	6a 3f                	push   $0x3f
f0103d27:	ff 55 08             	call   *0x8(%ebp)
f0103d2a:	83 c4 10             	add    $0x10,%esp
f0103d2d:	eb 0d                	jmp    f0103d3c <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103d2f:	83 ec 08             	sub    $0x8,%esp
f0103d32:	ff 75 0c             	pushl  0xc(%ebp)
f0103d35:	52                   	push   %edx
f0103d36:	ff 55 08             	call   *0x8(%ebp)
f0103d39:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103d3c:	83 eb 01             	sub    $0x1,%ebx
f0103d3f:	eb 1a                	jmp    f0103d5b <vprintfmt+0x24b>
f0103d41:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d44:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d47:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d4a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d4d:	eb 0c                	jmp    f0103d5b <vprintfmt+0x24b>
f0103d4f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d52:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d55:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d58:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d5b:	83 c7 01             	add    $0x1,%edi
f0103d5e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103d62:	0f be d0             	movsbl %al,%edx
f0103d65:	85 d2                	test   %edx,%edx
f0103d67:	74 23                	je     f0103d8c <vprintfmt+0x27c>
f0103d69:	85 f6                	test   %esi,%esi
f0103d6b:	78 a1                	js     f0103d0e <vprintfmt+0x1fe>
f0103d6d:	83 ee 01             	sub    $0x1,%esi
f0103d70:	79 9c                	jns    f0103d0e <vprintfmt+0x1fe>
f0103d72:	89 df                	mov    %ebx,%edi
f0103d74:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d77:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d7a:	eb 18                	jmp    f0103d94 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103d7c:	83 ec 08             	sub    $0x8,%esp
f0103d7f:	53                   	push   %ebx
f0103d80:	6a 20                	push   $0x20
f0103d82:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103d84:	83 ef 01             	sub    $0x1,%edi
f0103d87:	83 c4 10             	add    $0x10,%esp
f0103d8a:	eb 08                	jmp    f0103d94 <vprintfmt+0x284>
f0103d8c:	89 df                	mov    %ebx,%edi
f0103d8e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d91:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d94:	85 ff                	test   %edi,%edi
f0103d96:	7f e4                	jg     f0103d7c <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103d98:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103d9b:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d9e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103da1:	e9 90 fd ff ff       	jmp    f0103b36 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103da6:	83 f9 01             	cmp    $0x1,%ecx
f0103da9:	7e 19                	jle    f0103dc4 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103dab:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dae:	8b 50 04             	mov    0x4(%eax),%edx
f0103db1:	8b 00                	mov    (%eax),%eax
f0103db3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103db6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103db9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dbc:	8d 40 08             	lea    0x8(%eax),%eax
f0103dbf:	89 45 14             	mov    %eax,0x14(%ebp)
f0103dc2:	eb 38                	jmp    f0103dfc <vprintfmt+0x2ec>
	else if (lflag)
f0103dc4:	85 c9                	test   %ecx,%ecx
f0103dc6:	74 1b                	je     f0103de3 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103dc8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dcb:	8b 00                	mov    (%eax),%eax
f0103dcd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103dd0:	89 c1                	mov    %eax,%ecx
f0103dd2:	c1 f9 1f             	sar    $0x1f,%ecx
f0103dd5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103dd8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ddb:	8d 40 04             	lea    0x4(%eax),%eax
f0103dde:	89 45 14             	mov    %eax,0x14(%ebp)
f0103de1:	eb 19                	jmp    f0103dfc <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103de3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103de6:	8b 00                	mov    (%eax),%eax
f0103de8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103deb:	89 c1                	mov    %eax,%ecx
f0103ded:	c1 f9 1f             	sar    $0x1f,%ecx
f0103df0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103df3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103df6:	8d 40 04             	lea    0x4(%eax),%eax
f0103df9:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103dfc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103dff:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103e02:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103e07:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103e0b:	0f 89 0e 01 00 00    	jns    f0103f1f <vprintfmt+0x40f>
				putch('-', putdat);
f0103e11:	83 ec 08             	sub    $0x8,%esp
f0103e14:	53                   	push   %ebx
f0103e15:	6a 2d                	push   $0x2d
f0103e17:	ff d6                	call   *%esi
				num = -(long long) num;
f0103e19:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103e1c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103e1f:	f7 da                	neg    %edx
f0103e21:	83 d1 00             	adc    $0x0,%ecx
f0103e24:	f7 d9                	neg    %ecx
f0103e26:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103e29:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e2e:	e9 ec 00 00 00       	jmp    f0103f1f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103e33:	83 f9 01             	cmp    $0x1,%ecx
f0103e36:	7e 18                	jle    f0103e50 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103e38:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e3b:	8b 10                	mov    (%eax),%edx
f0103e3d:	8b 48 04             	mov    0x4(%eax),%ecx
f0103e40:	8d 40 08             	lea    0x8(%eax),%eax
f0103e43:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103e46:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e4b:	e9 cf 00 00 00       	jmp    f0103f1f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103e50:	85 c9                	test   %ecx,%ecx
f0103e52:	74 1a                	je     f0103e6e <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103e54:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e57:	8b 10                	mov    (%eax),%edx
f0103e59:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e5e:	8d 40 04             	lea    0x4(%eax),%eax
f0103e61:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103e64:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e69:	e9 b1 00 00 00       	jmp    f0103f1f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103e6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e71:	8b 10                	mov    (%eax),%edx
f0103e73:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e78:	8d 40 04             	lea    0x4(%eax),%eax
f0103e7b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103e7e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e83:	e9 97 00 00 00       	jmp    f0103f1f <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103e88:	83 ec 08             	sub    $0x8,%esp
f0103e8b:	53                   	push   %ebx
f0103e8c:	6a 58                	push   $0x58
f0103e8e:	ff d6                	call   *%esi
			putch('X', putdat);
f0103e90:	83 c4 08             	add    $0x8,%esp
f0103e93:	53                   	push   %ebx
f0103e94:	6a 58                	push   $0x58
f0103e96:	ff d6                	call   *%esi
			putch('X', putdat);
f0103e98:	83 c4 08             	add    $0x8,%esp
f0103e9b:	53                   	push   %ebx
f0103e9c:	6a 58                	push   $0x58
f0103e9e:	ff d6                	call   *%esi
			break;
f0103ea0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ea3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103ea6:	e9 8b fc ff ff       	jmp    f0103b36 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103eab:	83 ec 08             	sub    $0x8,%esp
f0103eae:	53                   	push   %ebx
f0103eaf:	6a 30                	push   $0x30
f0103eb1:	ff d6                	call   *%esi
			putch('x', putdat);
f0103eb3:	83 c4 08             	add    $0x8,%esp
f0103eb6:	53                   	push   %ebx
f0103eb7:	6a 78                	push   $0x78
f0103eb9:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103ebb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ebe:	8b 10                	mov    (%eax),%edx
f0103ec0:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103ec5:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103ec8:	8d 40 04             	lea    0x4(%eax),%eax
f0103ecb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103ece:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103ed3:	eb 4a                	jmp    f0103f1f <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103ed5:	83 f9 01             	cmp    $0x1,%ecx
f0103ed8:	7e 15                	jle    f0103eef <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0103eda:	8b 45 14             	mov    0x14(%ebp),%eax
f0103edd:	8b 10                	mov    (%eax),%edx
f0103edf:	8b 48 04             	mov    0x4(%eax),%ecx
f0103ee2:	8d 40 08             	lea    0x8(%eax),%eax
f0103ee5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103ee8:	b8 10 00 00 00       	mov    $0x10,%eax
f0103eed:	eb 30                	jmp    f0103f1f <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103eef:	85 c9                	test   %ecx,%ecx
f0103ef1:	74 17                	je     f0103f0a <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0103ef3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ef6:	8b 10                	mov    (%eax),%edx
f0103ef8:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103efd:	8d 40 04             	lea    0x4(%eax),%eax
f0103f00:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103f03:	b8 10 00 00 00       	mov    $0x10,%eax
f0103f08:	eb 15                	jmp    f0103f1f <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103f0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f0d:	8b 10                	mov    (%eax),%edx
f0103f0f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103f14:	8d 40 04             	lea    0x4(%eax),%eax
f0103f17:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103f1a:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103f1f:	83 ec 0c             	sub    $0xc,%esp
f0103f22:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103f26:	57                   	push   %edi
f0103f27:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f2a:	50                   	push   %eax
f0103f2b:	51                   	push   %ecx
f0103f2c:	52                   	push   %edx
f0103f2d:	89 da                	mov    %ebx,%edx
f0103f2f:	89 f0                	mov    %esi,%eax
f0103f31:	e8 f1 fa ff ff       	call   f0103a27 <printnum>
			break;
f0103f36:	83 c4 20             	add    $0x20,%esp
f0103f39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f3c:	e9 f5 fb ff ff       	jmp    f0103b36 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103f41:	83 ec 08             	sub    $0x8,%esp
f0103f44:	53                   	push   %ebx
f0103f45:	52                   	push   %edx
f0103f46:	ff d6                	call   *%esi
			break;
f0103f48:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103f4e:	e9 e3 fb ff ff       	jmp    f0103b36 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103f53:	83 ec 08             	sub    $0x8,%esp
f0103f56:	53                   	push   %ebx
f0103f57:	6a 25                	push   $0x25
f0103f59:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103f5b:	83 c4 10             	add    $0x10,%esp
f0103f5e:	eb 03                	jmp    f0103f63 <vprintfmt+0x453>
f0103f60:	83 ef 01             	sub    $0x1,%edi
f0103f63:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103f67:	75 f7                	jne    f0103f60 <vprintfmt+0x450>
f0103f69:	e9 c8 fb ff ff       	jmp    f0103b36 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103f6e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f71:	5b                   	pop    %ebx
f0103f72:	5e                   	pop    %esi
f0103f73:	5f                   	pop    %edi
f0103f74:	5d                   	pop    %ebp
f0103f75:	c3                   	ret    

f0103f76 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103f76:	55                   	push   %ebp
f0103f77:	89 e5                	mov    %esp,%ebp
f0103f79:	83 ec 18             	sub    $0x18,%esp
f0103f7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f7f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103f82:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103f85:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103f89:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103f8c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103f93:	85 c0                	test   %eax,%eax
f0103f95:	74 26                	je     f0103fbd <vsnprintf+0x47>
f0103f97:	85 d2                	test   %edx,%edx
f0103f99:	7e 22                	jle    f0103fbd <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103f9b:	ff 75 14             	pushl  0x14(%ebp)
f0103f9e:	ff 75 10             	pushl  0x10(%ebp)
f0103fa1:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103fa4:	50                   	push   %eax
f0103fa5:	68 d6 3a 10 f0       	push   $0xf0103ad6
f0103faa:	e8 61 fb ff ff       	call   f0103b10 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103faf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103fb2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103fb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103fb8:	83 c4 10             	add    $0x10,%esp
f0103fbb:	eb 05                	jmp    f0103fc2 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103fbd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103fc2:	c9                   	leave  
f0103fc3:	c3                   	ret    

f0103fc4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103fc4:	55                   	push   %ebp
f0103fc5:	89 e5                	mov    %esp,%ebp
f0103fc7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103fca:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103fcd:	50                   	push   %eax
f0103fce:	ff 75 10             	pushl  0x10(%ebp)
f0103fd1:	ff 75 0c             	pushl  0xc(%ebp)
f0103fd4:	ff 75 08             	pushl  0x8(%ebp)
f0103fd7:	e8 9a ff ff ff       	call   f0103f76 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103fdc:	c9                   	leave  
f0103fdd:	c3                   	ret    

f0103fde <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103fde:	55                   	push   %ebp
f0103fdf:	89 e5                	mov    %esp,%ebp
f0103fe1:	57                   	push   %edi
f0103fe2:	56                   	push   %esi
f0103fe3:	53                   	push   %ebx
f0103fe4:	83 ec 0c             	sub    $0xc,%esp
f0103fe7:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103fea:	85 c0                	test   %eax,%eax
f0103fec:	74 11                	je     f0103fff <readline+0x21>
		cprintf("%s", prompt);
f0103fee:	83 ec 08             	sub    $0x8,%esp
f0103ff1:	50                   	push   %eax
f0103ff2:	68 c4 4b 10 f0       	push   $0xf0104bc4
f0103ff7:	e8 d1 ee ff ff       	call   f0102ecd <cprintf>
f0103ffc:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103fff:	83 ec 0c             	sub    $0xc,%esp
f0104002:	6a 00                	push   $0x0
f0104004:	e8 1f c6 ff ff       	call   f0100628 <iscons>
f0104009:	89 c7                	mov    %eax,%edi
f010400b:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010400e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104013:	e8 ff c5 ff ff       	call   f0100617 <getchar>
f0104018:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010401a:	85 c0                	test   %eax,%eax
f010401c:	79 18                	jns    f0104036 <readline+0x58>
			cprintf("read error: %e\n", c);
f010401e:	83 ec 08             	sub    $0x8,%esp
f0104021:	50                   	push   %eax
f0104022:	68 a0 5d 10 f0       	push   $0xf0105da0
f0104027:	e8 a1 ee ff ff       	call   f0102ecd <cprintf>
			return NULL;
f010402c:	83 c4 10             	add    $0x10,%esp
f010402f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104034:	eb 79                	jmp    f01040af <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104036:	83 f8 08             	cmp    $0x8,%eax
f0104039:	0f 94 c2             	sete   %dl
f010403c:	83 f8 7f             	cmp    $0x7f,%eax
f010403f:	0f 94 c0             	sete   %al
f0104042:	08 c2                	or     %al,%dl
f0104044:	74 1a                	je     f0104060 <readline+0x82>
f0104046:	85 f6                	test   %esi,%esi
f0104048:	7e 16                	jle    f0104060 <readline+0x82>
			if (echoing)
f010404a:	85 ff                	test   %edi,%edi
f010404c:	74 0d                	je     f010405b <readline+0x7d>
				cputchar('\b');
f010404e:	83 ec 0c             	sub    $0xc,%esp
f0104051:	6a 08                	push   $0x8
f0104053:	e8 af c5 ff ff       	call   f0100607 <cputchar>
f0104058:	83 c4 10             	add    $0x10,%esp
			i--;
f010405b:	83 ee 01             	sub    $0x1,%esi
f010405e:	eb b3                	jmp    f0104013 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104060:	83 fb 1f             	cmp    $0x1f,%ebx
f0104063:	7e 23                	jle    f0104088 <readline+0xaa>
f0104065:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010406b:	7f 1b                	jg     f0104088 <readline+0xaa>
			if (echoing)
f010406d:	85 ff                	test   %edi,%edi
f010406f:	74 0c                	je     f010407d <readline+0x9f>
				cputchar(c);
f0104071:	83 ec 0c             	sub    $0xc,%esp
f0104074:	53                   	push   %ebx
f0104075:	e8 8d c5 ff ff       	call   f0100607 <cputchar>
f010407a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010407d:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f0104083:	8d 76 01             	lea    0x1(%esi),%esi
f0104086:	eb 8b                	jmp    f0104013 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104088:	83 fb 0a             	cmp    $0xa,%ebx
f010408b:	74 05                	je     f0104092 <readline+0xb4>
f010408d:	83 fb 0d             	cmp    $0xd,%ebx
f0104090:	75 81                	jne    f0104013 <readline+0x35>
			if (echoing)
f0104092:	85 ff                	test   %edi,%edi
f0104094:	74 0d                	je     f01040a3 <readline+0xc5>
				cputchar('\n');
f0104096:	83 ec 0c             	sub    $0xc,%esp
f0104099:	6a 0a                	push   $0xa
f010409b:	e8 67 c5 ff ff       	call   f0100607 <cputchar>
f01040a0:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01040a3:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f01040aa:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f01040af:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040b2:	5b                   	pop    %ebx
f01040b3:	5e                   	pop    %esi
f01040b4:	5f                   	pop    %edi
f01040b5:	5d                   	pop    %ebp
f01040b6:	c3                   	ret    

f01040b7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01040b7:	55                   	push   %ebp
f01040b8:	89 e5                	mov    %esp,%ebp
f01040ba:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01040bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01040c2:	eb 03                	jmp    f01040c7 <strlen+0x10>
		n++;
f01040c4:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01040c7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01040cb:	75 f7                	jne    f01040c4 <strlen+0xd>
		n++;
	return n;
}
f01040cd:	5d                   	pop    %ebp
f01040ce:	c3                   	ret    

f01040cf <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01040cf:	55                   	push   %ebp
f01040d0:	89 e5                	mov    %esp,%ebp
f01040d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040d5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040d8:	ba 00 00 00 00       	mov    $0x0,%edx
f01040dd:	eb 03                	jmp    f01040e2 <strnlen+0x13>
		n++;
f01040df:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040e2:	39 c2                	cmp    %eax,%edx
f01040e4:	74 08                	je     f01040ee <strnlen+0x1f>
f01040e6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01040ea:	75 f3                	jne    f01040df <strnlen+0x10>
f01040ec:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01040ee:	5d                   	pop    %ebp
f01040ef:	c3                   	ret    

f01040f0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01040f0:	55                   	push   %ebp
f01040f1:	89 e5                	mov    %esp,%ebp
f01040f3:	53                   	push   %ebx
f01040f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01040f7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01040fa:	89 c2                	mov    %eax,%edx
f01040fc:	83 c2 01             	add    $0x1,%edx
f01040ff:	83 c1 01             	add    $0x1,%ecx
f0104102:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104106:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104109:	84 db                	test   %bl,%bl
f010410b:	75 ef                	jne    f01040fc <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010410d:	5b                   	pop    %ebx
f010410e:	5d                   	pop    %ebp
f010410f:	c3                   	ret    

f0104110 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104110:	55                   	push   %ebp
f0104111:	89 e5                	mov    %esp,%ebp
f0104113:	53                   	push   %ebx
f0104114:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104117:	53                   	push   %ebx
f0104118:	e8 9a ff ff ff       	call   f01040b7 <strlen>
f010411d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104120:	ff 75 0c             	pushl  0xc(%ebp)
f0104123:	01 d8                	add    %ebx,%eax
f0104125:	50                   	push   %eax
f0104126:	e8 c5 ff ff ff       	call   f01040f0 <strcpy>
	return dst;
}
f010412b:	89 d8                	mov    %ebx,%eax
f010412d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104130:	c9                   	leave  
f0104131:	c3                   	ret    

f0104132 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104132:	55                   	push   %ebp
f0104133:	89 e5                	mov    %esp,%ebp
f0104135:	56                   	push   %esi
f0104136:	53                   	push   %ebx
f0104137:	8b 75 08             	mov    0x8(%ebp),%esi
f010413a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010413d:	89 f3                	mov    %esi,%ebx
f010413f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104142:	89 f2                	mov    %esi,%edx
f0104144:	eb 0f                	jmp    f0104155 <strncpy+0x23>
		*dst++ = *src;
f0104146:	83 c2 01             	add    $0x1,%edx
f0104149:	0f b6 01             	movzbl (%ecx),%eax
f010414c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010414f:	80 39 01             	cmpb   $0x1,(%ecx)
f0104152:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104155:	39 da                	cmp    %ebx,%edx
f0104157:	75 ed                	jne    f0104146 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104159:	89 f0                	mov    %esi,%eax
f010415b:	5b                   	pop    %ebx
f010415c:	5e                   	pop    %esi
f010415d:	5d                   	pop    %ebp
f010415e:	c3                   	ret    

f010415f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010415f:	55                   	push   %ebp
f0104160:	89 e5                	mov    %esp,%ebp
f0104162:	56                   	push   %esi
f0104163:	53                   	push   %ebx
f0104164:	8b 75 08             	mov    0x8(%ebp),%esi
f0104167:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010416a:	8b 55 10             	mov    0x10(%ebp),%edx
f010416d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010416f:	85 d2                	test   %edx,%edx
f0104171:	74 21                	je     f0104194 <strlcpy+0x35>
f0104173:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104177:	89 f2                	mov    %esi,%edx
f0104179:	eb 09                	jmp    f0104184 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010417b:	83 c2 01             	add    $0x1,%edx
f010417e:	83 c1 01             	add    $0x1,%ecx
f0104181:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104184:	39 c2                	cmp    %eax,%edx
f0104186:	74 09                	je     f0104191 <strlcpy+0x32>
f0104188:	0f b6 19             	movzbl (%ecx),%ebx
f010418b:	84 db                	test   %bl,%bl
f010418d:	75 ec                	jne    f010417b <strlcpy+0x1c>
f010418f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104191:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104194:	29 f0                	sub    %esi,%eax
}
f0104196:	5b                   	pop    %ebx
f0104197:	5e                   	pop    %esi
f0104198:	5d                   	pop    %ebp
f0104199:	c3                   	ret    

f010419a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010419a:	55                   	push   %ebp
f010419b:	89 e5                	mov    %esp,%ebp
f010419d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041a0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01041a3:	eb 06                	jmp    f01041ab <strcmp+0x11>
		p++, q++;
f01041a5:	83 c1 01             	add    $0x1,%ecx
f01041a8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01041ab:	0f b6 01             	movzbl (%ecx),%eax
f01041ae:	84 c0                	test   %al,%al
f01041b0:	74 04                	je     f01041b6 <strcmp+0x1c>
f01041b2:	3a 02                	cmp    (%edx),%al
f01041b4:	74 ef                	je     f01041a5 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01041b6:	0f b6 c0             	movzbl %al,%eax
f01041b9:	0f b6 12             	movzbl (%edx),%edx
f01041bc:	29 d0                	sub    %edx,%eax
}
f01041be:	5d                   	pop    %ebp
f01041bf:	c3                   	ret    

f01041c0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01041c0:	55                   	push   %ebp
f01041c1:	89 e5                	mov    %esp,%ebp
f01041c3:	53                   	push   %ebx
f01041c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01041c7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041ca:	89 c3                	mov    %eax,%ebx
f01041cc:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01041cf:	eb 06                	jmp    f01041d7 <strncmp+0x17>
		n--, p++, q++;
f01041d1:	83 c0 01             	add    $0x1,%eax
f01041d4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01041d7:	39 d8                	cmp    %ebx,%eax
f01041d9:	74 15                	je     f01041f0 <strncmp+0x30>
f01041db:	0f b6 08             	movzbl (%eax),%ecx
f01041de:	84 c9                	test   %cl,%cl
f01041e0:	74 04                	je     f01041e6 <strncmp+0x26>
f01041e2:	3a 0a                	cmp    (%edx),%cl
f01041e4:	74 eb                	je     f01041d1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01041e6:	0f b6 00             	movzbl (%eax),%eax
f01041e9:	0f b6 12             	movzbl (%edx),%edx
f01041ec:	29 d0                	sub    %edx,%eax
f01041ee:	eb 05                	jmp    f01041f5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01041f0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01041f5:	5b                   	pop    %ebx
f01041f6:	5d                   	pop    %ebp
f01041f7:	c3                   	ret    

f01041f8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01041f8:	55                   	push   %ebp
f01041f9:	89 e5                	mov    %esp,%ebp
f01041fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01041fe:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104202:	eb 07                	jmp    f010420b <strchr+0x13>
		if (*s == c)
f0104204:	38 ca                	cmp    %cl,%dl
f0104206:	74 0f                	je     f0104217 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104208:	83 c0 01             	add    $0x1,%eax
f010420b:	0f b6 10             	movzbl (%eax),%edx
f010420e:	84 d2                	test   %dl,%dl
f0104210:	75 f2                	jne    f0104204 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104212:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104217:	5d                   	pop    %ebp
f0104218:	c3                   	ret    

f0104219 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104219:	55                   	push   %ebp
f010421a:	89 e5                	mov    %esp,%ebp
f010421c:	8b 45 08             	mov    0x8(%ebp),%eax
f010421f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104223:	eb 03                	jmp    f0104228 <strfind+0xf>
f0104225:	83 c0 01             	add    $0x1,%eax
f0104228:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010422b:	38 ca                	cmp    %cl,%dl
f010422d:	74 04                	je     f0104233 <strfind+0x1a>
f010422f:	84 d2                	test   %dl,%dl
f0104231:	75 f2                	jne    f0104225 <strfind+0xc>
			break;
	return (char *) s;
}
f0104233:	5d                   	pop    %ebp
f0104234:	c3                   	ret    

f0104235 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104235:	55                   	push   %ebp
f0104236:	89 e5                	mov    %esp,%ebp
f0104238:	57                   	push   %edi
f0104239:	56                   	push   %esi
f010423a:	53                   	push   %ebx
f010423b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010423e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104241:	85 c9                	test   %ecx,%ecx
f0104243:	74 36                	je     f010427b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104245:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010424b:	75 28                	jne    f0104275 <memset+0x40>
f010424d:	f6 c1 03             	test   $0x3,%cl
f0104250:	75 23                	jne    f0104275 <memset+0x40>
		c &= 0xFF;
f0104252:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104256:	89 d3                	mov    %edx,%ebx
f0104258:	c1 e3 08             	shl    $0x8,%ebx
f010425b:	89 d6                	mov    %edx,%esi
f010425d:	c1 e6 18             	shl    $0x18,%esi
f0104260:	89 d0                	mov    %edx,%eax
f0104262:	c1 e0 10             	shl    $0x10,%eax
f0104265:	09 f0                	or     %esi,%eax
f0104267:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104269:	89 d8                	mov    %ebx,%eax
f010426b:	09 d0                	or     %edx,%eax
f010426d:	c1 e9 02             	shr    $0x2,%ecx
f0104270:	fc                   	cld    
f0104271:	f3 ab                	rep stos %eax,%es:(%edi)
f0104273:	eb 06                	jmp    f010427b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104275:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104278:	fc                   	cld    
f0104279:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010427b:	89 f8                	mov    %edi,%eax
f010427d:	5b                   	pop    %ebx
f010427e:	5e                   	pop    %esi
f010427f:	5f                   	pop    %edi
f0104280:	5d                   	pop    %ebp
f0104281:	c3                   	ret    

f0104282 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104282:	55                   	push   %ebp
f0104283:	89 e5                	mov    %esp,%ebp
f0104285:	57                   	push   %edi
f0104286:	56                   	push   %esi
f0104287:	8b 45 08             	mov    0x8(%ebp),%eax
f010428a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010428d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104290:	39 c6                	cmp    %eax,%esi
f0104292:	73 35                	jae    f01042c9 <memmove+0x47>
f0104294:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104297:	39 d0                	cmp    %edx,%eax
f0104299:	73 2e                	jae    f01042c9 <memmove+0x47>
		s += n;
		d += n;
f010429b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010429e:	89 d6                	mov    %edx,%esi
f01042a0:	09 fe                	or     %edi,%esi
f01042a2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01042a8:	75 13                	jne    f01042bd <memmove+0x3b>
f01042aa:	f6 c1 03             	test   $0x3,%cl
f01042ad:	75 0e                	jne    f01042bd <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01042af:	83 ef 04             	sub    $0x4,%edi
f01042b2:	8d 72 fc             	lea    -0x4(%edx),%esi
f01042b5:	c1 e9 02             	shr    $0x2,%ecx
f01042b8:	fd                   	std    
f01042b9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01042bb:	eb 09                	jmp    f01042c6 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01042bd:	83 ef 01             	sub    $0x1,%edi
f01042c0:	8d 72 ff             	lea    -0x1(%edx),%esi
f01042c3:	fd                   	std    
f01042c4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01042c6:	fc                   	cld    
f01042c7:	eb 1d                	jmp    f01042e6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01042c9:	89 f2                	mov    %esi,%edx
f01042cb:	09 c2                	or     %eax,%edx
f01042cd:	f6 c2 03             	test   $0x3,%dl
f01042d0:	75 0f                	jne    f01042e1 <memmove+0x5f>
f01042d2:	f6 c1 03             	test   $0x3,%cl
f01042d5:	75 0a                	jne    f01042e1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01042d7:	c1 e9 02             	shr    $0x2,%ecx
f01042da:	89 c7                	mov    %eax,%edi
f01042dc:	fc                   	cld    
f01042dd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01042df:	eb 05                	jmp    f01042e6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01042e1:	89 c7                	mov    %eax,%edi
f01042e3:	fc                   	cld    
f01042e4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01042e6:	5e                   	pop    %esi
f01042e7:	5f                   	pop    %edi
f01042e8:	5d                   	pop    %ebp
f01042e9:	c3                   	ret    

f01042ea <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01042ea:	55                   	push   %ebp
f01042eb:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01042ed:	ff 75 10             	pushl  0x10(%ebp)
f01042f0:	ff 75 0c             	pushl  0xc(%ebp)
f01042f3:	ff 75 08             	pushl  0x8(%ebp)
f01042f6:	e8 87 ff ff ff       	call   f0104282 <memmove>
}
f01042fb:	c9                   	leave  
f01042fc:	c3                   	ret    

f01042fd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01042fd:	55                   	push   %ebp
f01042fe:	89 e5                	mov    %esp,%ebp
f0104300:	56                   	push   %esi
f0104301:	53                   	push   %ebx
f0104302:	8b 45 08             	mov    0x8(%ebp),%eax
f0104305:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104308:	89 c6                	mov    %eax,%esi
f010430a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010430d:	eb 1a                	jmp    f0104329 <memcmp+0x2c>
		if (*s1 != *s2)
f010430f:	0f b6 08             	movzbl (%eax),%ecx
f0104312:	0f b6 1a             	movzbl (%edx),%ebx
f0104315:	38 d9                	cmp    %bl,%cl
f0104317:	74 0a                	je     f0104323 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104319:	0f b6 c1             	movzbl %cl,%eax
f010431c:	0f b6 db             	movzbl %bl,%ebx
f010431f:	29 d8                	sub    %ebx,%eax
f0104321:	eb 0f                	jmp    f0104332 <memcmp+0x35>
		s1++, s2++;
f0104323:	83 c0 01             	add    $0x1,%eax
f0104326:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104329:	39 f0                	cmp    %esi,%eax
f010432b:	75 e2                	jne    f010430f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010432d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104332:	5b                   	pop    %ebx
f0104333:	5e                   	pop    %esi
f0104334:	5d                   	pop    %ebp
f0104335:	c3                   	ret    

f0104336 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104336:	55                   	push   %ebp
f0104337:	89 e5                	mov    %esp,%ebp
f0104339:	53                   	push   %ebx
f010433a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010433d:	89 c1                	mov    %eax,%ecx
f010433f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104342:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104346:	eb 0a                	jmp    f0104352 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104348:	0f b6 10             	movzbl (%eax),%edx
f010434b:	39 da                	cmp    %ebx,%edx
f010434d:	74 07                	je     f0104356 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010434f:	83 c0 01             	add    $0x1,%eax
f0104352:	39 c8                	cmp    %ecx,%eax
f0104354:	72 f2                	jb     f0104348 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104356:	5b                   	pop    %ebx
f0104357:	5d                   	pop    %ebp
f0104358:	c3                   	ret    

f0104359 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104359:	55                   	push   %ebp
f010435a:	89 e5                	mov    %esp,%ebp
f010435c:	57                   	push   %edi
f010435d:	56                   	push   %esi
f010435e:	53                   	push   %ebx
f010435f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104362:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104365:	eb 03                	jmp    f010436a <strtol+0x11>
		s++;
f0104367:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010436a:	0f b6 01             	movzbl (%ecx),%eax
f010436d:	3c 20                	cmp    $0x20,%al
f010436f:	74 f6                	je     f0104367 <strtol+0xe>
f0104371:	3c 09                	cmp    $0x9,%al
f0104373:	74 f2                	je     f0104367 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104375:	3c 2b                	cmp    $0x2b,%al
f0104377:	75 0a                	jne    f0104383 <strtol+0x2a>
		s++;
f0104379:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010437c:	bf 00 00 00 00       	mov    $0x0,%edi
f0104381:	eb 11                	jmp    f0104394 <strtol+0x3b>
f0104383:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104388:	3c 2d                	cmp    $0x2d,%al
f010438a:	75 08                	jne    f0104394 <strtol+0x3b>
		s++, neg = 1;
f010438c:	83 c1 01             	add    $0x1,%ecx
f010438f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104394:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010439a:	75 15                	jne    f01043b1 <strtol+0x58>
f010439c:	80 39 30             	cmpb   $0x30,(%ecx)
f010439f:	75 10                	jne    f01043b1 <strtol+0x58>
f01043a1:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01043a5:	75 7c                	jne    f0104423 <strtol+0xca>
		s += 2, base = 16;
f01043a7:	83 c1 02             	add    $0x2,%ecx
f01043aa:	bb 10 00 00 00       	mov    $0x10,%ebx
f01043af:	eb 16                	jmp    f01043c7 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01043b1:	85 db                	test   %ebx,%ebx
f01043b3:	75 12                	jne    f01043c7 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01043b5:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01043ba:	80 39 30             	cmpb   $0x30,(%ecx)
f01043bd:	75 08                	jne    f01043c7 <strtol+0x6e>
		s++, base = 8;
f01043bf:	83 c1 01             	add    $0x1,%ecx
f01043c2:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01043c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01043cc:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01043cf:	0f b6 11             	movzbl (%ecx),%edx
f01043d2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01043d5:	89 f3                	mov    %esi,%ebx
f01043d7:	80 fb 09             	cmp    $0x9,%bl
f01043da:	77 08                	ja     f01043e4 <strtol+0x8b>
			dig = *s - '0';
f01043dc:	0f be d2             	movsbl %dl,%edx
f01043df:	83 ea 30             	sub    $0x30,%edx
f01043e2:	eb 22                	jmp    f0104406 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01043e4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01043e7:	89 f3                	mov    %esi,%ebx
f01043e9:	80 fb 19             	cmp    $0x19,%bl
f01043ec:	77 08                	ja     f01043f6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01043ee:	0f be d2             	movsbl %dl,%edx
f01043f1:	83 ea 57             	sub    $0x57,%edx
f01043f4:	eb 10                	jmp    f0104406 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01043f6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01043f9:	89 f3                	mov    %esi,%ebx
f01043fb:	80 fb 19             	cmp    $0x19,%bl
f01043fe:	77 16                	ja     f0104416 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104400:	0f be d2             	movsbl %dl,%edx
f0104403:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104406:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104409:	7d 0b                	jge    f0104416 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010440b:	83 c1 01             	add    $0x1,%ecx
f010440e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104412:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104414:	eb b9                	jmp    f01043cf <strtol+0x76>

	if (endptr)
f0104416:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010441a:	74 0d                	je     f0104429 <strtol+0xd0>
		*endptr = (char *) s;
f010441c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010441f:	89 0e                	mov    %ecx,(%esi)
f0104421:	eb 06                	jmp    f0104429 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104423:	85 db                	test   %ebx,%ebx
f0104425:	74 98                	je     f01043bf <strtol+0x66>
f0104427:	eb 9e                	jmp    f01043c7 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104429:	89 c2                	mov    %eax,%edx
f010442b:	f7 da                	neg    %edx
f010442d:	85 ff                	test   %edi,%edi
f010442f:	0f 45 c2             	cmovne %edx,%eax
}
f0104432:	5b                   	pop    %ebx
f0104433:	5e                   	pop    %esi
f0104434:	5f                   	pop    %edi
f0104435:	5d                   	pop    %ebp
f0104436:	c3                   	ret    
f0104437:	66 90                	xchg   %ax,%ax
f0104439:	66 90                	xchg   %ax,%ax
f010443b:	66 90                	xchg   %ax,%ax
f010443d:	66 90                	xchg   %ax,%ax
f010443f:	90                   	nop

f0104440 <__udivdi3>:
f0104440:	55                   	push   %ebp
f0104441:	57                   	push   %edi
f0104442:	56                   	push   %esi
f0104443:	53                   	push   %ebx
f0104444:	83 ec 1c             	sub    $0x1c,%esp
f0104447:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010444b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010444f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104453:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104457:	85 f6                	test   %esi,%esi
f0104459:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010445d:	89 ca                	mov    %ecx,%edx
f010445f:	89 f8                	mov    %edi,%eax
f0104461:	75 3d                	jne    f01044a0 <__udivdi3+0x60>
f0104463:	39 cf                	cmp    %ecx,%edi
f0104465:	0f 87 c5 00 00 00    	ja     f0104530 <__udivdi3+0xf0>
f010446b:	85 ff                	test   %edi,%edi
f010446d:	89 fd                	mov    %edi,%ebp
f010446f:	75 0b                	jne    f010447c <__udivdi3+0x3c>
f0104471:	b8 01 00 00 00       	mov    $0x1,%eax
f0104476:	31 d2                	xor    %edx,%edx
f0104478:	f7 f7                	div    %edi
f010447a:	89 c5                	mov    %eax,%ebp
f010447c:	89 c8                	mov    %ecx,%eax
f010447e:	31 d2                	xor    %edx,%edx
f0104480:	f7 f5                	div    %ebp
f0104482:	89 c1                	mov    %eax,%ecx
f0104484:	89 d8                	mov    %ebx,%eax
f0104486:	89 cf                	mov    %ecx,%edi
f0104488:	f7 f5                	div    %ebp
f010448a:	89 c3                	mov    %eax,%ebx
f010448c:	89 d8                	mov    %ebx,%eax
f010448e:	89 fa                	mov    %edi,%edx
f0104490:	83 c4 1c             	add    $0x1c,%esp
f0104493:	5b                   	pop    %ebx
f0104494:	5e                   	pop    %esi
f0104495:	5f                   	pop    %edi
f0104496:	5d                   	pop    %ebp
f0104497:	c3                   	ret    
f0104498:	90                   	nop
f0104499:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01044a0:	39 ce                	cmp    %ecx,%esi
f01044a2:	77 74                	ja     f0104518 <__udivdi3+0xd8>
f01044a4:	0f bd fe             	bsr    %esi,%edi
f01044a7:	83 f7 1f             	xor    $0x1f,%edi
f01044aa:	0f 84 98 00 00 00    	je     f0104548 <__udivdi3+0x108>
f01044b0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01044b5:	89 f9                	mov    %edi,%ecx
f01044b7:	89 c5                	mov    %eax,%ebp
f01044b9:	29 fb                	sub    %edi,%ebx
f01044bb:	d3 e6                	shl    %cl,%esi
f01044bd:	89 d9                	mov    %ebx,%ecx
f01044bf:	d3 ed                	shr    %cl,%ebp
f01044c1:	89 f9                	mov    %edi,%ecx
f01044c3:	d3 e0                	shl    %cl,%eax
f01044c5:	09 ee                	or     %ebp,%esi
f01044c7:	89 d9                	mov    %ebx,%ecx
f01044c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01044cd:	89 d5                	mov    %edx,%ebp
f01044cf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01044d3:	d3 ed                	shr    %cl,%ebp
f01044d5:	89 f9                	mov    %edi,%ecx
f01044d7:	d3 e2                	shl    %cl,%edx
f01044d9:	89 d9                	mov    %ebx,%ecx
f01044db:	d3 e8                	shr    %cl,%eax
f01044dd:	09 c2                	or     %eax,%edx
f01044df:	89 d0                	mov    %edx,%eax
f01044e1:	89 ea                	mov    %ebp,%edx
f01044e3:	f7 f6                	div    %esi
f01044e5:	89 d5                	mov    %edx,%ebp
f01044e7:	89 c3                	mov    %eax,%ebx
f01044e9:	f7 64 24 0c          	mull   0xc(%esp)
f01044ed:	39 d5                	cmp    %edx,%ebp
f01044ef:	72 10                	jb     f0104501 <__udivdi3+0xc1>
f01044f1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01044f5:	89 f9                	mov    %edi,%ecx
f01044f7:	d3 e6                	shl    %cl,%esi
f01044f9:	39 c6                	cmp    %eax,%esi
f01044fb:	73 07                	jae    f0104504 <__udivdi3+0xc4>
f01044fd:	39 d5                	cmp    %edx,%ebp
f01044ff:	75 03                	jne    f0104504 <__udivdi3+0xc4>
f0104501:	83 eb 01             	sub    $0x1,%ebx
f0104504:	31 ff                	xor    %edi,%edi
f0104506:	89 d8                	mov    %ebx,%eax
f0104508:	89 fa                	mov    %edi,%edx
f010450a:	83 c4 1c             	add    $0x1c,%esp
f010450d:	5b                   	pop    %ebx
f010450e:	5e                   	pop    %esi
f010450f:	5f                   	pop    %edi
f0104510:	5d                   	pop    %ebp
f0104511:	c3                   	ret    
f0104512:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104518:	31 ff                	xor    %edi,%edi
f010451a:	31 db                	xor    %ebx,%ebx
f010451c:	89 d8                	mov    %ebx,%eax
f010451e:	89 fa                	mov    %edi,%edx
f0104520:	83 c4 1c             	add    $0x1c,%esp
f0104523:	5b                   	pop    %ebx
f0104524:	5e                   	pop    %esi
f0104525:	5f                   	pop    %edi
f0104526:	5d                   	pop    %ebp
f0104527:	c3                   	ret    
f0104528:	90                   	nop
f0104529:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104530:	89 d8                	mov    %ebx,%eax
f0104532:	f7 f7                	div    %edi
f0104534:	31 ff                	xor    %edi,%edi
f0104536:	89 c3                	mov    %eax,%ebx
f0104538:	89 d8                	mov    %ebx,%eax
f010453a:	89 fa                	mov    %edi,%edx
f010453c:	83 c4 1c             	add    $0x1c,%esp
f010453f:	5b                   	pop    %ebx
f0104540:	5e                   	pop    %esi
f0104541:	5f                   	pop    %edi
f0104542:	5d                   	pop    %ebp
f0104543:	c3                   	ret    
f0104544:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104548:	39 ce                	cmp    %ecx,%esi
f010454a:	72 0c                	jb     f0104558 <__udivdi3+0x118>
f010454c:	31 db                	xor    %ebx,%ebx
f010454e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104552:	0f 87 34 ff ff ff    	ja     f010448c <__udivdi3+0x4c>
f0104558:	bb 01 00 00 00       	mov    $0x1,%ebx
f010455d:	e9 2a ff ff ff       	jmp    f010448c <__udivdi3+0x4c>
f0104562:	66 90                	xchg   %ax,%ax
f0104564:	66 90                	xchg   %ax,%ax
f0104566:	66 90                	xchg   %ax,%ax
f0104568:	66 90                	xchg   %ax,%ax
f010456a:	66 90                	xchg   %ax,%ax
f010456c:	66 90                	xchg   %ax,%ax
f010456e:	66 90                	xchg   %ax,%ax

f0104570 <__umoddi3>:
f0104570:	55                   	push   %ebp
f0104571:	57                   	push   %edi
f0104572:	56                   	push   %esi
f0104573:	53                   	push   %ebx
f0104574:	83 ec 1c             	sub    $0x1c,%esp
f0104577:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010457b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010457f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104583:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104587:	85 d2                	test   %edx,%edx
f0104589:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010458d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104591:	89 f3                	mov    %esi,%ebx
f0104593:	89 3c 24             	mov    %edi,(%esp)
f0104596:	89 74 24 04          	mov    %esi,0x4(%esp)
f010459a:	75 1c                	jne    f01045b8 <__umoddi3+0x48>
f010459c:	39 f7                	cmp    %esi,%edi
f010459e:	76 50                	jbe    f01045f0 <__umoddi3+0x80>
f01045a0:	89 c8                	mov    %ecx,%eax
f01045a2:	89 f2                	mov    %esi,%edx
f01045a4:	f7 f7                	div    %edi
f01045a6:	89 d0                	mov    %edx,%eax
f01045a8:	31 d2                	xor    %edx,%edx
f01045aa:	83 c4 1c             	add    $0x1c,%esp
f01045ad:	5b                   	pop    %ebx
f01045ae:	5e                   	pop    %esi
f01045af:	5f                   	pop    %edi
f01045b0:	5d                   	pop    %ebp
f01045b1:	c3                   	ret    
f01045b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01045b8:	39 f2                	cmp    %esi,%edx
f01045ba:	89 d0                	mov    %edx,%eax
f01045bc:	77 52                	ja     f0104610 <__umoddi3+0xa0>
f01045be:	0f bd ea             	bsr    %edx,%ebp
f01045c1:	83 f5 1f             	xor    $0x1f,%ebp
f01045c4:	75 5a                	jne    f0104620 <__umoddi3+0xb0>
f01045c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01045ca:	0f 82 e0 00 00 00    	jb     f01046b0 <__umoddi3+0x140>
f01045d0:	39 0c 24             	cmp    %ecx,(%esp)
f01045d3:	0f 86 d7 00 00 00    	jbe    f01046b0 <__umoddi3+0x140>
f01045d9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045dd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01045e1:	83 c4 1c             	add    $0x1c,%esp
f01045e4:	5b                   	pop    %ebx
f01045e5:	5e                   	pop    %esi
f01045e6:	5f                   	pop    %edi
f01045e7:	5d                   	pop    %ebp
f01045e8:	c3                   	ret    
f01045e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045f0:	85 ff                	test   %edi,%edi
f01045f2:	89 fd                	mov    %edi,%ebp
f01045f4:	75 0b                	jne    f0104601 <__umoddi3+0x91>
f01045f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01045fb:	31 d2                	xor    %edx,%edx
f01045fd:	f7 f7                	div    %edi
f01045ff:	89 c5                	mov    %eax,%ebp
f0104601:	89 f0                	mov    %esi,%eax
f0104603:	31 d2                	xor    %edx,%edx
f0104605:	f7 f5                	div    %ebp
f0104607:	89 c8                	mov    %ecx,%eax
f0104609:	f7 f5                	div    %ebp
f010460b:	89 d0                	mov    %edx,%eax
f010460d:	eb 99                	jmp    f01045a8 <__umoddi3+0x38>
f010460f:	90                   	nop
f0104610:	89 c8                	mov    %ecx,%eax
f0104612:	89 f2                	mov    %esi,%edx
f0104614:	83 c4 1c             	add    $0x1c,%esp
f0104617:	5b                   	pop    %ebx
f0104618:	5e                   	pop    %esi
f0104619:	5f                   	pop    %edi
f010461a:	5d                   	pop    %ebp
f010461b:	c3                   	ret    
f010461c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104620:	8b 34 24             	mov    (%esp),%esi
f0104623:	bf 20 00 00 00       	mov    $0x20,%edi
f0104628:	89 e9                	mov    %ebp,%ecx
f010462a:	29 ef                	sub    %ebp,%edi
f010462c:	d3 e0                	shl    %cl,%eax
f010462e:	89 f9                	mov    %edi,%ecx
f0104630:	89 f2                	mov    %esi,%edx
f0104632:	d3 ea                	shr    %cl,%edx
f0104634:	89 e9                	mov    %ebp,%ecx
f0104636:	09 c2                	or     %eax,%edx
f0104638:	89 d8                	mov    %ebx,%eax
f010463a:	89 14 24             	mov    %edx,(%esp)
f010463d:	89 f2                	mov    %esi,%edx
f010463f:	d3 e2                	shl    %cl,%edx
f0104641:	89 f9                	mov    %edi,%ecx
f0104643:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104647:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010464b:	d3 e8                	shr    %cl,%eax
f010464d:	89 e9                	mov    %ebp,%ecx
f010464f:	89 c6                	mov    %eax,%esi
f0104651:	d3 e3                	shl    %cl,%ebx
f0104653:	89 f9                	mov    %edi,%ecx
f0104655:	89 d0                	mov    %edx,%eax
f0104657:	d3 e8                	shr    %cl,%eax
f0104659:	89 e9                	mov    %ebp,%ecx
f010465b:	09 d8                	or     %ebx,%eax
f010465d:	89 d3                	mov    %edx,%ebx
f010465f:	89 f2                	mov    %esi,%edx
f0104661:	f7 34 24             	divl   (%esp)
f0104664:	89 d6                	mov    %edx,%esi
f0104666:	d3 e3                	shl    %cl,%ebx
f0104668:	f7 64 24 04          	mull   0x4(%esp)
f010466c:	39 d6                	cmp    %edx,%esi
f010466e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104672:	89 d1                	mov    %edx,%ecx
f0104674:	89 c3                	mov    %eax,%ebx
f0104676:	72 08                	jb     f0104680 <__umoddi3+0x110>
f0104678:	75 11                	jne    f010468b <__umoddi3+0x11b>
f010467a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010467e:	73 0b                	jae    f010468b <__umoddi3+0x11b>
f0104680:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104684:	1b 14 24             	sbb    (%esp),%edx
f0104687:	89 d1                	mov    %edx,%ecx
f0104689:	89 c3                	mov    %eax,%ebx
f010468b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010468f:	29 da                	sub    %ebx,%edx
f0104691:	19 ce                	sbb    %ecx,%esi
f0104693:	89 f9                	mov    %edi,%ecx
f0104695:	89 f0                	mov    %esi,%eax
f0104697:	d3 e0                	shl    %cl,%eax
f0104699:	89 e9                	mov    %ebp,%ecx
f010469b:	d3 ea                	shr    %cl,%edx
f010469d:	89 e9                	mov    %ebp,%ecx
f010469f:	d3 ee                	shr    %cl,%esi
f01046a1:	09 d0                	or     %edx,%eax
f01046a3:	89 f2                	mov    %esi,%edx
f01046a5:	83 c4 1c             	add    $0x1c,%esp
f01046a8:	5b                   	pop    %ebx
f01046a9:	5e                   	pop    %esi
f01046aa:	5f                   	pop    %edi
f01046ab:	5d                   	pop    %ebp
f01046ac:	c3                   	ret    
f01046ad:	8d 76 00             	lea    0x0(%esi),%esi
f01046b0:	29 f9                	sub    %edi,%ecx
f01046b2:	19 d6                	sbb    %edx,%esi
f01046b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01046b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01046bc:	e9 18 ff ff ff       	jmp    f01045d9 <__umoddi3+0x69>
