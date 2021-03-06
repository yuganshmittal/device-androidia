# ----------------- BEGIN MIX-IN DEFINITIONS -----------------
# Mix-In definitions are auto-generated by mixin-update
##############################################################
# Source: device/intel/mixins/groups/project-celadon/default/AndroidBoard.mk
##############################################################
droid: flashfiles
	-$(hide) $(ACP) $(out_flashfiles) $(DIST_DIR)
##############################################################
# Source: device/intel/mixins/groups/slot-ab/true/AndroidBoard.mk
##############################################################

make_dir_slot_ab:
	@mkdir -p $(PRODUCT_OUT)/root/boot
	@mkdir -p $(PRODUCT_OUT)/root/misc
	@mkdir -p $(PRODUCT_OUT)/root/persistent
	@mkdir -p $(PRODUCT_OUT)/root/metadata

$(PRODUCT_OUT)/ramdisk.img: make_dir_slot_ab
##############################################################
# Source: device/intel/mixins/groups/kernel/project-celadon/AndroidBoard.mk
##############################################################
ifneq ($(TARGET_PREBUILT_KERNEL),)
$(error TARGET_PREBUILT_KERNEL defined but AndroidIA kernels build from source)
endif

TARGET_KERNEL_SRC ?= kernel/project-celadon

TARGET_KERNEL_ARCH := x86_64
TARGET_KERNEL_CONFIG ?= kernel_64_defconfig

KERNEL_CONFIG_DIR := device/intel/project-celadon/kernel_config

KERNEL_NAME := bzImage

# Set the output for the kernel build products.
KERNEL_OUT := $(abspath $(TARGET_OUT_INTERMEDIATES)/kernel)
KERNEL_BIN := $(KERNEL_OUT)/arch/$(TARGET_KERNEL_ARCH)/boot/$(KERNEL_NAME)
KERNEL_MODULES_INSTALL := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules

KERNELRELEASE = $(shell cat $(KERNEL_OUT)/include/config/kernel.release)

KMOD_OUT := $(shell readlink -f "$(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)")

build_kernel := $(MAKE) -C $(TARGET_KERNEL_SRC) \
		O=$(KERNEL_OUT) \
		ARCH=$(TARGET_KERNEL_ARCH) \
		CROSS_COMPILE="$(KERNEL_CROSS_COMPILE_WRAPPER)" \
		KCFLAGS="$(KERNEL_CFLAGS)" \
		KAFLAGS="$(KERNEL_AFLAGS)" \
		$(if $(SHOW_COMMANDS),V=1) \
		INSTALL_MOD_PATH=$(KMOD_OUT)

KERNEL_CONFIG_FILE := device/intel/project-celadon/kernel_config/$(TARGET_KERNEL_CONFIG)

KERNEL_CONFIG := $(KERNEL_OUT)/.config
$(KERNEL_CONFIG): $(KERNEL_CONFIG_FILE)
	$(hide) mkdir -p $(@D) && cat $(wildcard $^) > $@
	$(build_kernel) oldnoconfig

# Produces the actual kernel image!
$(PRODUCT_OUT)/kernel: $(KERNEL_CONFIG) | $(ACP)
	$(build_kernel) $(KERNEL_NAME) modules
	$(hide) $(ACP) -fp $(KERNEL_BIN) $@

EXTMOD_SRC := ../../../../../..
TARGET_EXTRA_KERNEL_MODULES :=

ALL_EXTRA_MODULES := $(patsubst %,$(TARGET_OUT_INTERMEDIATES)/kmodule/%,$(TARGET_EXTRA_KERNEL_MODULES))
$(ALL_EXTRA_MODULES): $(TARGET_OUT_INTERMEDIATES)/kmodule/%: $(PRODUCT_OUT)/kernel
	@echo Building additional kernel module $*
	$(build_kernel) M=$(abspath $@) modules

# Copy modules in directory pointed by $(KERNEL_MODULES_ROOT)
# First copy modules keeping directory hierarchy lib/modules/`uname-r`for libkmod
# Second, create flat hierarchy for insmod linking to previous hierarchy
$(KERNEL_MODULES_INSTALL): $(PRODUCT_OUT)/kernel $(ALL_EXTRA_MODULES)
	$(hide) rm -rf $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules
	$(build_kernel) modules_install
	$(hide) for kmod in "$(TARGET_EXTRA_KERNEL_MODULES)" ; do \
		echo Installing additional kernel module $${kmod} ; \
		$(subst +,,$(subst $(hide),,$(build_kernel))) M=$(abspath $(TARGET_OUT_INTERMEDIATES))/kernel/$${kmod} modules_install ; \
	done
	$(hide) rm -f $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules/*/{build,source}
	$(hide) mv $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules/$(KERNELRELEASE)/* $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules
	$(hide) rm -rf $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules/$(KERNELRELEASE)
	$(hide) touch $@

# Makes sure any built modules will be included in the system image build.
ALL_DEFAULT_INSTALLED_MODULES += $(KERNEL_MODULES_INSTALL)

installclean: FILES += $(KERNEL_OUT) $(PRODUCT_OUT)/kernel

.PHONY: kernel
kernel: $(PRODUCT_OUT)/kernel
##############################################################
# Source: device/intel/mixins/groups/factory-partition/true/AndroidBoard.mk
##############################################################
INSTALLED_FACTORYIMAGE_TARGET := $(PRODUCT_OUT)/factory.img
selinux_fc := $(TARGET_ROOT_OUT)/file_contexts.bin

$(INSTALLED_FACTORYIMAGE_TARGET) : PRIVATE_SELINUX_FC := $(selinux_fc)
$(INSTALLED_FACTORYIMAGE_TARGET) : $(MKEXTUSERIMG) $(MAKE_EXT4FS) $(E2FSCK) $(selinux_fc)
	$(call pretty,"Target factory fs image: $(INSTALLED_FACTORYIMAGE_TARGET)")
	@mkdir -p $(PRODUCT_OUT)/factory
	$(hide)	$(MKEXTUSERIMG) -s \
		$(PRODUCT_OUT)/factory \
		$(PRODUCT_OUT)/factory.img \
		ext4 \
		factory \
		$(BOARD_FACTORYIMAGE_PARTITION_SIZE) \
		$(PRIVATE_SELINUX_FC)

INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_FACTORYIMAGE_TARGET)

selinux_fc :=

.PHONY: factoryimage
factoryimage: $(INSTALLED_FACTORYIMAGE_TARGET)

make_dir_ab_factory:
	@mkdir -p $(PRODUCT_OUT)/root/factory

$(PRODUCT_OUT)/ramdisk.img: make_dir_ab_factory
##############################################################
# Source: device/intel/mixins/groups/vendor-partition/true/AndroidBoard.mk
##############################################################

# This is to ensure that kernel modules are installed before
# vendor.img is generated.
$(PRODUCT_OUT)/vendor.img : $(KERNEL_MODULES_INSTALL)

make_dir_ab_vendor:
	@mkdir -p $(PRODUCT_OUT)/root/vendor

$(PRODUCT_OUT)/ramdisk.img: make_dir_ab_vendor
##############################################################
# Source: device/intel/mixins/groups/config-partition/enabled/AndroidBoard.mk
##############################################################
INSTALLED_CONFIGIMAGE_TARGET := $(PRODUCT_OUT)/config.img

selinux_fc := $(TARGET_ROOT_OUT)/file_contexts.bin

$(INSTALLED_CONFIGIMAGE_TARGET) : PRIVATE_SELINUX_FC := $(selinux_fc)
$(INSTALLED_CONFIGIMAGE_TARGET) : $(MKEXTUSERIMG) $(MAKE_EXT4FS) $(E2FSCK) $(selinux_fc)
	$(call pretty,"Target config fs image: $(INSTALLED_CONFIGIMAGE_TARGET)")
	@mkdir -p $(PRODUCT_OUT)/config
	$(hide)	PATH=$(HOST_OUT_EXECUTABLES):$$PATH \
		$(MKEXTUSERIMG) -s \
		$(PRODUCT_OUT)/config \
		$(PRODUCT_OUT)/config.img \
		ext4 \
		oem_config \
		$(BOARD_CONFIGIMAGE_PARTITION_SIZE) \
		$(PRIVATE_SELINUX_FC)

INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_CONFIGIMAGE_TARGET)

selinux_fc :=

selinux_fc :=
.PHONY: configimage
configimage: $(INSTALLED_CONFIGIMAGE_TARGET)

make_dir_ab_config:
	@mkdir -p $(PRODUCT_OUT)/vendor/oem_config

$(PRODUCT_OUT)/ramdisk.img: make_dir_ab_config
##############################################################
# Source: device/intel/mixins/groups/variants/default/AndroidBoard.mk
##############################################################
# flashfile_add_blob <blob_name> <path> <mandatory> <var_name>
# - Delete ::variant:: from <path>
# - If the result does not exists and <mandatory> is set, error
# - If <var_name> is set, put the result in <var_name>
# - Add the pair <result>:<blob_name> in BOARD_FLASHFILES_FIRMWARE
define flashfile_add_blob
$(eval blob := $(subst ::variant::,,$(2))) \
$(if $(wildcard $(blob)), \
    $(if $(4), $(eval $(4) := $(blob))) \
    $(eval BOARD_FLASHFILES_FIRMWARE += $(blob):$(1)) \
    , \
    $(if $(3), $(error $(blob) does not exist)))
endef

##############################################################
# Source: device/intel/mixins/groups/boot-arch/project-celadon/AndroidBoard.mk
##############################################################
src_loader_file := $(PRODUCT_OUT)/efi/kernelflinger.efi
tgt_loader_file := $(PRODUCT_OUT)/loader.efi

define generate_flashfiles
$(shell cp $(src_loader_file) $(tgt_loader_file))
zip -qj $(1) $(2) $(tgt_loader_file)
endef

ifneq ($(BUILD_NUMBER),)
out_flashfiles := $(PRODUCT_OUT)/$(TARGET_PRODUCT)-flashfiles-$(BUILD_NUMBER).zip
else
out_flashfiles := $(PRODUCT_OUT)/$(TARGET_PRODUCT).flashfiles.$(TARGET_BUILD_VARIANT).$(USER).zip
endif


$(PRODUCT_OUT)/efi/startup.nsh: $(TARGET_DEVICE_DIR)/$(@F)
	$(ACP) $(TARGET_DEVICE_DIR)/$(@F) $@
	sed -i '/#/d' $@

$(PRODUCT_OUT)/efi/unlock_device.nsh: $(TARGET_DEVICE_DIR)/$(@F)
	$(ACP) $(TARGET_DEVICE_DIR)/$(@F) $@
	sed -i '/#/d' $@

$(PRODUCT_OUT)/efi/efivar_oemlock: $(TARGET_DEVICE_DIR)/$(@F)
	$(ACP) $(TARGET_DEVICE_DIR)/$(@F) $@

$(out_flashfiles): $(BOARD_FLASHFILES) | $(ACP)
	$(call generate_flashfiles,$@, $^)


.PHONY: flashfiles_simple
flashfiles_simple: $(out_flashfiles)

# Rules to create bootloader zip file, a precursor to the bootloader
# image that is stored in the target-files-package. There's also
# metadata file which indicates how large to make the VFAT filesystem
# image

ifeq ($(TARGET_UEFI_ARCH),i386)
efi_default_name := bootia32.efi
LOADER_TYPE := linux-x86
else
efi_default_name := bootx64.efi
LOADER_TYPE := linux-x86_64
endif

# (pulled from build/core/Makefile as this gets defined much later)
# Pick a reasonable string to use to identify files.
ifneq "" "$(filter eng.%,$(BUILD_NUMBER))"
# BUILD_NUMBER has a timestamp in it, which means that
# it will change every time.  Pick a stable value.
FILE_NAME_TAG := eng.$(USER)
else
FILE_NAME_TAG := $(BUILD_NUMBER)
endif

BOARD_FIRST_STAGE_LOADER := $(PRODUCT_OUT)/efi/kernelflinger.efi
BOARD_EXTRA_EFI_MODULES :=

# We stash a copy of BIOSUPDATE.fv so the FW sees it, applies the
# update, and deletes the file. Follows Google's desire to update all
# bootloader pieces with a single "fastboot flash bootloader" command.
# Since it gets deleted we can't do incremental updates of it, we keep
# a copy as capsules/current.fv for this purpose.
intermediates := $(call intermediates-dir-for,PACKAGING,bootloader_zip)
bootloader_zip := $(intermediates)/bootloader.zip
$(bootloader_zip): intermediates := $(intermediates)
$(bootloader_zip): efi_root := $(intermediates)/root
$(bootloader_zip): \
		$(TARGET_DEVICE_DIR)/AndroidBoard.mk \
		$(BOARD_FIRST_STAGE_LOADER) \
		$(BOARD_EXTRA_EFI_MODULES) \
		$(BOARD_SFU_UPDATE) \
		| $(ACP) \

	$(hide) rm -rf $(efi_root)
	$(hide) rm -f $@
	$(hide) mkdir -p $(efi_root)/capsules
	$(hide) mkdir -p $(efi_root)/EFI/BOOT
	$(foreach EXTRA,$(BOARD_EXTRA_EFI_MODULES), \
		$(hide) $(ACP) $(EXTRA) $(efi_root)/)
ifneq ($(BOARD_SFU_UPDATE),)
        $(hide) $(ACP) $(BOARD_SFU_UPDATE) $(efi_root)/BIOSUPDATE.fv
        $(hide) $(ACP) $(BOARD_SFU_UPDATE) $(efi_root)/capsules/current.fv
endif
	$(hide) $(ACP) $(BOARD_FIRST_STAGE_LOADER) $(efi_root)/loader.efi
	$(hide) $(ACP) $(BOARD_FIRST_STAGE_LOADER) $(efi_root)/EFI/BOOT/$(efi_default_name)
	$(hide) echo "Android-IA=\\EFI\\BOOT\\$(efi_default_name)" > $(efi_root)/manifest.txt
ifeq ($(BOARD_BOOTOPTION_FASTBOOT),true)
	$(hide) echo "Fastboot=\\EFI\\BOOT\\$(efi_default_name);-f">> $(efi_root)/manifest.txt
endif
	$(hide) (cd $(efi_root) && zip -qry ../$(notdir $@) .)

bootloader_info := $(intermediates)/bootloader_image_info.txt
$(bootloader_info):
	$(hide) mkdir -p $(dir $@)
	$(hide) echo "size=$(BOARD_BOOTLOADER_PARTITION_SIZE)" > $@
	$(hide) echo "block_size=$(BOARD_BOOTLOADER_BLOCK_SIZE)" >> $@

INSTALLED_RADIOIMAGE_TARGET += $(bootloader_zip) $(bootloader_info)

# Rule to create $(OUT)/bootloader image, binaries within are signed with
# testing keys

BOOTLOADER_FROM_ZIP = device/intel/build/bootloader_from_zip

bootloader_bin := $(PRODUCT_OUT)/bootloader
$(bootloader_bin): \
		$(bootloader_zip) \
		$(IMG2SIMG) \
		$(BOOTLOADER_ADDITIONAL_DEPS) \
		$(BOOTLOADER_FROM_ZIP) \

	$(hide) $(BOOTLOADER_FROM_ZIP) \
		 --size $(BOARD_BOOTLOADER_PARTITION_SIZE) \
		--block-size $(BOARD_BOOTLOADER_BLOCK_SIZE) \
		$(BOOTLOADER_ADDITIONAL_ARGS) \
		--zipfile $(bootloader_zip) \
		$@

droidcore: $(bootloader_bin)

.PHONY: bootloader
bootloader: $(bootloader_bin)
$(call dist-for-goals,droidcore,$(bootloader_bin):$(TARGET_PRODUCT)-bootloader-$(FILE_NAME_TAG))

fastboot_usb_bin := $(PRODUCT_OUT)/fastboot-usb.img
$(fastboot_usb_bin): \
		$(bootloader_zip) \
		$(BOOTLOADER_ADDITIONAL_DEPS) \
		$(BOOTLOADER_FROM_ZIP) \

	$(hide) $(BOOTLOADER_FROM_ZIP) \
		$(BOOTLOADER_ADDITIONAL_ARGS) \
		--zipfile $(bootloader_zip) \
		--extra-size 10485760 \
		--bootable \
		$@

# Build when 'make' is run with no args
droidcore: $(fastboot_usb_bin)

.PHONY: fastboot-usb
fastboot-usb: $(fastboot_usb_bin)

$(call dist-for-goals,droidcore,$(fastboot_usb_bin):$(TARGET_PRODUCT)-fastboot-usb-$(FILE_NAME_TAG).img)
$(call dist-for-goals,droidcore,device/intel/build/testkeys/testkeys_lockdown.txt:test-keys_efi_lockdown.txt)
$(call dist-for-goals,droidcore,device/intel/build/testkeys/unlock.txt:efi_unlock.txt)

ifeq ($(TARGET_BOOTLOADER_POLICY),$(filter $(TARGET_BOOTLOADER_POLICY),static external))
# The bootloader policy is not built but is provided statically in the
# repository or in $(PRODUCT_OUT)/.
else
# Bootloader policy values are generated based on the
# TARGET_BOOTLOADER_POLICY value and the
# device/intel/build/testkeys/{odm,OAK} keys.  The OEM must provide
# its own keys.
GEN_BLPOLICY_OEMVARS := device/intel/build/generate_blpolicy_oemvars
TARGET_ODM_KEY_PAIR := device/intel/build/testkeys/odm
TARGET_OAK_KEY_PAIR := device/intel/build/testkeys/OAK

$(BOOTLOADER_POLICY_OEMVARS):
	$(GEN_BLPOLICY_OEMVARS) -K $(TARGET_ODM_KEY_PAIR) \
		-O $(TARGET_OAK_KEY_PAIR).x509.pem -B $(TARGET_BOOTLOADER_POLICY) \
		$(BOOTLOADER_POLICY_OEMVARS)
endif


GPT_INI2BIN := ./device/intel/common/gpt_bin/gpt_ini2bin.py

$(BOARD_GPT_BIN): $(TARGET_DEVICE_DIR)/gpt.ini
	$(hide) $(GPT_INI2BIN) $< > $@
	$(hide) echo GEN $(notdir $@)

# Use by updater_ab_esp
$(PRODUCT_OUT)/vendor.img: $(PRODUCT_OUT)/vendor/firmware/kernelflinger.efi
$(PRODUCT_OUT)/vendor/firmware/kernelflinger.efi: $(PRODUCT_OUT)/efi/kernelflinger.efi
	$(ACP) $(PRODUCT_OUT)/efi/kernelflinger.efi $@

##############################################################
# Source: device/intel/mixins/groups/audio/project-celadon/AndroidBoard.mk
##############################################################
pfw_rebuild_settings := true
# Target specific audio configuration files
include device/intel/project-celadon/common/audio/AndroidBoard.mk
##############################################################
# Source: device/intel/mixins/groups/wlan/iwlwifi/AndroidBoard.mk
##############################################################
#LOCAL_KERNEL_PATH := $(abspath $(PRODUCT_OUT)/obj/kernel) is not defined yet
#$(abspath $(PRODUCT_OUT)/obj/kernel)/copy_modules: iwlwifi
##############################################################
# Source: device/intel/mixins/groups/flashfiles/ini/AndroidBoard.mk
##############################################################
ff_intermediates := $(call intermediates-dir-for,PACKAGING,flashfiles)

# We need a copy of the flashfiles configuration ini in the
# TFP RADIO/ directory
ff_config := $(ff_intermediates)/flashfiles.ini
$(ff_config): $(FLASHFILES_CONFIG) | $(ACP)
	$(copy-file-to-target)

$(call add_variant_flashfiles,$(ff_intermediates))

INSTALLED_RADIOIMAGE_TARGET += $(ff_config)


$(call flashfile_add_blob,extra_script.edify,$(TARGET_DEVICE_DIR)/flashfiles/::variant::/extra_script.edify)

# We take any required images that can't be derived elsewhere in
# the TFP and put them in RADIO/provdata.zip.
ff_intermediates := $(call intermediates-dir-for,PACKAGING,flashfiles)
provdata_zip := $(ff_intermediates)/provdata.zip
provdata_zip_deps := $(foreach pair,$(BOARD_FLASHFILES),$(call word-colon,1,$(pair)))
ff_root := $(ff_intermediates)/root

define copy-flashfile
$(hide) $(ACP) -fp $(1) $(2)

endef

define deploy_provdata
$(eval ff_var := $(subst provdata,,$(basename $(notdir $(1)))))
$(hide) rm -f $(1)
$(hide) rm -rf $(ff_intermediates)/root$(ff_var)
$(hide) mkdir -p $(ff_intermediates)/root$(ff_var)
$(foreach pair,$(BOARD_FLASHFILES$(ff_var)), \
	$(call copy-flashfile,$(call word-colon,1,$(pair)),$(ff_intermediates)/root$(ff_var)/$(call word-colon,2,$(pair))))
$(hide) zip -qj $(1) $(ff_intermediates)/root$(ff_var)/*
endef

ifneq ($(FLASHFILE_VARIANTS),)
provdata_zip :=
$(foreach var,$(FLASHFILE_VARIANTS), \
	$(eval provdata_zip += $(ff_intermediates)/provdata_$(var).zip) \
	$(eval BOARD_FLASHFILES_$(var) := $(BOARD_FLASHFILES)) \
	$(eval BOARD_FLASHFILES_$(var) += $(BOARD_FLASHFILES_FIRMWARE_$(var))) \
	$(eval provdata_zip_deps += $(foreach pair,$(BOARD_FLASHFILES_FIRMWARE_$(var)),$(call word-colon,1,$(pair)))))
else
$(eval BOARD_FLASHFILES += $(BOARD_FLASHFILES_FIRMWARE))
$(eval provdata_zip_deps += $(foreach pair,$(BOARD_FLASHFILES_FIRMWARE),$(call word-colon,1,$(pair))))
endif

$(provdata_zip): $(provdata_zip_deps) | $(ACP)
	$(call deploy_provdata,$@)


INSTALLED_RADIOIMAGE_TARGET += $(provdata_zip)

##############################################################
# Source: device/intel/mixins/groups/trusty/true/AndroidBoard.mk
##############################################################
TOS_IMAGE_TARGET := $(TRUSTY_BUILDROOT)/evmm_lk_pkg.bin

INTERNAL_PLATFORM := ikgt
LOCAL_MAKE := make

# Build the evmm_pkg.bin and lk.bin
.PHONY: $(TOS_IMAGE_TARGET)
$(TOS_IMAGE_TARGET):
	@echo "making lk.bin.."
	$(hide) (cd $(TOPDIR)trusty && $(TRUSTY_ENV_VAR) $(LOCAL_MAKE) sand-x86-64)
	@echo "making tos image.."
	$(hide) (cd $(TOPDIR)vendor/intel/fw/evmm/$(INTERNAL_PLATFORM) && $(TRUSTY_ENV_VAR) $(LOCAL_MAKE))

#tos partition is assigned for trusty
INSTALLED_TOS_IMAGE_TARGET := $(PRODUCT_OUT)/tos.img
TOS_SIGNING_KEY := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_VERITY_SIGNING_KEY).pk8
TOS_SIGNING_CERT := $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_VERITY_SIGNING_KEY).x509.pem

.PHONY: tosimage
tosimage: $(INSTALLED_TOS_IMAGE_TARGET)

ifeq (true,$(BOARD_AVB_ENABLE)) # BOARD_AVB_ENABLE == true
$(INSTALLED_TOS_IMAGE_TARGET): $(TOS_IMAGE_TARGET) $(MKBOOTIMG) $(AVBTOOL)
	@echo "mkbootimg to create boot image for TOS file: $@"
	$(hide) $(MKBOOTIMG) --kernel $(TOS_IMAGE_TARGET) --output $@
	$(hide) $(AVBTOOL) add_hash_footer \
		--image $@ \
		--partition_size $(BOARD_TOSIMAGE_PARTITION_SIZE) \
		--partition_name tos $(INTERNAL_AVB_SIGNING_ARGS)
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --include_descriptors_from_image $(INSTALLED_TOS_IMAGE_TARGET)
$(PRODUCT_OUT)/vbmeta.img: $(INSTALLED_TOS_IMAGE_TARGET)
else
$(INSTALLED_TOS_IMAGE_TARGET): $(TOS_IMAGE_TARGET) $(MKBOOTIMG) $(BOOT_SIGNER)
	@echo "mkbootimg to create boot image for TOS file: $@"
	$(hide) $(MKBOOTIMG) --kernel $(TOS_IMAGE_TARGET) --output $@
	$(if $(filter true,$(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_SUPPORTS_BOOT_SIGNER)),\
		@echo "sign prebuilt TOS file: $@" &&\
		$(BOOT_SIGNER) /tos $@ $(TOS_SIGNING_KEY) $(TOS_SIGNING_CERT) $@)
endif

INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_TOS_IMAGE_TARGET)

make_dir_ab_tos:
	@mkdir -p $(PRODUCT_OUT)/root/tos

$(PRODUCT_OUT)/ramdisk.img: make_dir_ab_tos
##############################################################
# Source: device/intel/mixins/groups/gptbuild/true/AndroidBoard.mk
##############################################################
gptimage_size ?= 14G

raw_config := none
raw_factory := none
tos_bin := none
multiboot_bin := none

.PHONY: none
none: ;

.PHONY: $(INSTALLED_CONFIGIMAGE_TARGET).raw
$(INSTALLED_CONFIGIMAGE_TARGET).raw: $(INSTALLED_CONFIGIMAGE_TARGET) $(SIMG2IMG)
	$(SIMG2IMG) $< $@

.PHONY: $(INSTALLED_FACTORYIMAGE_TARGET).raw
$(INSTALLED_FACTORYIMAGE_TARGET).raw: $(INSTALLED_FACTORYIMAGE_TARGET) $(SIMG2IMG)
	$(SIMG2IMG) $< $@

ifdef INSTALLED_CONFIGIMAGE_TARGET
raw_config := $(INSTALLED_CONFIGIMAGE_TARGET).raw
endif

ifdef INSTALLED_FACTORYIMAGE_TARGET
raw_factory := $(INSTALLED_FACTORYIMAGE_TARGET).raw
endif

.PHONY: $(GPTIMAGE_BIN)
ifeq ($(strip $(TARGET_USE_TRUSTY)),true)
ifeq ($(strip $(TARGET_USE_MULTIBOOT)),true)
$(GPTIMAGE_BIN): tosimage multiboot
multiboot_bin = $(INSTALLED_MULTIBOOT_IMAGE_TARGET)
else
$(GPTIMAGE_BIN): tosimage
endif
tos_bin = $(INSTALLED_TOS_IMAGE_TARGET)
endif

$(GPTIMAGE_BIN): \
	bootloader \
	bootimage \
	systemimage \
	vbmetaimage \
	vendorimage \
	$(SIMG2IMG) \
	$(raw_config) \
	$(raw_factory)

	$(hide) rm -f $(INSTALLED_SYSTEMIMAGE).raw
	$(hide) rm -f $(INSTALLED_USERDATAIMAGE_TARGET).raw

	$(SIMG2IMG) $(INSTALLED_SYSTEMIMAGE) $(INSTALLED_SYSTEMIMAGE).raw
	$(SIMG2IMG) $(INSTALLED_VENDORIMAGE_TARGET) $(INSTALLED_VENDORIMAGE_TARGET).raw

	$(INTEL_PATH_BUILD)/create_gpt_image.py \
		--create $@ \
		--block $(BOARD_FLASH_BLOCK_SIZE) \
		--table $(TARGET_DEVICE_DIR)/gpt.ini \
		--size $(gptimage_size) \
		--bootloader $(bootloader_bin) \
		--bootloader2 $(bootloader_bin) \
		--tos $(tos_bin) \
		--multiboot $(multiboot_bin) \
		--boot $(INSTALLED_BOOTIMAGE_TARGET) \
		--vbmeta $(INSTALLED_VBMETAIMAGE_TARGET) \
		--system $(INSTALLED_SYSTEMIMAGE).raw \
		--vendor $(INSTALLED_VENDORIMAGE_TARGET).raw \
		--config $(raw_config) \
		--factory $(raw_factory)


.PHONY: gptimage
gptimage: $(GPTIMAGE_BIN)
# ------------------ END MIX-IN DEFINITIONS ------------------
