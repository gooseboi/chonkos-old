# CONFIG: Architecture to build for
ARCH ?= amd64

ifeq ($(ARCH),amd64)
    TRIPLE ?= x86_64-elf-
else ifeq ($(ARCH),x86)
    TRIPLE ?= i686-elf-
else
    $(error Unknown architecture $(ARCH))
endif


# Toolchain commands (can be overridden)
CARGO ?= cargo
RUSTC ?= rustc
LD := $(TRIPLE)ld
AS := $(TRIPLE)as
OBJDUMP := $(TRIPLE)objdump
OBJCOPY := $(TRIPLE)objcopy

# Building directories
BUILDDIR := build/
OBJDIR := $(BUILDDIR)obj/$(ARCH)/

LINKSCRIPT := arch/$(ARCH)/link.ld
TARGETSPEC := arch/$(ARCH)/target.json
# Compiler Options
LINKFLAGS := -T $(LINKSCRIPT)
LINKFLAGS += -Map $(OBJDIR)map.txt
LINKFLAGS += -n --gc-sections

# Objects
OBJS := start.o kernel.a
OBJS := $(OBJS:%=$(OBJDIR)%)
BIN := $(BUILDDIR)kernel.$(ARCH).bin

# Final output
GRUB_CFG := arch/$(ARCH)/grub.cfg
ISO := build/os-$(ARCH).iso

.PHONY: all clean PHONY

all: $(BIN)

clean:
	rm -rf $(BUILDDIR) target/

# Final link command
$(BIN): $(OBJS) arch/$(ARCH)/link.ld
	$(LD) -o $@ $(LINKFLAGS) $(OBJS)
ifeq ($(ARCH),amd64)
	@mv $@ $@.elf64
	@$(OBJCOPY) $@.elf64 -F elf32-i386 $@
endif

$(ISO): kernel
	@mkdir -p build/isofiles/boot/grub
	@cp $(BIN) build/isofiles/boot/kernel.bin
	@cp $(GRUB_CFG) build/isofiles/boot/grub
	@grub-mkrescue -o $(ISO) build/isofiles 2> /dev/null
	@rm -r build/isofiles

kernel: $(BIN)

# Compile rust kernel object
$(OBJDIR)kernel.a: PHONY Makefile $(TARGETSPEC)
	@mkdir -p $(dir $@)
	$(CARGO) build --target=$(TARGETSPEC) --release
	@cp --preserve target/target/release/libchonkos.a $@

# Compile architecture's assembly stub
$(OBJDIR)start.o: arch/$(ARCH)/start.S
	@mkdir -p $(dir $@)
	$(AS) -o $@ $<

run: $(ISO)
	qemu-system-x86_64 -cdrom $< -serial stdio

test: kernel
	$(CARGO) test --target=$(TARGETSPEC) --release
