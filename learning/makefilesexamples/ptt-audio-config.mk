#-------------------------------------------------------------------------------
# Audio codecs configuration
#-----------------------------------
# Audio codec properties to check
# space-separated list of known (supported) codecs
_KNOWN_AUDIO_CODECS = AMRWB AMRWB_66 AMBE VSELP

# space-separated list of loadable codecs
_KNOWN_LOADABLE_CODECS = AMBE

# space-separated list of statically linkable codecs
_KNOWN_LINKABLE_CODECS = AMRWB AMRWB_66 AMBE VSELP

# space-separated list of mutually exclusive codecs 
# (either statically linked or loadable)
_MUTUALLY_EXCLUSIVE_CODECS = AMBE

#-----------------------------------
# default set of codecs to support
# (space-separated list of default codecs)
DEFAULT_AUDIO_CODECS = AMRWB_66 VSELP

#-----------------------------------
# default set of codecs to load dynamically, now empty
# (space-separated list of default codecs)
DEFAULT_LOADABLE_AUDIO_CODECS =

#-----------------------------------
# process optional list of statically linked codecs
# use DEFAULT_AUDIO_CODECS if AUDIO_CODECS was not specified
LINKED_CODECS ?= $(DEFAULT_AUDIO_CODECS)
$(call validate-codecs,linkable_audio_codecs,$(LINKED_CODECS),statically linked)
# check whether remaining codecs are known as statically linkable
_wrong_linkable_audio_codecs=$(filter-out $(_KNOWN_LINKABLE_CODECS),$(linkable_audio_codecs))
ifneq ($(_wrong_linkable_audio_codecs),)
  $(error Codec(s) $(_wrong_linkable_audio_codecs) cannot be linked statically)
endif

#-----------------------------------
# process optional list of dynamically loadable codecs
# use DEFAULT_LOADABLE_AUDIO_CODECS if LOADABLE_CODECS was not specified
LOADABLE_CODECS ?= $(DEFAULT_LOADABLE_AUDIO_CODECS)
$(call validate-codecs,loadable_audio_codecs,$(LOADABLE_CODECS),dynamically loadable)
# check whether specified loadable codecs are known as loadable
_wrong_loadable_audio_codecs:=$(filter-out $(_KNOWN_LOADABLE_CODECS),$(loadable_audio_codecs))
ifneq ($(_wrong_loadable_audio_codecs),)
  $(error Codec(s) $(_wrong_loadable_audio_codecs) cannot be loaded dynamically)
endif

supported_audio_codecs = $(sort $(linkable_audio_codecs) $(loadable_audio_codecs))

# check for supported_audio_codecs and loadable_audio_codecs consistency
_both_loadable_and_static_codecs=$(filter $(linkable_audio_codecs),$(loadable_audio_codecs))
_wrong_loadable_and_linkable_codecs=$(filter $(_MUTUALLY_EXCLUSIVE_CODECS),$(_both_loadable_and_static_codecs))
ifneq ($(_wrong_loadable_and_linkable_codecs),)
  $(error Codec(s) $(_wrong_loadable_and_linkable_codecs) shall be either statically linked or loadable)
endif

# check for non-empty list of codecs
ifeq ($(loadable_audio_codecs)$(linkable_audio_codecs),)
  $(error As minimum one codec shall be specified)
endif


# report effective codecs configuratoin
$(info Supported codec(s)        : "$(supported_audio_codecs)")
$(info Statically linked codec(s): "$(linkable_audio_codecs)")
$(info Loadable codec(s)         : "$(loadable_audio_codecs)")

# Generate list of macros for CPP command line
USE_VOCODER_MACROS=$(addprefix HAS_FEATURE_AUDIO_,$(supported_audio_codecs))
USE_EXT_VOCODER_MACROS=$(addprefix HAS_FEATURE_LOADABLE_AUDIO_,$(loadable_audio_codecs))

#generate list of feature definitions to use in makefiles
$(foreach codec,$(supported_audio_codecs),$(eval HAS_FEATURE_AUDIO_$(codec):=yes))
$(foreach codec,$(loadable_audio_codecs), $(eval HAS_FEATURE_LOADABLE_AUDIO_$(codec):=yes))
$(foreach codec,$(linkable_audio_codecs), $(eval HAS_FEATURE_LINKABLE_AUDIO_$(codec):=yes))
