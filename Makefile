CC = clang-20
NASM = nasm
CFLAGS = -m64 -Wall -O2 -g -fPIE
NASMFLAGS = -f elf64
LDFLAGS = -m64 -pie
TARGET = printf

all: $(TARGET)

$(TARGET): build/main.o build/showme.o
	$(CC) $(LDFLAGS) -o $@ $^

build/main.o: src/main.c
	$(CC) $(CFLAGS) -c $< -o $@

build/showme.o: src/showme.s
	$(NASM) $(NASMFLAGS) $< -o $@

clean:
	rm -f build/*.o $(TARGET)

.PHONY: all clean