# Toolchain executables

# TARGET_PLATFORM must be defined
ifdef TARGET_PLATFORM
  $(info Setting up toolchain for $(TARGET_PLATFORM))
else
  $(error TARGET_PLATFORM must be defined before including $(notdir $(lastword $(MAKEFILE_LIST))))
endif

override TARGET_DIR :=

# by default, logging targets are disabled. Choosing the host-32 target platform 
# will have overriden the variable with value yes.
# Choosing the host-64 platform and target 'run_ct_functionaltests' allows usage
# of 32-bit SampleLoggingApp

override LOGGING_TARGET_SUPPORTED:=no

################################################################################
# Android
ifeq ($(TARGET_PLATFORM), android)
  # Check for Android NDK
  ifeq ("$(NDK_ROOT)","")
    #TODO: Implement Android toolchain support in addition to NDK
    $(error NDK_ROOT is not defined - cannot build Android target)
  else
    _NDK_DIR        ?= $(NDK_ROOT)
  endif

  override TARGET_DIR := android

  # Use TARGET_ARCHITECTURE armv7-a
  ifneq ($(TARGET_ARCHITECTURE),armv7-a)
    ifneq ($(TARGET_ARCHITECTURE),)
      $(warning TARGET_ARCHITECTURE $(TARGET_ARCHITECTURE) - ignored)
    endif
    override TARGET_ARCHITECTURE := armv7-a
  endif

  $(info Making "$(TARGET_ARCHITECTURE)" Android target)

  # Hardware and ABI version
  TARGET_ARCH_ABI ?= armeabi-v7a

  # Android toolchain specifics - arch, gcc versioin, api version
  _GCC_VER        ?= 4.8
  _API_VER        ?= android-18
  _ARCH           ?= arm

  # Some intermediate definitions related to SDK's Android toolchain
  _TOOLCHAIN_PREFIX=$(_ARCH)-linux-androideabi
  _TOOLCHAIN_DIR   = $(_NDK_DIR)/toolchains/$(_TOOLCHAIN_PREFIX)-$(_GCC_VER)/prebuilt/$(HOST_TYPE)-$(HOST_ARCH)
  _TOOLCHAIN_BINDIR=$(_TOOLCHAIN_DIR)/bin

  # Toolchain specific includes
  _TOOLCHAIN_INCDIRROOT=$(_NDK_DIR)/sources/cxx-stl/gnu-libstdc++/$(_GCC_VER)

  _TOOLCHAIN_INCDIRS += \
    $(_TOOLCHAIN_INCDIRROOT)/libs/$(TARGET_ARCH_ABI)/include \
    $(_TOOLCHAIN_INCDIRROOT)/include \
    $(_TOOLCHAIN_INCDIRROOT)/include/backward \
    $(_NDK_DIR)/platforms/$(_API_VER)/arch-$(_ARCH)/usr/include \
    $(_NDK_DIR)/sources/cxx-stl/gnu-libstdc++/$(GCC_VER)/include

  # Toolchain tools
  CPP =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-gcc -E $(addprefix -I,$(_TOOLCHAIN_INCDIRS))
  CXXCPP =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-g++ -E $(addprefix -I,$(_TOOLCHAIN_INCDIRS))
  CC  =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-gcc
  CXX =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-g++
  AR  =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-ar

  _PLATFORM_DEFINES=ANDROID ARM _ARM_ ARMV4 T_ARM
  # Additional macro to distinguish between the leagcy native Android client 
  # and our platform agnostic solution when building for the Android platform.
  _PLATFORM_DEFINES += PLATFORM_AGNOSTIC

  _TOOLCHAIN_COMPILER_FLAGS = -march=armv7-a -mfloat-abi=softfp -marm -finline-limit=64
  _TOOLCHAIN_COMPILER_FLAGS += -no-canonical-prefixes -pthread
  ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
    _TOOLCHAIN_COMPILER_FLAGS += -mfpu=neon
  else
    _TOOLCHAIN_COMPILER_FLAGS += -mfpu=vfpv3-d16
  endif

  _TOOLCHAIN_CXX_FLAGS = -std=c++11

  #TODO: this is done to specify neon support for Android target. It could be a beeter solution for this.
  TARGET_ARCH_ABI ?= armeabi-v7a

  _TOOLCHAIN_LIBS = c android m log dl OpenSLES

  #TODO: Flags are picked up from NDK's SampleApp dry-run build for armeabi-v7a. Should we verify ones?
  _TOOLCHAIN_LDFLAGS = -L$(_NDK_DIR)/sources/cxx-stl/gnu-libstdc++/$(_GCC_VER)/libs/$(TARGET_ARCH_ABI) \
                       -L$(_NDK_DIR)/platforms/$(_API_VER)/arch-$(_ARCH)/usr/lib \
                       -Wl,-rpath-link=$(_NDK_DIR)/platforms/$(_API_VER)/arch-$(_ARCH)/usr/lib \
                       --sysroot=$(_NDK_DIR)/platforms/$(_API_VER)/arch-$(_ARCH) \
                       -Wl,--gc-sections \
                       -Wl,-z,nocopyreloc \
                       -Wl,--fix-cortex-a8  \
                       -march=armv7-a \
                       -fPIE -pie \
                       -Wl,--no-undefined \
                       -Wl,-z,noexecstack \
                       -Wl,-z,relro \
                       -Wl,-z,now  \
                       $(addprefix -l,$(_TOOLCHAIN_LIBS))

################################################################################
# Host
else ifneq ($(filter $(TARGET_PLATFORM),host host-32 host-64),)

  ifeq ($(filter x86%, $(HOST_ARCH)),)
    $(error Target $(TARGET_PLATFORM) can be built on x86 based systems only)
  endif

  ifeq ($(TARGET_PLATFORM),host-32)
    ifeq ($(TARGET_ARCHITECTURE),x86_64)
      $(error Wrong target arch $(TARGET_ARCHITECTURE) for target $(TARGET_PLATFORM))
    else
      override TARGET_ARCHITECTURE ?= x86
    endif
  else ifeq ($(TARGET_PLATFORM),host-64)
    ifeq ($(TARGET_ARCHITECTURE),x86)
      $(error Wrong target arch $(TARGET_ARCHITECTURE) for target $(TARGET_PLATFORM))
    else
      override TARGET_ARCHITECTURE ?= x86_64
    endif
  endif

  # Use TARGET_ARCHITECTURE x86_64 or x86(default)
  override TARGET_ARCHITECTURE ?= x86
  ifneq ($(filter-out x86 x86_64,$(TARGET_ARCHITECTURE)),)
    $(warning Target arch $(TARGET_ARCHITECTURE) ignored; using x86 instead)
    override TARGET_ARCHITECTURE := x86
  endif

  # x86_64 target is not valid on x86 host
  ifneq ($(HOST_ARCH),x86_64)
    ifneq ($(TARGET_ARCHITECTURE),x86)
      $(error Wrong target $(TARGET_ARCHITECTURE) on host $(HOST_ARCH))
    endif
  endif

  ifeq ($(TARGET_ARCHITECTURE),x86)
    override TARGET_DIR := host-32
    override LOGGING_TARGET_SUPPORTED:=yes
  else
    override TARGET_DIR := host-64
    override LOGGING_TARGET_SUPPORTED:=conditionally
  endif

  ifneq ($(HOST_TYPE),darwin)
    $(warning Target $(TARGET_PLATFORM) is not yet fully implemented/tested)
  endif


  CPP =gcc -E
  CC  =-gcc
  CXX =g++
  AR  =ar

  _PLATFORM_DEFINES := UNIX_BUILD

  ifeq ($(HOST_TYPE),darwin)
    _PLATFORM_DEFINES += __APPLE__
  endif

  #TODO Investigate why it was commented out. Remove if actually unnecessary
  #_PLATFORM_DEFINES += HAVE_ARPA_NAMESER_H HAVE_ARPA_NAMESER_COMPAT_H

  #TODO dirty solution but this definition used in many places
  _PLATFORM_DEFINES += T_ARM

  ifeq ($(HOST_TYPE),darwin)
    ifeq ($(TARGET_ARCHITECTURE),x86)
      _TOOLCHAIN_COMPILER_FLAGS = -arch i386
      _TOOLCHAIN_LDFLAGS = -arch i386
    else
      _TOOLCHAIN_COMPILER_FLAGS = -arch x86_64
      _TOOLCHAIN_LDFLAGS = -arch x86_64
    endif
  else
    ifeq ($(TARGET_ARCHITECTURE),x86_64)
      _TOOLCHAIN_COMPILER_FLAGS = -m64
      _TOOLCHAIN_LDFLAGS = -m64 -lrt
    else
      _TOOLCHAIN_COMPILER_FLAGS = -m32
      _TOOLCHAIN_LDFLAGS = -m32 -lrt
    endif
  endif
  _TOOLCHAIN_COMPILER_FLAGS += -no-canonical-prefixes -pthread
  _TOOLCHAIN_LDFLAGS += -lpthread -ldl

  _TOOLCHAIN_CXX_FLAGS = -std=c++11

  ifeq ($(HOST_TYPE),darwin)
    _FRAMEWORKS := AVFoundation AudioToolbox Foundation AudioUnit
    _TOOLCHAIN_LDFLAGS += $(addprefix -framework ,$(_FRAMEWORKS))
  endif

################################################################################
# iOS
else ifeq ($(TARGET_PLATFORM),ios)
  # verify host system
  ifneq ($(HOST_TYPE),darwin)
    $(error Mac OS X host is required to build iOS target)
  endif

  # Use TARGET_ARCHITECTURE arm64 or armv7s or armv7(default)
  ifneq ($(TARGET_ARCHITECTURE),arm64)
    ifneq ($(TARGET_ARCHITECTURE),armv7s)
      ifneq ($(TARGET_ARCHITECTURE),armv7)
        ifneq ($(TARGET_ARCHITECTURE),)
          $(warning TARGET_ARCHITECTURE $(TARGET_ARCHITECTURE) - ignored)
        endif
        override TARGET_ARCHITECTURE := armv7 armv7s arm64
        override TARGET_DIR := ios-universal
      else
        override TARGET_DIR := ios-armv7
      endif
    else
      override TARGET_DIR := ios-armv7s
    endif
  else
    override TARGET_DIR := ios-arm64
  endif

  $(info Making "$(TARGET_ARCHITECTURE)" iOS target)

#  MIN_IOS_SDK  =

  CC  =$(shell xcrun --sdk iphoneos$(MIN_IOS_SDK) --find clang)
  CXX =$(shell xcrun --sdk iphoneos$(MIN_IOS_SDK) --find clang++)
  CPP =$(CXX) -E
  AR  =ar

  IOS_SDK_PATH =$(shell xcrun --sdk iphoneos$(MIN_IOS_SDK) --show-sdk-path)

  _FRAMEWORKS := AVFoundation AudioToolbox Foundation

  _PLATFORM_DEFINES := __APPLE__ TARGET_OS_IPHONE=1

  _PLATFORM_DEFINES += T_ARM

  _TOOLCHAIN_COMPILER_FLAGS := $(foreach arch,$(TARGET_ARCHITECTURE),-arch $(arch))
  _TOOLCHAIN_COMPILER_FLAGS += -isysroot $(IOS_SDK_PATH)
  _TOOLCHAIN_COMPILER_FLAGS += -no-canonical-prefixes -pthread

  _TOOLCHAIN_CXX_FLAGS = -std=c++11 -stdlib=libc++

  _TOOLCHAIN_LDFLAGS := $(foreach arch,$(TARGET_ARCHITECTURE),-arch $(arch))
  _TOOLCHAIN_LDFLAGS += -isysroot $(IOS_SDK_PATH)
  _TOOLCHAIN_LDFLAGS += -stdlib=libc++ -lresolv
  _TOOLCHAIN_LDFLAGS += $(addprefix -framework ,$(_FRAMEWORKS))

  #TODO: this is done to specify neon support for iOS target. It could be a beeter solution for this.
  TARGET_ARCH_ABI ?= armeabi-v7a

  # iOS will use FAT libraries which should be created with a different tool
  define create-static-library
    libtool -o $(1) $(2)
  endef

  define merge-static-libraries
    libtool -o $(1) $(1) $(2)
  endef

################################################################################
# iOS Phone Simulator
else ifneq ($(filter $(TARGET_PLATFORM),iphonesimulator iphonesimulator-32 iphonesimulator-64),)
  # verify host system
  ifneq ($(HOST_TYPE),darwin)
    $(error Mac OS X host is required to build iPhoneSimulator target)
  endif

  ifeq ($(TARGET_PLATFORM),iphonesimulator-32)
    ifeq ($(TARGET_ARCHITECTURE),x86_64)
      $(error Wrong parameters)
    else
      override TARGET_ARCHITECTURE ?= x86
    endif
  else ifeq ($(TARGET_PLATFORM),iphonesimulator-64)
    ifeq ($(TARGET_ARCHITECTURE),x86)
      $(error Wrong parameters)
    else
      override TARGET_ARCHITECTURE ?= x86_64
    endif
  endif

  _TARGET_ARCHITECTURE = i386
  ifneq ($(TARGET_ARCHITECTURE),x86_64)
    ifneq ($(TARGET_ARCHITECTURE),x86)
      ifneq ($(TARGET_ARCHITECTURE),)
        $(warning TARGET_ARCHITECTURE $(TARGET_ARCHITECTURE) - ignored)
      endif
      override TARGET_ARCHITECTURE := x86 x86_64
      override TARGET_DIR := iphonesimulator-universal
      _TARGET_ARCHITECTURE = i386 x86_64
    else
      override TARGET_DIR := iphonesimulator-32
      _TARGET_ARCHITECTURE = i386
    endif
  else
    override TARGET_DIR := iphonesimulator-64
    _TARGET_ARCHITECTURE = x86_64
  endif

  CC  =$(shell xcrun --sdk iphonesimulator --find clang)
  CXX =$(shell xcrun --sdk iphonesimulator --find clang++)
  CPP =$(CXX) -E
  AR  =ar

  IOS_SDK_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)

  _FRAMEWORKS := AVFoundation AudioToolbox Foundation

  _PLATFORM_DEFINES := __APPLE__
  _PLATFORM_DEFINES += T_ARM

  _TOOLCHAIN_COMPILER_FLAGS := $(foreach arch,$(_TARGET_ARCHITECTURE),-arch $(arch))
  _TOOLCHAIN_COMPILER_FLAGS += -isysroot $(IOS_SDK_PATH)
  _TOOLCHAIN_COMPILER_FLAGS += -miphoneos-version-min=$(MIN_IOS_SDK)
  _TOOLCHAIN_COMPILER_FLAGS += -no-canonical-prefixes -pthread

  _TOOLCHAIN_CXX_FLAGS = -std=c++11 -stdlib=libc++

  _TOOLCHAIN_LDFLAGS := $(foreach arch,$(_TARGET_ARCHITECTURE),-arch $(arch))
  _TOOLCHAIN_LDFLAGS += -isysroot $(IOS_SDK_PATH)
  _TOOLCHAIN_LDFLAGS += -stdlib=libc++ -lresolv
  _TOOLCHAIN_LDFLAGS += $(addprefix -framework ,$(_FRAMEWORKS))
  _TOOLCHAIN_LDFLAGS += -miphoneos-version-min=$(MIN_IOS_SDK)

  # iPhoneSimulator will use FAT libraries which should be created with a different tool
  define create-static-library
    libtool -o $(1) $(2)
  endef

  define merge-static-libraries
    libtool -o $(1) $(1) $(2)
  endef

################################################################################
else ifeq ($(TARGET_PLATFORM),blackberry)
  # Check for BlackBerry NDK
  ifeq ($(and $(QDE),$(QNX_HOST),$(QNX_TARGET)),)
    $(error BlackBerry10 NDK is not installed - cannot build BlackBerry10 target)
  endif

  override TARGET_DIR := blackberry

  _GCC_VER        ?= 4.8.3
  _TOOLCHAIN_BINDIR=$(QNX_HOST)/usr/bin
  _TOOLCHAIN_PREFIX=ntoarmv7

  # Toolchain tools
  CPP =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-gcc-$(_GCC_VER) -E
  CXXCPP =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-g++-$(_GCC_VER) -E
  CC  =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-gcc-$(_GCC_VER)
  CXX =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-g++-$(_GCC_VER)
  AR  =$(_TOOLCHAIN_BINDIR)/$(_TOOLCHAIN_PREFIX)-ar

  _PLATFORM_DEFINES := BLACKBERRY PLATFORM_AGNOSTIC T_ARM

  _TOOLCHAIN_COMPILER_FLAGS = -fPIC -no-canonical-prefixes
  _TOOLCHAIN_COMPILER_FLAGS += -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16

  _TOOLCHAIN_CXX_FLAGS = -std=gnu++0x

  _TOOLCHAIN_LIBS = stdc++ m socket

  _TOOLCHAIN_LDFLAGS = -fuse-ld=bfd \
                       -fPIE -pie \
                       -Wl,--no-undefined \
                       -Wl,--no-keep-memory \
                       -Wl,--gc-sections \
                       -Wl,-z,nocopyreloc \
                       -Wl,-z,noexecstack \
                       -Wl,-z,relro \
                       -Wl,-z,now \
                       --sysroot=$(QNX_TARGET)/armle-v7 \
                       -Wl,-hash-style,gnu \
                       -march=armv7-a \
                       -Wl,-Bstatic $(addprefix -l,$(_TOOLCHAIN_LIBS)) \
                       -Wl,-Bdynamic -lc \
                       -Wl,--as-needed

################################################################################
else
  #TODO: Define other supported toolchains here
  $(error TARGET_PLATFORM=$(TARGET_PLATFORM) is not yet supported)
endif

