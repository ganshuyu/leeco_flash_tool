LOCAL_PATH:= $(call my-dir)

LEECO_TOOL_DIR := $(ANDROID_BUILD_TOP)/vendor/letv/proprietary/tools/leeco_flash_tool

.PHONY: leeco_flash_tool

leeco_flash_tool: FORCE
	cp $(LEECO_TOOL_DIR)/leeco_mobile_flash.* $(PRODUCT_OUT) -rf
	cp $(LEECO_TOOL_DIR)/tools $(PRODUCT_OUT) -rf

droidcore: leeco_flash_tool
