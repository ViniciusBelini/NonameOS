all: clean build/noname.img

build/boot.bin: src/boot.asm
	nasm -f bin src/boot.asm -o build/boot.bin
build/stage_two.bin: src/stage_two.asm
	nasm -f bin src/stage_two.asm -o build/stage_two.bin
build/kernel.bin: src/kernel/main.asm
	nasm -f bin src/kernel/main.asm -o build/kernel.bin
build/temp_program.bin: src/temp_program.asm
	nasm -f bin src/temp_program.asm -o build/temp_program.bin

build/noname.img: build/boot.bin build/stage_two.bin build/kernel.bin build/temp_program.bin
	dd if=/dev/zero of=build/noname.img bs=1M count=16

	dd if=build/boot.bin of=build/noname.img conv=notrunc bs=512 seek=0
	dd if=build/stage_two.bin of=build/noname.img conv=notrunc bs=512 seek=1
	dd if=build/kernel.bin of=build/noname.img conv=notrunc bs=512 seek=2
	dd if=build/temp_program.bin of=build/noname.img conv=notrunc bs=512 seek=6

	qemu-system-i386 -hda build/noname.img

clean:
	rm -rf build
	mkdir build
