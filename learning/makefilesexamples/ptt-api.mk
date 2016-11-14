$(info ================ ptt-api make ================)

WORKING_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

MK_DEPS := $(WORKING_DIR)ptt-api.mk

MIN_IOS_SDK ?= 8.1

#----------------------------------------------------
#TODOs:
# Think about avoiding of merging file pathnames with current directory
#  (in theory, there could be files with FULL pathname)
#
# Maybe specify only subsystem names and filter only susbsystem makefiles
#  that have name presenting in the list?
#----------------------------------------------------


#-------------------------------------------------------------------------------
# Use common style for debug parameter
ifneq ($(filter $(debug),1 true y Y yes Yes YES on On ON),)
  override debug := 1
else
  override debug := 0
endif

#-------------------------------------------------------------------------------
# Use common style for COVERAGE parameter
ifneq ($(filter $(COVERAGE),1 true y Y yes Yes YES on On ON),)
  override COVERAGE := 1
  override debug := 1
else
  override COVERAGE := 0
endif

#-------------------------------------------------------------------------------
# Use common style for CLEAN_COVERAGE parameter
ifneq ($(filter $(CLEAN_COVERAGE),1 true y Y yes Yes YES on On ON),)
  override CLEAN_COVERAGE := 1
  override debug := 1
  override COVERAGE := 1
else
  override CLEAN_COVERAGE := 0
endif

#-------------------------------------------------------------------------------
# Use common style for KPI parameter
ifneq ($(filter $(kpi),1 true y Y yes Yes YES on On ON),)
  override kpi := 1
else
  override kpi := 0
endif

#===============================================================================
include $(WORKING_DIR)ptt-api-definitions.mk
include $(WORKING_DIR)ptt-api-hosts.mk
include $(WORKING_DIR)ptt-audio-config.mk

MK_DEPS += $(WORKING_DIR)ptt-api-hosts.mk

# default stack is Wave7k. Please do not accidentally merge it to upp-master branch
STACK ?= WAVE

ifeq ($(STACK),WAVE)
    BUILDTYPE ?= BLD_AGNOSTIC
else
    $(error The stack '$(STACK)' specified is not supported)
endif
$(info Building $(STACK) stack with BUILDTYPE=$(BUILDTYPE))

# Supported target platforms: android, ios, blackberry, host
# default target platform is 'host-32'
TARGET_PLATFORM ?= host-32

# By default, no target variant specified
TARGET_VARIANT:=

#debug option to optional debug flag
ifeq ($(debug),1)

  DEBUG_OPTION:=-g
  ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
    ifeq ($(HOST_TYPE),darwin)
      DEBUG_OPTION:=-gdwarf-2
    endif
  endif
  DEBUG_MACRO:=DEBUG
  BLDTYPE:=debug
else
  DEBUG_MACRO:=NDEBUG
  BLDTYPE:=release
endif
ifeq ($(COVERAGE),1)
  BLDTYPE:=coverage
endif

# Include target toolchains definition
include $(WORKING_DIR)ptt-api-targets.mk

MK_DEPS += $(WORKING_DIR)ptt-api-targets.mk

# Only allow SPG libs on Android platform for now.
ifeq ($(HAS_FEATURE_SPGTLS),1)
ifneq ($(TARGET_PLATFORM),android)
    $(warning HAS_FEATURE_SPGTLS is ignored for $(TARGET_PLATFORM) target)
    override HAS_FEATURE_SPGTLS := 0
endif
endif

BLDTYPEDIR:=$(BLDTYPE)

# Include SPG libraries when enabled in build
ifeq ($(HAS_FEATURE_SPGTLS),1)
  ifeq ($(TARGET_PLATFORM),android)
    #TODO: generate other BLDTYPE name if adding a '-spgtls' suffix is not appropriate
    BLDTYPEDIR:=$(BLDTYPE)-spgtls
    COMMON_LDFLAGS += -L$(WORKING_DIR)ptt-stack/CryptrInterface/lib -lcryptr_interface -lsrtp -lmatrixtls_384 -lspgpkcs11_384

    ifeq ($(HAS_FEATURE_AUDIO_AMBE),1)
    COMMON_LDFLAGS += -L$(WORKING_DIR)ptt-stack/XIS/lib -lapco_secure_xis
    endif
  endif
endif


# intermediate files and output dirs
OBJS_DIR=$(WORKING_DIR)objs
OBJDIR=$(OBJS_DIR)/$(TARGET_DIR)/$(BLDTYPEDIR)
LIBS_DIR=$(WORKING_DIR)libs
LIBDIR=$(LIBS_DIR)/$(TARGET_DIR)/$(BLDTYPEDIR)

_GTEST_DIR=$(WORKING_DIR)third_party/gtest-1.7.0
_GTEST_INCDIR=$(_GTEST_DIR)/include

ifeq ($(CLEAN_COVERAGE),1)
	GCOVR = $(WORKING_DIR)third_party/gcovr-3.2/scripts/cleanGcovr
else
	GCOVR = $(WORKING_DIR)third_party/gcovr-3.2/scripts/gcovr
endif

GCOVR_REPORT_DIR  = $(LIBDIR)/gcovr-report
GCOVR_XML_REPORT  = $(GCOVR_REPORT_DIR)/report.xml
GCOVR_HTML_REPORT = $(GCOVR_REPORT_DIR)/index.html
# list of directories to exclude from coverage report
#   paths relative to the root of the repository
GCOVR_EXCLUDES    = \
    SampleLoggingApp/                              \
    SampleApp/                                     \
    TestApp/                                       \
    UniversalPTT/                                  \
    third_party/                                   \
    objs/                                          \
    libs/                                          \
    sqlite-amalgamation-3081002/                   \
    ptt-stack/                                     \
    audio_xface/                                   \
    KPI/                                           \
    integration-tests/
# TODO: cqx874: ptt-stack, audio_xface and KPI are not included for now,
#               because they have UTs written for cppunit,
#               which is not included/enabled yet

# Directories for doxygen output
DOXY_HTML_OUT = $(WORKING_DIR)api/include/doxygen/html
DOXY_LATEX_OUT = $(WORKING_DIR)api/include/doxygen/latex

# list of files to exclude from coverage report
#   paths relative to the root of the repository
GCOVR_EXCLUDES += \
    api-impl/source/AgentTestTools.h

# list of regexps to exclude from coverage report
GCOVR_EXCLUDES_REGEXP = \
    .*Stub.*            \
    .*[tT]estHelper.*   \
    .*[sS]py.*          \
    .*_test.cpp

# Common configuration options
#TODO: Review feature flags
_COMMON_FEATURES = UNICODE _UNICODE POSIX_TIMER \
                   $(BUILDTYPE) $(DEBUG_MACRO) $(STACK) \
                   $(USE_VOCODER_MACROS) $(USE_EXT_VOCODER_MACROS)

ifeq ($(kpi),1)
    _COMMON_FEATURES += ENABLE_KPI_MARKERS
endif

ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
    _COMMON_FEATURES += OPENSSL_NO_ASM
endif

# Common compilation options - platform defines, features, toolchain includes
COMMON_CPPFLAGS += $(addprefix -D, $(_COMMON_FEATURES) $(_PLATFORM_DEFINES))
COMMON_CPPFLAGS += $(addprefix -I,$(_TOOLCHAIN_INCDIRS) $(_GTEST_INCDIR))

#TODO: review flags. Some flags might be moved to toolchain specifics
#TODO: shall we use -pthread for compilation (not for linking)?
#TODO: remove Wno-error=format-security ?
_COMMON_COMPILER_FLAGS += \
  -MMD -MP \
  -fpic -ffunction-sections -funwind-tables -fstack-protector \
  -fPIE -fPIC\
  -fno-strict-aliasing \
  -fno-omit-frame-pointer -Wa,--noexecstack \
  -Wall -Wformat -Wno-error=format-security \
  $(DEBUG_OPTION) \
  $(_TOOLCHAIN_COMPILER_FLAGS)

# TODO: add dependency generation by specifying  -MF option

COMMON_CFLAGS   += $(_COMMON_COMPILER_FLAGS)
# RTTI/exceptions support in addition to common
COMMON_CXXFLAGS += $(_COMMON_COMPILER_FLAGS) $(_TOOLCHAIN_CXX_FLAGS) -frtti -fexceptions -fpermissive
COMMON_LDFLAGS  += $(_TOOLCHAIN_LDFLAGS) $(DEBUG_OPTION)

ifeq ($(COVERAGE),1)
ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
    OPT_COVERAGE_COMPILE_FLAGS   += --coverage -O0 -g
    OPT_COVERAGE_LDFLAGS         += --coverage
endif
endif

ifeq ($(HOST_TYPE),linux)
  COMMON_LDFLAGS += -Wl,--no-as-needed
endif

# extensions
LIBEXT=a
SHLIBEXT=so
OBJEXT=o

LIBEXT_SUFFIX=$(addprefix .,$(LIBEXT))
SHLIBEXT_SUFFIX=$(addprefix .,$(SHLIBEXT))
OBJEXT_SUFFIX=$(addprefix .,$(OBJEXT))
LIB_PREFIX=lib

# Target library names
_LIBNAME=PttApi
_LOGGING_LIBNAME=LoggingApi

# Prefixes for intermediate files and UTs 
LOGGING_PREFIX=logging-
PTT_PREFIX=

# Target libraries
LIBTARGET=$(addsuffix /,$(LIBDIR))$(LIB_PREFIX)$(_LIBNAME)$(LIBEXT_SUFFIX)
LOGGING_LIBTARGET=$(addsuffix /,$(LIBDIR))$(LIB_PREFIX)$(_LOGGING_LIBNAME)$(LIBEXT_SUFFIX)
LOGGING_SHLIBTARGET=$(addsuffix /,$(LIBDIR))$(LIB_PREFIX)$(_LOGGING_LIBNAME)$(SHLIBEXT_SUFFIX)

# Sqlite3 library; separate target for DB-manager testing
_SQLITE=sqlite3
LIBSQLITE=$(addsuffix /,$(OBJDIR))$(LIB_PREFIX)$(_SQLITE)$(LIBEXT_SUFFIX)

LINENOISENG=linenoise-ng
LIBLINENOISENG=$(addsuffix /,$(OBJDIR))$(LIB_PREFIX)$(LINENOISENG)$(LIBEXT_SUFFIX)

# OpenSSL library: separate target to build OpenSSL library
OPENSSL_SRCDIR=$(WORKING_DIR)third_party/openssl-1.0.2d
ifeq ($(BLDTYPE),coverage)
  OPENSSL_BLDTYPE=debug
else
  OPENSSL_BLDTYPE=$(BLDTYPE)
endif
OPENSSL_LIBDIR=$(OPENSSL_SRCDIR)/libs/$(HOST_TYPE)_$(TARGET_DIR)_$(OPENSSL_BLDTYPE)
OPENSSL_LIBNAME=openssl
LIBOPENSSL=$(addsuffix /, $(OPENSSL_LIBDIR))$(LIB_PREFIX)$(OPENSSL_LIBNAME)$(LIBEXT_SUFFIX)

ifeq ($(filter $(TARGET_PLATFORM),android blackberry),)
COMMON_LDFLAGS += -ldl -lpthread
endif

ifdef HAS_FEATURE_AUDIO_AMBE
  ifdef HAS_FEATURE_LINKABLE_AUDIO_AMBE
    ifeq ($(TARGET_PLATFORM),android)
      LIBAMBEP2_LIB=$(WORKING_DIR)third_party/ambep2-armv7a/libapcop2.a
    endif
  endif
endif

# Native Audio I/O library
#_AUDIO=PttClientAudio
#LIBAUDIO=$(addsuffix /,$(LIBDIR))$(LIB_PREFIX)$(_AUDIO)$(LIBEXT_SUFFIX)

#Reserved to-be-implemented target names
TESTAPP=

MK_DEPS += $(WORKING_DIR)ptt-api-definitions.mk


#-------------------------------------------------------------------------------
# Use common style for CRYPTR_UP parameter
ifneq ($(filter $(CRYPTR_UP),1 true y Y yes Yes YES on On ON),)
  override COMMON_CXXFLAGS += -DCRYPTR_UP
endif

#===============================================================================

################################################################################
# Google Test framework
#
# Libraries generated by gtest-1.7.0 build system
# gtest library without default main() function
GTEST_LIB=gtest
#gtest library with default main() method
GTESTMAIN_LIB=gtest_main

# Full gtest libraries' pathnames
GTEST_LIB_TARGET=$(addsuffix /,$(OBJDIR))$(LIB_PREFIX)$(GTEST_LIB)$(LIBEXT_SUFFIX)
GTESTMAIN_LIB_TARGET=$(addsuffix /,$(OBJDIR))$(LIB_PREFIX)$(GTESTMAIN_LIB)$(LIBEXT_SUFFIX)

# Marker file indicating that gtest libraries are built
GTEST_LIBMARKER=$(addsuffix /,$(OBJDIR)).have_gtest

ifeq ($(TARGET_PLATFORM),android)
  GTEST_CONF_HOST_OPT=--host=$(_TOOLCHAIN_PREFIX) \
	  CC=$(CC) CFLAGS='$(COMMON_CFLAGS)' \
	  CXX=$(CXX) CXXFLAGS='$(COMMON_CPPFLAGS) $(COMMON_CXXFLAGS)' \
	  CPP='$(CPP)' CXXCPP='$(CXXCPP)' \
	  LDFLAGS='$(COMMON_LDFLAGS)'

else ifeq ($(TARGET_PLATFORM),ios)
  GTEST_CONF_HOST_OPT= \
	  CC=$(CC) CFLAGS='$(COMMON_CFLAGS)' \
	  CXX=$(CXX) CXXFLAGS='$(COMMON_CPPFLAGS) $(COMMON_CXXFLAGS)' \
	  --host=arm-none-none

else ifneq ($(filter $(TARGET_PLATFORM),iphonesimulator iphonesimulator-32 iphonesimulator-64),)
  GTEST_CONF_HOST_OPT= \
	  CC=$(CC) CFLAGS='$(COMMON_CFLAGS)' \
	  CXX=$(CXX) CXXFLAGS='$(COMMON_CPPFLAGS) $(COMMON_CXXFLAGS)' \

else ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
  GTEST_CONF_HOST_OPT= \
	  CXX=$(CXX) CXXFLAGS='$(subst --coverage,,$(COMMON_CPPFLAGS)) $(subst --coverage,,$(COMMON_CXXFLAGS))'
endif

.PHONY : gtest clean-gtest gtest-selftest clean-gtest-selftest

# Builds and installs gtest libraries to target-specific libraries directory
gtest : $(GTEST_LIBMARKER)
ifneq ($(_TOOLCHAIN_BINDIR),)
  EXPORT_PATH=PATH="$(_TOOLCHAIN_BINDIR):$(PATH)"
endif

$(GTEST_LIBMARKER) :
	cd $(_GTEST_DIR) && \
	$(EXPORT_PATH) ./configure --libdir=$(OBJDIR) $(GTEST_CONF_HOST_OPT) --disable-shared && \
	$(EXPORT_PATH) $(MAKE) install-libLTLIBRARIES && \
	touch $@ && \
	$(EXPORT_PATH) $(MAKE) distclean

# Cleans installed target specific gtest libraries
# TODO: optimize cleanup in case of there are no both libraries nor Makefile
clean-gtest : clean-gtest-selftest
	-cd $(_GTEST_DIR) && \
	$(EXPORT_PATH) ./configure --libdir=$(OBJDIR) $(GTEST_CONF_HOST_OPT) --disable-shared && \
	$(EXPORT_PATH) $(MAKE) uninstall-libLTLIBRARIES && \
	$(RM) $(GTEST_LIBMARKER) && \
	$(EXPORT_PATH) $(MAKE) distclean

# makes and executes (for host target only) gtest self-test file
GTEST_SELFTEST_SRC=$(_GTEST_DIR)/test/gtest_all_test.cc
GTEST_SELFTEST=$(addsuffix /,$(OBJDIR))$(notdir $(GTEST_SELFTEST_SRC:.cc=))
gtest-selftest : $(GTEST_SELFTEST)
ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
	@ echo Running gtest selftest executable $(notdir $<)
	@ $<
else
	$(info PASSED: gtest selftest executable $(notdir $@) has been successfully built for $(TARGET_PLATFORM) platform)
	$(warning Will not run gtest selftest executable $(notdir $@) built for $(TARGET_PLATFORM) platform )
endif

clean-gtest-selftest :
	@- $(RM) $(GTEST_SELFTEST)

$(GTEST_SELFTEST) : $(GTEST_LIBMARKER) $(MK_DEPS)
	 $(CXX) -pthread -I$(_GTEST_DIR)/include \
	         -I$(_GTEST_DIR) $(CXXFLAGS) -o $@ \
	         $(_GTEST_DIR)/test/gtest_all_test.cc \
	         $(COMMON_CPPFLAGS) $(COMMON_CXXFLAGS) \
	         $(COMMON_LDFLAGS) $(LOCAL_LDFLAGS) \
	         -L$(OBJDIR) $(addprefix -l,$(GTEST_LIB) $(GTESTMAIN_LIB))

################################################################################
# SWIG tool

SWIG_DIR=$(WORKING_DIR)third_party/swig-3.0.8
SWIG=$(SWIG_DIR)/bin/swig

.PHONY : swig clean-swig

# Build swig tool binary
swig : $(SWIG)

$(SWIG) :
	@echo Making $(notdir $@)
	@-mkdir -p $(dir $@)
	cd $(SWIG_DIR) && \
	$(EXPORT_PATH) ./configure --prefix=`pwd` --disable-ccache && \
	$(EXPORT_PATH) $(MAKE) && \
	$(EXPORT_PATH) $(MAKE) install && \
	$(EXPORT_PATH) $(MAKE) distclean -j1

# Cleans installed target specific gtest libraries
clean-swig :
ifneq ($(wildcard $(SWIG)),)
	-cd $(SWIG_DIR) && \
	$(EXPORT_PATH) ./configure --prefix=`pwd` --disable-ccache && \
	$(EXPORT_PATH) $(MAKE) uninstall && \
	$(EXPORT_PATH) $(MAKE) distclean -j1 && \
	$(RM) $(SWIG)
endif

# High-level target to build libraries
$(call declare-phony-target,libs,"Builds libraries only")

################################################################################

# Will use new list of objects
OBJS :=

$(call def-subsys,SQLITE_LIB,$(WORKING_DIR)third_party/sqlite-amalgamation-3081002)

$(call declare-phony-target,sqlite,"Builds Sqlite library only")
sqlite : $(LIBSQLITE)

$(LIBSQLITE) : $(OBJS)
	@echo Making $@
	@-mkdir -p $(dir $@)
	@$(RM) $(LIBSQLITE)
	@$(call create-static-library,$@,$?)

OBJS_TO_CLEAN += $(OBJS)

################################################################################

# Will use new list of objects
OBJS :=

$(call def-subsys,LINENOISENG_LIB,$(WORKING_DIR)third_party/linenoise-ng)

$(call declare-phony-target,linenoiseng,"Builds linenoise-ng library only")
linenoiseng : $(LIBLINENOISENG)

$(LIBLINENOISENG) : $(OBJS)
	@echo Making $@
	@-mkdir -p $(dir $@)
	@$(RM) $(LIBLINENOISENG)
	@$(call create-static-library,$@,$?)

OBJS_TO_CLEAN += $(OBJS)

################################################################################

# OpenSSL library shall be built only if specified as a goal in command line
ifeq (openssl, $(filter openssl,$(MAKECMDGOALS)))
# Will use new list of objects
OBJS :=

$(call def-subsys,OPENSSL_LIB,$(OPENSSL_SRCDIR))

$(call declare-phony-target,openssl,"Builds OpenSSL library only")
openssl : $(LIBOPENSSL)

$(LIBOPENSSL) : $(OBJS)
	@echo Making $@
	@-mkdir -p $(dir $@)
	@$(RM) $(LIBOPENSSL)
	@$(call create-static-library,$@,$?)

OBJS_TO_CLEAN += $(OBJS)
endif


################################################################################
# Common Test

$(call declare-phony-target,common_test,"Common Test application")
common_test: $(GTEST_LIBMARKER) gtestapp testapp sampleapp
	cd $@ && $(MAKE)
	rm -f $@/setenv.sh
	@echo "make $@/setenv.sh"
	@echo "export GTESTAPP_TARGET=$(GTESTAPP_TARGET)"    > $@/setenv.sh
	@echo "export TESTAPP_TARGET=$(TESTAPP_TARGET)"     >> $@/setenv.sh
	@echo "export SAMPLEAPP_TARGET=$(SAMPLEAPP_TARGET)" >> $@/setenv.sh
	@echo                                               >> $@/setenv.sh
	@cd ..

################################################################################

################################################################################
# SampleApp executable

# Will use new list of objects
OBJS :=

$(call def-subsys,GTESTAPP_APP,$(WORKING_DIR)GTestApp)

GTESTAPP_TARGET=$(LIBDIR)/GTestApp

$(call declare-phony-target,gtestapp,"Builds GTestApp application")
gtestapp: $(GTEST_LIBMARKER) $(GTESTAPP_TARGET)

$(GTESTAPP_TARGET) : $(OBJS) $(LIBTARGET) $(LIBSQLITE)
	@echo Making $(notdir $@) executable
	@-mkdir -p $(dir $@)
	@$(CXX) -o $@ $^ $(COMMON_LDFLAGS) $(LOCAL_LDFLAGS) -L$(OBJDIR) $(addprefix -l,$(GTEST_LIB))

OBJS_TO_CLEAN += $(OBJS)

################################################################################

################################################################################
# Below are targets related to PTT API
################################################################################
# Making libPttApi.a 

# Will use new list of objects
OBJS :=

$(call push,TARGET_VRIANT)
$(call push,VRIANT_PREFIX)
VARIANT_PREFIX:=
TARGET_VARIANT:=ptt

$(call def-subsys,PTTAPIIMPL_LIB,$(WORKING_DIR)api-impl/source)
$(call def-subsys,PAAS_CORE,$(WORKING_DIR)paas-core)
$(call def-subsys,PTT_STACK,$(WORKING_DIR)ptt-stack)
$(call def-subsys,AUDIO_XFACE,$(WORKING_DIR)audio_xface)
$(call def-subsys,KPI,$(WORKING_DIR)KPI)
$(call def-subsys,DB_MANAGER,$(WORKING_DIR)paas-core/DB-manager/source)
$(call def-subsys,INT_UT,$(WORKING_DIR)integration-tests)
libs : $(LIBTARGET)
#ifeq ($(TARGET_PLATFORM),ios)
#libs : $(LIBAUDIO)
#endif

.DELETE_ON_ERROR : $(LIBTARGET)

$(LIBTARGET) : $(OBJS) $(LIBOPENSSL)
	@echo Making $@
	@-mkdir -p $(dir $@)
	@$(RM) $(LIBTARGET)
	@$(call create-static-library,$@,$(filter %.o, $^))
	@echo Merging $@ with $(LIBOPENSSL)
	@$(call merge-static-libraries,$@,$(LIBOPENSSL))
# Only allow AMBE+2 libs on Android platform for now.
ifdef HAS_FEATURE_AUDIO_AMBE
  ifdef HAS_FEATURE_LINKABLE_AUDIO_AMBE
    ifeq ($(TARGET_PLATFORM),android)
	    @echo Merging $@ with $(LIBAMBEP2_LIB)
	    @$(call merge-static-libraries,$@,$(LIBAMBEP2_LIB))
      $(LIBTARGET) : $(LIBAMBEP2_LIB)
    endif
  endif
endif

OBJS_TO_CLEAN := $(OBJS)

################################################################################
# SampleApp executable

# Will use new list of objects
OBJS :=

$(call def-subsys,SAMPLEAPP_APP,$(WORKING_DIR)SampleApp)

SAMPLEAPP_TARGET=$(LIBDIR)/SampleApp

$(call declare-phony-target,sampleapp,"Builds SampleApp application")
sampleapp: $(SAMPLEAPP_TARGET)

$(SAMPLEAPP_TARGET) : | $(LIBTARGET)
$(SAMPLEAPP_TARGET) : $(OBJS) $(LIBTARGET) $(LIBSQLITE)
	@echo Making $(notdir $@) executable
	@-mkdir -p $(dir $@)
	@$(CXX) -o $@ $^ $(COMMON_LDFLAGS) $(LOCAL_LDFLAGS)

OBJS_TO_CLEAN += $(OBJS)

################################################################################
# Now create TestApp executable

# Will use new list of objects
OBJS :=
$(call def-subsys,TESTAPP_APP,$(WORKING_DIR)TestApp)

#----------------------
TESTAPP_TARGET=$(LIBDIR)/TestApp
TEST_RUNNER=$(LIBDIR)/tests_runner.sh
TEST_RUNNER_COMMON_PROFILE=$(LIBDIR)/test_runner_common_profile.sh
TEST_LIST=$(LIBDIR)/test_list.sh

$(call declare-phony-target,testapp,"Builds TestApp application")
testapp: $(TESTAPP_TARGET) $(TEST_RUNNER)

$(TESTAPP_TARGET) : $(OBJS) $(LIBTARGET) $(LIBSQLITE)
	@echo Making $(notdir $@) executable
	@-mkdir -p $(dir $@)
	@$(CXX) -o $@ $^ $(COMMON_LDFLAGS) $(LOCAL_LDFLAGS)

$(TEST_RUNNER) : $(WORKING_DIR)/TestApp/scripts/$(notdir $(TEST_RUNNER))
	@echo Copying $(notdir $@) executable
	@-mkdir -p $(dir $@)
	@cp -f $< $@

$(TEST_RUNNER_COMMON_PROFILE) : $(WORKING_DIR)/TestApp/scripts/$(notdir $(TEST_RUNNER_COMMON_PROFILE))
	@-mkdir -p $(dir $@)
	@cp -f $< $@

$(TEST_LIST) : $(WORKING_DIR)/TestApp/scripts/$(notdir $(TEST_LIST))
	@-mkdir -p $(dir $@)
	@cp -f $< $@

$(TEST_RUNNER) : $(TEST_RUNNER_COMMON_PROFILE) $(TEST_LIST)

OBJS_TO_CLEAN += $(OBJS)

################################################################################
# Universal PTT library

OBJS :=
$(call def-subsys,UPTT_JSON,$(WORKING_DIR)UniversalPTT/json)
$(call def-subsys,UPTT_PTT,$(WORKING_DIR)UniversalPTT/ptt)

#----------------------
UPTT_TARGET=$(LIBDIR)/libUPTT.a

$(call declare-phony-target,upttlib,"Builds Universal PTT library")
upttlib: $(UPTT_TARGET)

$(UPTT_TARGET) : $(LIBTARGET) $(LIBSQLITE) $(OBJS)
	@echo Making $(notdir $@) library
	@-mkdir -p $(dir $@)
	@$(RM) $(UPTT_TARGET)
	@$(call create-static-library,$@,$(filter %.o, $^))
	@$(call merge-static-libraries,$@,$(LIBTARGET))
	@$(call merge-static-libraries,$@,$(LIBSQLITE))
	@echo Successfully built $@

OBJS_TO_CLEAN += $(OBJS) $(UPTT_TARGET)

################################################################################
# Universal PTT Python module

# Will use new list of objects
OBJS :=
$(call def-subsys,UPTT_LISTENER,$(WORKING_DIR)UniversalPTT/python/listener)
$(call def-subsys,UPTT_AUDIO,$(WORKING_DIR)UniversalPTT/python/audio)

#----------------------
UPTT=uptt
UPTT_DIR=$(WORKING_DIR)/UniversalPTT
UPTT_PYTHON_DIR=$(UPTT_DIR)/python
UPTT_PYTHON_PREBUILT_DIR=$(UPTT_PYTHON_DIR)/prebuilt
UPTT_PYTHON_LIB=$(LIBDIR)/_$(UPTT).so
UPTT_PYTHON_MODULE=$(LIBDIR)/$(UPTT).py
UPTT_PYTHON_CLIENT=$(LIBDIR)/client.py
UPTT_PYTHON_OBJ=$(OBJDIR)/UPTT_PYTHON.$(UPTT).o
UPTT_PYTHON_INTERFACE=$(UPTT_PYTHON_DIR)/bridge/$(UPTT).i
UPTT_PYTHON_SRC=$(UPTT_PYTHON_DIR)/bridge/$(UPTT).cpp

#----------------------
UPTT_PYTHON_INCDIRS  = -I$(WORKING_DIR)/api/include
UPTT_PYTHON_INCDIRS += -I$(UPTT_DIR)/ptt/include
UPTT_PYTHON_INCDIRS += -I$(UPTT_PYTHON_DIR)/listener/include
UPTT_PYTHON_INCDIRS += -I$(UPTT_PYTHON_DIR)/audio/include
UPTT_PYTHON_INCDIRS += -I$(UPTT_PYTHON_PREBUILT_DIR)/include

ifeq ($(HOST_TYPE),darwin)
  UPTT_LDFLAGS  = $(UPTT_TARGET) -framework Python
else
  UPTT_LDFLAGS  = -Wl,-whole-archive $(UPTT_TARGET) -Wl,-no-whole-archive
  UPTT_LDFLAGS += -L$(UPTT_PYTHON_PREBUILT_DIR)/libs/$(HOST_TYPE) -lpython2.7
endif

#----------------------
$(call declare-phony-target,$(UPTT),"Builds Universal PTT library")
ifeq ($(TARGET_PLATFORM),host-64)
$(UPTT) : $(UPTT_PYTHON_LIB) $(UPTT_PYTHON_MODULE) $(UPTT_PYTHON_CLIENT)
else
$(UPTT) :
	$(error Universal PTT is supported for host-64 target platform only)
endif

# Build shared library for python module
$(UPTT_PYTHON_LIB) : $(UPTT_TARGET) $(OBJS) $(UPTT_PYTHON_OBJ)
	@echo Making $(notdir $@) library
	@-mkdir -p $(dir $@)
	@$(RM) $(UPTT_PYTHON_LIB)
	$(CXX) -o $@ -shared $(subst $(UPTT_TARGET),$(UPTT_LDFLAGS),$^) $(subst -pie,,$(COMMON_LDFLAGS))
	@echo Successfully built $@

# Build c++ wrapper file
$(UPTT_PYTHON_OBJ) : $(UPTT_PYTHON_SRC)
	@echo Making $(notdir $@)
	@$(RM) $(UPTT_PYTHON_OBJ)
	@$(CXX) -c $(UPTT_PYTHON_SRC) $(COMMON_CXXFLAGS) $(UPTT_PYTHON_INCDIRS) -o $(UPTT_PYTHON_OBJ)

# Generate c++ wrapper file using swig tool
$(UPTT_PYTHON_SRC) : $(UPTT_PYTHON_INTERFACE) $(OBJS) $(SWIG)
	@echo Making $(notdir $@)
	@-mkdir -p $(dir $@)
	@$(RM) $(UPTT_PYTHON_SRC) $(subst $(UPTT).cpp,$(UPTT).h,$(UPTT_PYTHON_SRC))
	@$(SWIG) -c++ -python $(UPTT_PYTHON_INCDIRS) -outdir $(LIBDIR) -o $(UPTT_PYTHON_SRC) $(UPTT_PYTHON_INTERFACE)

# Generate python module file using swig tool
$(UPTT_PYTHON_MODULE) : $(UPTT_PYTHON_INTERFACE) $(OBJS) $(SWIG)
	@echo Making $(notdir $@)
	@-mkdir -p $(dir $@)
	@$(RM) $(UPTT_PYTHON_MODULE)
	@$(SWIG) -c++ -python $(UPTT_PYTHON_INCDIRS) -outdir $(LIBDIR) -o $(UPTT_PYTHON_SRC) $(UPTT_PYTHON_INTERFACE)

# Copy python module wrapper file into lib directory
$(UPTT_PYTHON_CLIENT) : $(UPTT_PYTHON_DIR)/client.py
	@echo Making $(notdir $@) executable
	@-mkdir -p $(dir $@)
	@cp -f $^ $@

OBJS_TO_CLEAN += $(UPTT_PYTHON_LIB) $(UPTT_PYTHON_MODULE) $(UPTT_PYTHON_CLIENT)
OBJS_TO_CLEAN += $(OBJS) $(UPTT_PYTHON_OBJ) $(UPTT_PYTHON_SRC)
OBJS_TO_CLEAN += $(subst $(UPTT).cpp,$(UPTT).h,$(UPTT_PYTHON_SRC))
OBJS_TO_CLEAN += $(wildcard $(LIBDIR)/*.pyc)

$(call pop,VRIANT_PREFIX)
$(call pop,TARGET_VRIANT)

# End of targets related to PTT API
################################################################################

################################################################################
# Below are targets related to logging API
ifeq ($(LOGGING_TARGET_SUPPORTED),1)

  $(call declare-phony-target,logging-libs,"Builds logging API libraries")

  $(call push,TARGET_VRIANT)
  $(call push,VARIANT_CPPFLAGS)
  $(call push,VARIANT_PREFIX)
  VARIANT_PREFIX:=$(LOGGING_PREFIX)
  VARIANT_CPPFLAGS:=-DLOGGING_SDK
  TARGET_VARIANT:=logging
  ##############################################################################
  # Making make static and shared logging API libraries
  # TODO: Extract common part to separate .mk or macro
  #
  # Will use new list of objects
  OBJS :=

  $(call def-subsys,PTTAPIIMPL_LIB,$(WORKING_DIR)api-impl/source)
  $(call def-subsys,PAAS_CORE,$(WORKING_DIR)paas-core)
  $(call def-subsys,PTT_STACK,$(WORKING_DIR)ptt-stack)
  $(call def-subsys,AUDIO_XFACE,$(WORKING_DIR)audio_xface)
  # TODO: do we need to include KPI to this target?
  $(call def-subsys,KPI,$(WORKING_DIR)KPI)
  $(call def-subsys,DB_MANAGER,$(WORKING_DIR)paas-core/DB-manager/source)
  $(call def-subsys,INT_UT,$(WORKING_DIR)integration-tests)

  # static  logging library rule
  .DELETE_ON_ERROR : $(LOGGING_LIBTARGET)
  $(LOGGING_LIBTARGET) : $(OBJS) $(LIBOPENSSL)
	@echo Making $@
	@-mkdir -p $(dir $@)
	@$(RM) $@
	@$(call create-static-library,$@,$(filter %.o, $^))
	@echo Merging $@ with $(LIBOPENSSL)
	@$(call merge-static-libraries,$@,$(LIBOPENSSL))
  logging-libs : $(LOGGING_LIBTARGET)

  # shared logging library rule
  .DELETE_ON_ERROR : $(LOGGING_SHLIBTARGET)
  $(LOGGING_SHLIBTARGET) : $(OBJS) $(LIBOPENSSL) $(LIBSQLITE)
	@echo Making $@
	@-mkdir -p $(dir $@)
	@$(RM) $@
	@$(CXX) -shared -o $@ $^ $(COMMON_LDFLAGS) $(LOCAL_LDFLAGS)
  # TODO: command below may require an argument to make visible only names 
  # that explicitly marked as exportable in code (using W7KSDKAPI macro)
  # Now all the names are exported/visible
  logging-libs : $(LOGGING_SHLIBTARGET)

  OBJS_TO_CLEAN := $(OBJS)

  ##############################################################################
  # SampleLoggingApp executable

  # Will use new list of objects
  OBJS :=

  $(call def-subsys,SAMPLELOGGINGAPP_APP,$(WORKING_DIR)SampleLoggingApp)

  SAMPLELOGGINGAPP_TARGET=$(LIBDIR)/SampleLoggingApp

  $(call declare-phony-target,sampleloggingapp,"Builds SampleLoggingApp application")
  sampleloggingapp: $(SAMPLELOGGINGAPP_TARGET)

  $(SAMPLELOGGINGAPP_TARGET) : | $(LOGGING_LIBTARGET)
  $(SAMPLELOGGINGAPP_TARGET) : $(OBJS) $(LOGGING_LIBTARGET) $(LIBSQLITE) $(LIBLINENOISENG)
	@echo Making $(notdir $@) executable
	@-mkdir -p $(dir $@)
	@$(CXX) -o $@ $^ $(COMMON_LDFLAGS) $(LOCAL_LDFLAGS)

  OBJS_TO_CLEAN += $(OBJS)

  ##############################################################################
  # End of targets related to logging API / SampleLoggingApp
  $(call pop,VARIANT_PREFIX)
  $(call pop,VARIANT_CPPFLAGS)
  $(call pop,TARGET_VRIANT)
  ##############################################################################

endif


################################################################################
# Now create AMRWBProfiler executable

# Will use new list of objects
#OBJS :=

#$(call def-subsys,AMRWBPROFILER_APP,$(WORKING_DIR)common/src/pfimpl_mptt/jni/audio_xface/src/AMR/AMRWBProfiler)

#----------------------
#AMRWBPROFILER_TARGET=$(LIBDIR)/AMRWBProfiler

#$(call declare-phony-target,amrwbprofiler,"Builds AMRWBProfiler application")

#ifeq ($(TARGET_PLATFORM),ios)
#amrwbprofiler:
#	@cd ./common/src/pfimpl_mptt/jni/audio_xface/src/AMR/AMRWBProfiler && \
#	xcodebuild -target AMRWBProfiler -sdk iphoneos \
#               -configuration Running -scheme AMRWBProfiler \
#               GCC_PREPROCESSOR_DEFINITIONS="$(STACK) $(BUILDTYPE) NO_VSELP_TEST"

#else
#amrwbprofiler: $(AMRWBPROFILER_TARGET)

#$(AMRWBPROFILER_TARGET): $(OBJS) $(LIBTARGET)
#	@echo Making $(notdir $@) executable
#	@-mkdir -p $(dir $@)
#	@$(CXX) -o $@ $^ $(COMMON_LDFLAGS) $(LOCAL_LDFLAGS)

#endif

#amrwbprofiler_clean:
#	@cd ./common/src/pfimpl_mptt/jni/audio_xface/src/AMR/AMRWBProfiler && \
#	xcodebuild -target AMRWBProfiler -sdk iphoneos \
#               -configuration Running -scheme AMRWBProfiler clean \
#               GCC_PREPROCESSOR_DEFINITIONS="$(STACK) $(BUILDTYPE) NO_VSELP_TEST"
#	@-rm -f $(OBJS) $(AMRWBPROFILER_TARGET)

#OBJS_TO_CLEAN += $(OBJS)

################################################################################
# the target to check that all the executables involved into nightly testing
# can be successfully built
.PHONY : check-nightly-test-executables
check-nightly-test-executables:
	@echo Running check-nightly-test-executables for $(TARGET_PLATFORM) platform is not yet supported

################################################################################
# Target to run all the implemented PTT unit tests except marked as 'Nightly'
#
$(call declare-phony-target,run-$(PTT_PREFIX)unittests,"Builds and runs all PTT unit tests except marked as 'Nightly'")
ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
  run-$(PTT_PREFIX)unittests : $(addprefix run_,$($(PTT_PREFIX)UTs))
else
  run-$(PTT_PREFIX)unittests :
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif

################################################################################
# Target to run all the implemented PTT unit tests including 'Nightly'
#
$(call declare-phony-target,run-nightly-$(PTT_PREFIX)unittests,"Builds and runs 'nightly' \(extended\) set of PTT unit tests")
ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
  run-nightly-$(PTT_PREFIX)unittests : $(addprefix run_nightly_,$($(PTT_PREFIX)UTs))
  # run-ios-audio-unittest is excluded because test freeses when runs on build server
  # run-nightly-$(PTT_PREFIX)unittests : run-ios-audio-unittest
else
  run-nightly-$(PTT_PREFIX)unittests :
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif

################################################################################
# Target to run disabled PTT unit tests
#
$(call declare-phony-target,run-disabled-$(PTT_PREFIX)unittests,"Builds and runs disabled PTT unit tests")
ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
  run-disabled-$(PTT_PREFIX)unittests : $(addprefix run_disabled_,$($(PTT_PREFIX)UTs))
else
  run-disabled-$(PTT_PREFIX)unittests :
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif

################################################################################
# Target to run disabled logging unit tests
#
$(call declare-phony-target,show-$(PTT_PREFIX)unittests,"Prints list of avaiable logging unit tests")
ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
  show-$(PTT_PREFIX)unittests : $(addprefix show_,$($(PTT_PREFIX)UTs))
else
  show-$(PTT_PREFIX)unittests :
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif


################################################################################
# Target to run all the implemented logging unit tests except marked as 'Nightly'
#
$(call declare-phony-target,run-$(LOGGING_PREFIX)unittests,"Builds and runs all logging unit tests except marked as 'Nightly'")
ifeq ($(TARGET_PLATFORM),host-32)
  run-$(LOGGING_PREFIX)unittests : $(addprefix run_,$($(LOGGING_PREFIX)UTs))
else
  run-$(LOGGING_PREFIX)unittests : $(addprefix run_,$($(LOGGING_PREFIX)UTs))
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif

################################################################################
# Target to run all the implemented unit tests including 'Nightly'
#
$(call declare-phony-target,run-nightly-$(LOGGING_PREFIX)unittests,"Builds and runs 'nightly' \(extended\) set of logging unit tests")
ifeq ($(TARGET_PLATFORM),host-32)
  run-nightly-$(LOGGING_PREFIX)unittests : $(addprefix run_nightly_,$($(LOGGING_PREFIX)UTs))
  # run-ios-audio-unittest is excluded because test freeses when runs on build server
  # run-nightly-$(LOGGING_PREFIX)unittests : run-ios-audio-unittest
else
  run-nightly-$(LOGGING_PREFIX)unittests :
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif

################################################################################
# Target to run disabled unit tests
#
$(call declare-phony-target,run-disabled-$(LOGGING_PREFIX)unittests,"Builds and runs disabled logging unit tests")
ifeq ($(TARGET_PLATFORM),host-32)
  run-disabled-$(LOGGING_PREFIX)unittests : $(addprefix run_disabled_,$($(LOGGING_PREFIX)UTs))
else
  run-disabled-$(LOGGING_PREFIX)unittests :
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif

################################################################################
# Target to run disabled unit tests
#
$(call declare-phony-target,show-$(LOGGING_PREFIX)unittests,"Prints list of avaiable logging unit tests")
ifeq ($(TARGET_PLATFORM),host-32)
  show-$(LOGGING_PREFIX)unittests : $(addprefix show_,$($(LOGGING_PREFIX)UTs))
else
  show-$(LOGGING_PREFIX)unittests :
	@echo Running $@ for $(TARGET_PLATFORM) platform is not yet supported
endif

################################################################################
# Runs TestApp's functional tests during nightly build verification
#
#$(call declare-phony-target,run-nightly-testapp,"Builds and executes TestApp application during nightly build")
#run-nightly-testapp : $(TESTAPP_TARGET)
#ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
#run-nightly-testapp : | testapp
#	$(warning TODO: implement TestApp nightly test running; there is corresponding "Intergrate Test App (3P API)" task)
#	$(warning For now, the existing script is just executed in order to check nightly test run logic)
#	-@$(WORKING_DIR)3papi/src/TestApp/run-gerrit-tests.sh
#TODO: temporarily commented out due to compilation error to allow nightly builds debugging by SCM
#	$(warning For now, testapp tests are temporarily disabled due to errors in ones)
#else
#	@echo Running nightly tests for $(TARGET_PLATFORM) platform is not yet supported
#endif

################################################################################
# Runs AMRWBProfiler tests during nightly build verification
#
#$(call declare-phony-target,run-nightly-amrwbprofiler,"Builds and executes AMRWBProfiler tests for nightly builds")
#run-nightly-amrwbprofiler:
#ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
#run-nightly-amrwbprofiler: | amrwbprofiler
#	-@$(WORKING_DIR)common/src/pfimpl_mptt/jni/audio_xface/src/AMR/AMRWBProfiler/run-nightly-tests.sh $(LIBDIR)
#else
#	@echo Running of nightly AMRWBProfiler tests for $(TARGET_PLATFORM) platform is not yet supported
#endif

################################################################################
# Runs functional tests during nightly build verification
#
#$(call declare-phony-target,run-nightly-functests,"Builds and executes tests for nightly builds")
#run-nightly-functests :
#ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
#  run-nightly-functests : run-nightly-testapp run-nightly-testntpdate run-nightly-amrwbprofiler
#else
#	@echo Running of nightly functional tests for $(TARGET_PLATFORM) platform is not yet supported
#endif

################################################################################
# Gerrit nightly tests target
# this target is intended to run nightly tests
#
$(call declare-phony-target,run-nightly-tests,"run nightly tests")
#run-nightly-tests: run-nightly-functests run-unittests audio-xface-utest amrwbprofiler
run-nightly-tests: run-unittests

################################################################################
# Gerrit verification tests target
# this target is intended to run tests during Gerrit commit verification build
#
$(call declare-phony-target,run-gerrit-tests,"run tests")
#run-gerrit-tests: check-nightly-test-executables run-unittests audio-xface-utest
run-gerrit-tests: check-nightly-test-executables run-unittests

################################################################################
# Code coverage
$(call declare-phony-target,run-nightly-code-coverage,"run nightly code coverage")
$(call declare-phony-target,run-gerrit-code-coverage,"run code coverage")

ifeq ($(COVERAGE),1)
ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)
run-nightly-gcovr: | run-nightly-tests
run-gerrit-gcovr: | run-gerrit-tests

_common_gcovr_options =        \
  --print-summary              \
  --object-directory=$(OBJDIR) \
  --root=$(WORKING_DIR)        \
  $(addprefix --exclude=,$(subst $(WORKING_DIR),,$(realpath $(GCOVR_EXCLUDES)))) \
  $(addprefix --exclude=,$(subst $(WORKING_DIR),,$(realpath $(UTSRCs))))         \
  $(addprefix --exclude=,$(GCOVR_EXCLUDES_REGEXP))

run-nightly-gcovr run-gerrit-gcovr:
	@echo "[ GCOVR ] Cleaning output directory"
	@-$(RM) -r $(GCOVR_REPORT_DIR)
	@mkdir -p $(GCOVR_REPORT_DIR)
	@echo "[ GCOVR ] Generating code coverage report to $(call expand-local-path,$(GCOVR_XML_REPORT),$(LOCAL_PATH))"
	@$(GCOVR) $(_common_gcovr_options) --xml --xml-pretty --output=$(GCOVR_XML_REPORT)
	@echo "[ GCOVR ] Generating code coverage report to $(call expand-local-path,$(GCOVR_HTML_REPORT),$(LOCAL_PATH))"
	@$(GCOVR) $(_common_gcovr_options) --html --html-details --sort-percentage --output=$(GCOVR_HTML_REPORT)

run-nightly-code-coverage: all run-nightly-tests run-nightly-gcovr

run-gerrit-code-coverage: all run-gerrit-tests run-gerrit-gcovr

else
run-nightly-gcovr run-gerrit-gcovr run-nightly-code-coverage run-gerrit-code-coverage:
	@echo Code coverage for $(TARGET_PLATFORM) platform is not yet supported
endif
endif

################################################################################
# Gerrit nightly builds target
# this target is intended to make and verify nightly 3P API library builds
#
$(call declare-phony-target,nightly-check-ptt-sdk,"Target used by Jenkins for nightly build \& check")
nightly-check-ptt-sdk : all run-nightly-tests
ifeq ($(COVERAGE),1)
  nightly-check-ptt-sdk : run-nightly-gcovr
endif


################################################################################
# Gerrit verification target
# Target is intended to be built during Gerrit commit verification build
#
$(call declare-phony-target,gerrit-verify-ptt-sdk,"Target used by Gerrit for commit verification")
gerrit-verify-ptt-sdk : all run-gerrit-tests
ifeq ($(COVERAGE),1)
  gerrit-verify-ptt-sdk : run-gerrit-gcovr
endif

################################################################################
# GCOVR related files clean tragets
.PHONY : clean-gcovr-db
clean-gcovr-db :
	@echo Removing .gcda files from $(OBJDIR)
	@$(call xargs,$(RM) ,$(patsubst %.$(OBJEXT),%.gcda,$(OBJS_TO_CLEAN)))
	@$(call xargs,$(RM) ,$(addsuffix .gcda,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))
	@$(call xargs,$(RM) ,$(addsuffix _test.gcda,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))

.PHONY : clean-gcovr-reports
clean-gcovr-reports :
	@echo Removing code coverage reports
	@$(call xargs,$(RM) ,$(addsuffix .gtest_report.xml,$(subst $(OBJDIR),$(LIBDIR),$(UTs))))
	@$(RM) $(GCOVR_XML_REPORT)
	@$(RM) $(GCOVR_HTML_REPORT)
	@$(RM) $(GCOVR_REPORT_DIR)/*.html


################################################################################
$(call declare-phony-target,clean,"Cleans built targets and intermediate files")
clean : clean-gtest clean-gcovr-db clean-gcovr-reports clean-swig
	@echo Removing object files from $(OBJDIR)
	@$(call xargs,$(RM) ,$(OBJS_TO_CLEAN) $(patsubst %.$(OBJEXT),%.d,$(OBJS_TO_CLEAN)))
	@echo Removing $(notdir $(LIBTARGET)) from $(LIBDIR)
	@$(RM) $(LIBTARGET)
	@echo Removing $(notdir $(LIBAUDIO)) from $(LIBDIR)
	@$(RM) $(LIBAUDIO)
	@echo Removing $(notdir $(LIBSQLITE)) from $(OBJDIR)
	@$(RM) $(LIBSQLITE)
	@echo Removing $(notdir $(SAMPLEAPP_TARGET)) from $(LIBDIR)
	@$(RM) $(SAMPLEAPP_TARGET)
	@echo Removing $(notdir $(SAMPLELOGGINGAPP_TARGET)) from $(LIBDIR)
	@$(RM) $(SAMPLELOGGINGAPP_TARGET)
	@echo Removing $(notdir $(TESTAPP_TARGET)) from $(LIBDIR)
	@$(RM) $(TESTAPP_TARGET)
	@echo Removing unit test executables from $(LIBDIR)
	@$(call xargs,$(RM) , $(UTs) $(TESTNTPDATE_TARGET))
	@echo Removing unit test object files from $(OBJDIR)
	@$(call xargs,$(RM) , $(addsuffix .d,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))
	@$(call xargs,$(RM) , $(addsuffix .o,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))
	@$(call xargs,$(RM) , $(addsuffix _test.d,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))
	@$(call xargs,$(RM) , $(addsuffix _test.o,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))
    ifeq ("$(TARGET_PLATFORM)-$(BLDTYPE)","host-debug")
	  @$(call xargs,$(RM) -r,$(addsuffix .dSYM,$(UTs)))
    endif
	@echo Removing .gcno files from $(OBJDIR)
	@$(call xargs,$(RM) ,$(patsubst %.$(OBJEXT),%.gcno,$(OBJS_TO_CLEAN)))
	@$(call xargs,$(RM) ,$(addsuffix .gcno,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))
	@$(call xargs,$(RM) ,$(addsuffix _test.gcno,$(subst $(LIBDIR),$(OBJDIR),$(UTs))))
	@echo Removing code coverage report directory
	@$(RM) -r $(GCOVR_REPORT_DIR)
	@echo Removing doxygen output
	@$(RM) -r $(DOXY_HTML_OUT)
	@$(RM) -r $(DOXY_LATEX_OUT)
	@echo Removing UPTT generated files
	@$(RM) $(UPTT_PYTHON_SRC) $(subst $(UPTT).cpp,$(UPTT).h,$(UPTT_PYTHON_SRC))
	@echo "Build '$(BLDTYPE)' for target platform '$(TARGET_PLATFORM)' has been cleaned"


################################################################################
.PHONY : __HelpBanner__
__HelpBanner__ :
	@echo "\n==== PTT API  [&  PTT Audio] libraries build system ===="
	@echo "\nThe following variables should be defined for the make targets below:"
	@echo "\tTARGET_PLATFORM=<target platform> - specifies target platform; can be one of the following:"
	@echo "\t\tios(default), android, blackberry, host, host-32, host-64,"
	@echo "\t\tiphonesimulator, iphonesimulator-32, iphonesimulator-64"
	@echo "\tTARGET_ARCHITECTURE=<arch> - specifies target architecture; can be one of the following:"
	@echo "\t\tarmv7, armv7s, arm64 - if target platform is 'ios'; omitting forces build for all three together"
	@echo "\t\tarmv7-a(default) - if target platform is 'android'"
	@echo "\t\tx86, x86_64 - if target platform is 'host' or 'iphonesimulator'; default is x86"
	@echo "\tNDK_ROOT=/path/to/ndk - specifies path to Android NDK; obligatory if 'android' target is specified"
	@echo "\nThe following variables can be defined:"
	@echo "\tBUILDTYPE=[string] - overrides default '$(BUILDTYPE)' compiler macro"
	@echo "\tdebug=[1|true|y|Y|yes|Yes|YES|on|On|ON] - any of listed values forces build targets with debug info included"
	@echo "\tCOVERAGE=[1|true|y|Y|yes|Yes|YES|on|On|ON] - any of listed values enables code coverage generation"
	@echo "\tkpi=[1|true|y|Y|yes|Yes|YES|on|On|ON] - any of listed values forces build targets with KPI markers feature"
	@echo "\nThe following make targets are available:"

$(call declare-phony-target,help,"Prints this help")
help : __HelpBanner__


################################################################################
include $(wildcard $(OBJDIR)/*.d)
include $(wildcard $(LIBDIR)/*.d)
