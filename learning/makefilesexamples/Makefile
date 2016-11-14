
.PHONY: all gerrit-verify nightly-check release cleanall

# 'all' target is the default one
all:

WORKING_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
LOG_FOLDER ?= ./TAlog
CT_LOG_FOLDER ?= $(LOG_FOLDER)

include $(WORKING_DIR)ptt-api.mk

# Build libs for an application
all: libs sampleapp testapp

# Gerrit verify
gerrit-verify::
	@cd $(WORKING_DIR) && \
	$(MAKE) TARGET_PLATFORM=host-32 debug=1 CLEAN_COVERAGE=1 gerrit-verify-ptt-sdk

ifeq ($(HOST_TYPE),darwin)
gerrit-verify::
	@cd $(WORKING_DIR) && \
	$(MAKE) TARGET_PLATFORM=ios debug=1 gerrit-verify-ptt-sdk
endif

ifeq ($(HOST_TYPE),linux)
gerrit-verify::
	@cd $(WORKING_DIR) && \
	$(MAKE) TARGET_PLATFORM=host-64 debug=1 gerrit-verify-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=android debug=1 gerrit-verify-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=blackberry debug=1 gerrit-verify-ptt-sdk
endif

gerrit-verify::
	@echo "Common Test config verification" && cd $(WORKING_DIR)/common_test && $(MAKE) verify_configs

# Nightly build
nightly-check::
	@cd $(WORKING_DIR) && \
	$(MAKE) TARGET_PLATFORM=host-32 debug=1 CLEAN_COVERAGE=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=host-64 debug=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=android debug=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=android debug=1 HAS_FEATURE_SPGTLS=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=blackberry debug=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=host-32 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=host-64 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=android nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=android HAS_FEATURE_SPGTLS=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=blackberry nightly-check-ptt-sdk

ifeq ($(HOST_TYPE),darwin)
nightly-check::
	@cd $(WORKING_DIR) && \
	$(MAKE) TARGET_PLATFORM=ios debug=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=ios debug=1 TARGET_ARCHITECTURE=armv7  nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=ios debug=1 TARGET_ARCHITECTURE=armv7s nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=ios debug=1 TARGET_ARCHITECTURE=arm64  nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=iphonesimulator debug=1 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=ios nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=ios TARGET_ARCHITECTURE=armv7 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=ios TARGET_ARCHITECTURE=armv7s nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=ios TARGET_ARCHITECTURE=arm64 nightly-check-ptt-sdk && \
	$(MAKE) TARGET_PLATFORM=iphonesimulator nightly-check-ptt-sdk
endif


# Release build
release::
	@cd $(WORKING_DIR) && \
	$(MAKE) TARGET_PLATFORM=host-32 all && \
	$(MAKE) TARGET_PLATFORM=host-64 all && \
	$(MAKE) TARGET_PLATFORM=android all && \
	$(MAKE) TARGET_PLATFORM=blackberry all

ifeq ($(HOST_TYPE),darwin)
release::
	@cd $(WORKING_DIR) && \
	$(MAKE) TARGET_PLATFORM=ios all && \
	$(MAKE) TARGET_PLATFORM=iphonesimulator all
endif


# Clean working directories
cleanall:: clean-gtest
	@echo Removing everything...
	@$(RM) -r $(LIBS_DIR) $(OBJS_DIR)
	@echo "'$@' has been completed"


run_boxtests: $(SAMPLEAPP_TARGET)
	@echo "Executing box tests"
	@python $(WORKING_DIR)boxtest/sdkBtFramework/run.py \
	  --sampleapp=$(SAMPLEAPP_TARGET) \
	  --config=$(PATH_TO_FTCONFIG) \
	  --log_out=$(LOG_FOLDER) \
	  --sipp_path=$(SIPP_PATH) \
	  --sipp_scenarios=$(SIPP_SCENARIOS_PATH)

run_ct_functionaltests: run_functionaltests

run_functionaltests: common_test
	@echo "Executing nightly tests"
	mkdir -p $(CT_LOG_FOLDER)
	@$(WORKING_DIR)/common_test/bin/ct_run_nightly -logdir $(CT_LOG_FOLDER) -label nightly

.PHONY: no_targets__ list
no_targets__:
list:
	sh -c "$(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | sort"
