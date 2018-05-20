arch	?=	x86_64
kernel	:=	build/kernel-$(arch).bin
iso	:=	build/os-$(arch).iso
target	?=	$(arch)-WOSR
rust_os := target/$(target)/debug/libwosr.a

linker_script	:=	src/arch/$(arch)/linker.ld
grub_cfg	:=	src/arch/$(arch)/grub.cfg
assembly_source_files	:=	$(wildcard	src/arch/$(arch)/*.asm)
assembly_object_files	:=	$(patsubst	src/arch/$(arch)/%.asm,	\
	build/arch/$(arch)/%.o,	$(assembly_source_files))

.PHONY:	all	clean	run	iso	kernel

all:	$(kernel)

clean:
	@rm	-r	build

#using	xiwi	because	chromebook	(in	99%	of	cases	remove	"xiwi -T")
#if	you	are	not	using	a	chromebook	with	crouton	the	line	should	be	:
#"	@qemu-system-x86_64	-cdrom	$(iso)"
run:	$(iso)
	@xiwi	-T	qemu-system-x86_64	-cdrom	$(iso)

iso:	$(iso)

#non	EFI system	check	tutorial	post1
$(iso):	$(kernel)	$(grub_cfg)
	@mkdir	-p	build/isofiles/boot/grub
	@cp	$(kernel)	build/isofiles/boot/kernel.bin
	@cp	$(grub_cfg)	build/isofiles/boot/grub
	@grub-mkrescue	/usr/lib/grub/i386-pc	-o	$(iso)	build/isofiles	2>	/dev/null
	@rm	-r	build/isofiles

$(kernel):	kernel	$(rust_os)	$(assembly_object_files)	$(linker_script)
	@ld	-n	-T	$(linker_script)	-o	$(kernel)	$(assembly_object_files)	$(rust_os)

kernel :
	@RUST_TARGET_PATH=$(shell	pwd)	xargo	build	--target	$(target)
#	compile	assembly	files
build/arch/$(arch)/%.o:	src/arch/$(arch)/%.asm
	@mkdir	-p	$(shell	dirname	$@)
	@nasm	-felf64	$<	-o	$@
