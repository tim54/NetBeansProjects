################################################################################
#
# Makefile that detects host type and architecture and sets host specific
# variables: PATH_DELIM, HOST_TYPE, HOST_ARCH
#
#===============================================================================
ifeq ($(OS),Windows_NT)
  PATH_DELIM  ?=\\
  HOST_TYPE   ?=windows
  ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
    HOST_ARCH ?=x86_64
  else
    HOST_ARCH ?=x86
  endif
else
  PATH_DELIM?=/

  _uname_s = $(shell uname -s)
  ifeq ($(_uname_s),Linux)
    HOST_TYPE=linux
  endif
  ifeq ($(_uname_s),Darwin)
    HOST_TYPE?=darwin
  endif
  ifeq ($(_uname_s), Solaris)
    #TODO: check is this correct assignment and will work
    HOST_TYPE?=solaris
  endif

  #If unknown, will use 'unknown' as a placeholder
  HOST_TYPE ?= unknown
  ifeq ($(HOST_TYPE),unknown)
    $(warn Unknown host type ('uname -s' returned '$(_uname_s)')
  endif

  _uname_m = $(shell uname -m)
  ifeq ($(_uname_m),x86_64)
    #AMD64 (x86_64)
    HOST_ARCH ?=x86_64
  endif
  ifeq ($(filter-out i%86,$(_uname_m)),)
    #Intel ?86
    HOST_ARCH ?=x86
  endif
  ifneq ($(filter %86,$(_uname_m)),)
    #IA32
    HOST_ARCH ?=IA32
  endif
  ifneq ($(filter arm%,$(_uname_m)),)
    #ARM
    HOST_ARCH ?=ARM
  endif

  #If unknown use 'unknown' as a placeholder
  HOST_ARCH ?=unknown
  ifeq ($(HOST_ARCH),unknown)
    $(warn Unknown host architecture ('uname -m' returned '$(_uname_m)')
  endif
endif

$(info Using host configuration variables: HOST_TYPE=$(HOST_TYPE), HOST_ARCH=$(HOST_ARCH), PATH_DELIM=$(PATH_DELIM))
