OUT=$(PWD)/out
MKFS=$(PWD)/tools/jffs2/mkfs.jffs2
FSROOT=$(OUT)/rootfs/fs_1
MKFS_FLAGS=-b -p -n -e 0x20000 -r $(FSROOT) -o $(OUT)/rootfs.jffs2 \
			  -N $(FSROOT)/nocomprlist -U
JEFFERSON=$(HOME)/.local/bin/jefferson -d $(OUT)/rootfs
PYTHON=/usr/bin/python
DECRYPT=$(PWD)/tools/sercomm_fwutils/decrypt_image.py $(STOCK_IMG) \
		  $(OUT)/$(basename $(notdir $(STOCK_IMG))).bin
DECOMPRESS=$(PWD)/tools/sercomm_fwutils/decompress_image.py \
			  $(OUT)/$(basename $(notdir $(STOCK_IMG))).bin \
			  $(OUT)/image_root
CREATE=$(PWD)/tools/sercomm_fwutils/create_image.py $(OUT)/image_root \
		 $(OUT)/patched.img 1
EXTRACT=binwalk -C $(OUT) -D jffs2:jffs2

.NOTPARALLEL : extract
.PHONY : clean extract patch all

all:
	@echo "Usage:"
	@echo "make extract STOCK_IMG=<image of stock firmware>"
	@echo "make patch"
	@echo "make build"
	@echo "make clean"

extract:
	@if test -z "$(STOCK_IMG)"; then \
		echo "Usage: make extract STOCK_IMG=<image of stock firmware>"; false; fi
	@if ! test -r "$(STOCK_IMG)"; then echo "Missing $(STOCK_IMG)"; false; fi
	@echo "Using stock firmware image $(STOCK_IMG) as source"
	@if test -f $(OUT)/.extract-stamp; then \
		echo "$(OUT)/.extract-stamp already exists." ; false ; fi
	@mkdir -p $(OUT)
	$(PYTHON) $(DECRYPT)
	$(PYTHON) $(DECOMPRESS)
	$(EXTRACT) $(OUT)/image_root/kernel_rootfs_*.bin
	head -c32 $(OUT)/image_root/kernel_rootfs_*.bin > \
		$(OUT)/rootfs.hdr
	sudo -n $(JEFFERSON) $(OUT)/_kernel_rootfs_*/20.jffs2
	touch $(OUT)/.extract-stamp

clean:
	$(MAKE) -C $(PWD)/tools/jffs2 clean
	sudo -n rm -rf $(OUT)

patch: $(OUT)/.extract-stamp
	@if test -f $(OUT)/.patch-stamp; then echo Cyclic patches not supported;\
		echo "Run 'make clean'"; false; fi
	sudo -n rsync -avb --chown=root:root --suffix=.orig $(PWD)/replace/. \
		$(OUT)/rootfs/fs_1
	find $(FSROOT) -type l -name "*.orig" -delete
	touch $(OUT)/.patch-stamp

$(MKFS): $(PWD)/tools/jffs2/mkfs.jffs2.c
	$(MAKE) -C $(PWD)/tools/jffs2 mkfs.jffs2

build: $(MKFS) $(OUT)/.extract-stamp
	sudo -n $(MKFS) $(MKFS_FLAGS)
	cat $(OUT)/rootfs.hdr $(OUT)/rootfs.jffs2 > $(OUT)/rootfs.bin
	cp $(OUT)/rootfs.bin $(OUT)/image_root/kernel_rootfs_*
	$(PYTHON) $(CREATE)
	@ls -l $(OUT)/patched.img

