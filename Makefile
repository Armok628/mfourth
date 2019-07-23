CC=clang
CFLAGS=-ansi -O3 -g -nostartfiles -Wall -Wextra -Wpedantic

ASM=nasm
ASMFLAGS=-felf64

PLATFORM=linux_x64

a.out: base.o 3lib.o
	ld $^

posix: base.c posix.c
	$(CC) $(CFLAGS) $^

base.c: mfourth.m4.c *.m4 fth/*.fth
	m4 -Pd $< > $@

base.o: base.c 3lib.h
	$(CC) -c $(CFLAGS) $< -o $@

3lib.o: $(PLATFORM).asm
	$(ASM) $(ASMFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -f base.c *.o
.PHONY: cleaner
cleaner: clean
	rm -f a.out
.PHONY: cleanest
cleanest: cleaner
	rm -f .*~ *~ */.*~ */*~
