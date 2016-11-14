################################################################################
# Make functions
################################################################################

# Subsystem's makefile name
_SUBSYS_MAKE=ptt-api-subsys.mk

#----------------------
# Helper function generating target that prints help info on given target
define _declare-target
  .PHONY : __help_$1
  __help_$1 : __HelpBanner__
	@echo "\t$1\t: $2"
  help : __help_$1
endef

#----------------------
# Creates 'help' target prerequisite that ptints this target and its
# description string
# arguments: $1 - target name
#            $2 - target description
declare-target = $(eval $(call _declare-target,$1,$2))

#----------------------
# Helper function generating target that prints help info on given target.
# In addition, given target is declared as .PHONY
define _declare-phony-target
  .PHONY : $1
  $(call declare-target,$1,$2)
endef

#----------------------
# Declares target as .PHONY and and creates 'help' target prerequisite
# that ptints this target and its description string
# arguments: $1 - target name
#            $2 - target description
declare-phony-target = $(eval $(call _declare-phony-target,$1,$2))

#----------------------
# Helper function returning directory name without trailing slash
# arguments: $1 - full pathname to extract containing directory from
_parent-dir = $(patsubst %/,%,$(dir $(1:%/=%)))

#----------------------
# Returns directory that the calling makefile is in
# arguments: none
# uses: name of last makefile from MAKEFILE_LIST
my-dir = $(call _parent-dir,$(lastword $(MAKEFILE_LIST)))

#----------------------
# Returns full path to the given directory using base directory to expand relative path if necessary
# arguments: $1 relative or absolute file name
#            $2 base directory the relative path is form
# uses: none
# note: this functions works only with unix-style paths that have '/' at the
# beginning of the absolyte pathname. Do not use it with Windows-style paths
# containing drive letter followed by colon.
expand-local-path = $(if $(patsubst /%,,$(strip $1)),$(strip $2)/$(strip $1),$(strip $1))

################################################################################
#======================
# Helper function generating C/C++ file compilation target and recipe
# $1 ==> $(OBJDIR)/$(basename $(notdir $1))$(OBJEXT_SUFFIX)
# $2 ==> submodule's name (obj. files names for conflicts resolution)
# arguments: $1 source file to be compiled
# uses: COMMOM_CXXFLAGS COMMON_CFLAGS CC CXX LOCAL_CFLAGS LOCAL_CXXFLAGS
#       LOCAL_INCLUDES OBJDIR OBJECT_SUFFIX LOCAL_DEFINES
define _mkobjrule
  $(if $(filter $(suffix $1), .c), \
      $(eval _compflags:=$(COMMON_CFLAGS) $(LOCAL_CFLAGS)) $(VARIANT_CFLAGS) \
      $(eval _compiler:=$(CC)) \
      $(eval _icon:=\[ C \] ) \
    , \
      $(eval _compflags:=$(COMMON_CXXFLAGS) $(LOCAL_CXXFLAGS)) $(VARIANT_CXXFLAGS) \
      $(eval _compiler:=$(CXX)) \
      $(eval _icon:=\[C++\] ) \
  )
	$(eval _objfile:=$(OBJDIR)/$(VARIANT_PREFIX)$(2).$(basename $(notdir $1))$(OBJEXT_SUFFIX))
  OBJS += $(_objfile)
  $(_objfile) : $(call expand-local-path,$1,$(LOCAL_PATH)) $(MK_DEPS)
	@echo $(_icon) $$(notdir $$@) \<= $(call expand-local-path,$1,$(LOCAL_PATH))
	@-mkdir -p $$(dir $$@)
	@$(_compiler) -c $(_compflags) $(COMMON_CPPFLAGS) $(LOCAL_CPPFLAGS) $(VARIANT_CPPFLAGS) \
                  $(addprefix -I,$(LOCAL_INCLUDES)) $(addprefix -D,$(LOCAL_DEFINES)) \
                  -o $$@ $(call expand-local-path,$1,$(LOCAL_PATH))
endef

mkobjrule = $(eval $(call _mkobjrule,$1,$2))

################################################################################
#======================
# Helper function generating C/C++ file compilation target and recipe
# $1 ==> source file name to build UT application for
# $2 ==> submodule's name (obj. files names for conflicts resolution)
# requires: test file shall present in the same directory (a_test.cpp for a.cpp)
# arguments: $1 source file to be compiled
# uses: COMMOM_CXXFLAGS COMMON_CFLAGS CC CXX LOCAL_CFLAGS LOCAL_CXXFLAGS
#       LOCAL_INCLUDES OBJDIR OBJECT_SUFFIX LOCAL_DEFINES LOCAL_NIGHTLY_UT_PATTERNS
define _mkutrule
  $(if $(filter $(suffix $1), .c), \
      $(eval _compflags:=$(COMMON_CFLAGS) $(LOCAL_CFLAGS)) $(VARIANT_CFLAGS)\
      $(eval _compiler:=$(CC)) \
      $(eval _icon:=\[ C  UT\] ) \
    , \
      $(eval _compflags:=$(COMMON_CXXFLAGS) $(LOCAL_CXXFLAGS)) $(VARIANT_CXXFLAGS)\
      $(eval _compiler:=$(CXX)) \
      $(eval _icon:=\[C++ UT\] ) \
  )

  $(eval _cxx:=$(CXX))
  $(eval _cxxflags:=$(COMMON_CXXFLAGS) $(LOCAL_CXXFLAGS) $(VARIANT_CXXFLAGS))

  $(eval _srcfullname:=$(notdir $1))
  $(eval _srcname:=$(basename $(_srcfullname)))
  $(eval _srcpathname:=$(call expand-local-path,$1,$(LOCAL_PATH)))
  $(eval _srcdir:=$(dir $(_srcpathname)))
  $(eval _objprefix:=$(OBJDIR)/$(VARIANT_PREFIX)$(2)__)
  $(eval _objpathname:=$(_objprefix)$(_srcname)$(OBJEXT_SUFFIX))
  $(eval _gcdapathname:=$(_objprefix)$(_srcname).gcda)
  $(eval _testaddon:=$(2)__$(_srcname)_ADDON)

  # check if the *_test.cpp file is specified instead of tested source
  $(if $(filter %_test.cpp, $(_srcpathname)), \
    $(eval _testsrcpathname:=) \
    $(eval _testobjpathname:=) \
  , \
    $(eval _testsrcname:=$(_srcname)_test.cpp) \
    $(eval _testsrcpathname:=$(wildcard $(_srcdir)$(_testsrcname)) $(wildcard $(_srcdir)../test/$(_testsrcname))) \
    $(eval _testobjpathname:=$(_objprefix)$(_srcname)_test$(OBJEXT_SUFFIX)) \
    $(eval _testgcdapathname:=$(_objprefix)$(_srcname)_test.gcda) \
  )

  $(eval _ut_includes:=$(foreach include,$(LOCAL_INCLUDES),$(include) $(include)/../stub/ $(include)/../source/))

  # build sources to objects
  $(_objpathname) :  $(_srcpathname) $(MK_DEPS)
	@echo $(_icon) $$(notdir $$@) \<= $(_srcpathname)
	@-mkdir -p $$(dir $$@)
	@$(_compiler) -c $(_compflags) $(COMMON_CPPFLAGS) $(LOCAL_CPPFLAGS) \
                  $(VARIANT_CPPFLAGS) $(OPT_COVERAGE_COMPILE_FLAGS) \
                  $(addprefix -I,$(_ut_includes)) \
                  $(addprefix -D,$(LOCAL_DEFINES)) \
                  -o $$@ \
                  $(_srcpathname)
	-@$(RM) $(_gcdapathname)

  ifneq "$(strip $(_testsrcpathname))" ""
    $(_testobjpathname) : $(_testsrcpathname) $(MK_DEPS)
	  @echo $(_icon) $$(notdir $$@) \<= $(_testsrcpathname)
	  @-mkdir -p $$(dir $$@)
	  @$(_cxx) -c $(_cxxflags) $(COMMON_CPPFLAGS) $(LOCAL_CPPFLAGS) \
               $(VARIANT_CPPFLAGS) $(OPT_COVERAGE_COMPILE_FLAGS) \
               $(addprefix -I,$(_ut_includes)) \
               $(addprefix -D,$(LOCAL_DEFINES)) \
               -o $$@ $(_testsrcpathname)
	-@$(RM) $(_testgcdapathname)
  endif

  UTSRCs += $(_testsrcpathname)

  # link sources
  $(eval _testexepathname:=$(LIBDIR)/$(VARIANT_PREFIX)$(2)__$(_srcname))
  $(VARIANT_PREFIX)UTs += $(_testexepathname)
  $(_testexepathname) : $(GTEST_LIBMARKER) $(_objpathname) $(_testobjpathname) \
              $(MK_DEPS) $(LIBSQLITE) $($(_testaddon))
	@echo $(_icon) $$(notdir $$@) \<= $$(notdir $(_objpathname) $(_testobjpathname))
	@-mkdir -p $$(dir $$@)
	@$(_cxx) $(_cxxflags) $(COMMON_CPPFLAGS) $(LOCAL_CPPFLAGS) $(VARIANT_CPPFLAGS) \
             -o $$@ $(_objpathname) $(_testobjpathname) \
             $(COMMON_LDFLAGS) $(LOCAL_UT_LDFLAGS) $(VARIANT_LDFLAGS)\
             $(OPT_COVERAGE_LDFLAGS) \
             -L$(OBJDIR) $(addprefix -l,$(GTEST_LIB) $(GTESTMAIN_LIB)) \
             $($(_testaddon))

  # define targets to run tests
  $(eval _xmltestreportname:="xml:$(_testexepathname).gtest_report.xml")
  .PHONY : run_$(_testexepathname)
  run_$(_testexepathname) : $(_testexepathname)
	@printf "\n_________\nExecuting $$<\n"
	@$$< --gtest_filter=-*Nightly*$(addprefix :,$(LOCAL_NIGHTLY_UT_PATTERNS)) \
         --gtest_output="xml:$(_testexepathname).gtest_report.xml"

  .PHONY : run_nightly_$(_testexepathname)
  run_nightly_$(_testexepathname) : $(_testexepathname)
	-@echo Executing nightly $$<
	-@$$< \
         --gtest_output=$(_xmltestreportname)

  .PHONY : run_disabled_$(_testexepathname)
  run_disabled_$(_testexepathname) : $(_testexepathname)
	-@printf "\n_________\nExecuting DISABLED tests from $$<\n"
	-@$$< --gtest_filter=*DISABLED* --gtest_also_run_disabled_tests \
         --gtest_output=$(_xmltestreportname)

  .PHONY : run_$(notdir $(_testexepathname))
  run_$(notdir $(_testexepathname)) : $(_testexepathname)
	-@printf "\n_________\nExecuting $$<\n"
	-@$$< --gtest_output=$(_xmltestreportname)

  .PHONY : run_$(2)_ut
  run_$(2)_ut : run_$(_testexepathname)

  .PHONY : show_$(_testexepathname)
  show_$(_testexepathname) : $(_testexepathname)
	-@printf "\n_________\nExecuting $$<\n"
	@$$< --gtest_list_tests

endef

mkutrule = $(eval $(call _mkutrule,$1,$2))



#-------------------------
# Helper function pushing variable's value to its stack
# arguments: $1 - name of the variable to be pushed
#            #2 - (generated) name of the variable representing the Nth stack entry
define _do_push
  $2:=$($1)
endef

#-------------------------
# Helper function pushing variable's value to the corresponding stack entry variable
# and adding latter one to the stack (the list of stack variable names)
# arguments: $1 name of the variable to be pushed to the stack
define _push
  ifeq ("$(_PUSHED_$1)","")
    _PUSHED_$1:=PuShEd_$1
  endif
  _PUSHED_$1:=$$(_PUSHED_$1).push
  $$(eval $$(call _do_push,$$1,$$(_PUSHED_$1)))
endef

#======================
# Keeps (pushes) variable's value to the stack
# arguments: $1 - name of the variable to be pushed
push = $(eval $(call _push,$1))

#-------------------------
# Helper function popping variable's value from the stack
# arguments: $1 - name of the variable to be restored
#            #2 - (generated) name of the variable representing the Nth stack entry
define _do_pop
  $1:=$($2)
endef

#-------------------------
# Helper function popping variable's value from the corresponding stack entry variable
# and removing latter one from the stack (the list of stack variable names)
# arguments: $1 name of the variable to be pushed to the stack
define _pop
  $$(eval $$(call _do_pop,$$1,$$(_PUSHED_$1)))
  _PUSHED_$1 := $$(basename $$(_PUSHED_$1))
endef

#======================
# Restores (pops) variable's value from the stack
# arguments: $1 - name of the variable to be popped
#TODO: Maybe add check for empty stack?
pop = $(eval $(call _pop,$1))


################################################################################
#----------------------
# Helper function reading the subsystem's makefile and generating dependencies
# and recipes for each listed source file
# arguments: $1 - Module name (used for obj. files names conflicts resolution)
#            $2 - submodule's makefile to be included
# uses: LOCAL_SRC_FILES LOCAL_INCLUDES LOCAL_CPPFLAGS LOCAL_CFLAGS
#       LOCAL_CXXFLAGS LOCAL_PATH LOCAL_SRC_FILES OBJDIR OBJEXT_SUFFIX
#       LOCAL_DEFINES COMMOM_CXXFLAGS COMMON_CFLAGS CC CXX
#
# TODO: Add check for duplicating object file names. fail make if detected
define _def-subsys

  # save parent's locals
  $(call push,LOCAL_DEFINES)
  $(call push,LOCAL_SRC_FILES)
  $(call push,LOCAL_INCLUDES)
  $(call push,LOCAL_CPPFLAGS)
  $(call push,LOCAL_CFLAGS)
  $(call push,LOCAL_CXXFLAGS)
  $(call push,LOCAL_PATH)
  $(call push,LOCAL_UT_FOR_SRC)
  $(call push,LOCAL_NIGHTLY_UT_PATTERNS)
  $(call push,MK_DEPS)
  $(call push,LOCAL_UT_LDFLAGS)

  LOCAL_UT_FOR_SRC:=
  LOCAL_NIGHTLY_UT_PATTERNS:=

  $(eval include $2/$(_SUBSYS_MAKE))
  MK_DEPS += $2/$(_SUBSYS_MAKE)

  # submodule directory is also should be included into the list of includes
  # TODO: Instead it would be better to cd to module's dir and do compilation from there
  $(eval LOCAL_INCLUDES += $2)

  $1.SUBSET.DIR:=$2
  SUBSETS+=$(VARIANT_PREFIX)$1.SUBSET
  .PHONY : $(VARIANT_PREFIX)$1.SUBSET $2
  $(VARIANT_PREFIX)$1.SUBSET : $(addprefix $(OBJDIR)/, $(addsuffix $(OBJEXT_SUFFIX), $(basename $(notdir $(LOCAL_SRC_FILES)))))
	@echo $(VARIANT_PREFIX)$1.SUBSET has been (re)made

  # Generate rule and recipe for each source file from the list
  $(foreach _srcfile, $(LOCAL_SRC_FILES), $(eval $(call mkobjrule,$(_srcfile),$1)))

  # Generate rules and recipes to build and run UT executables for each source file in the list
  $(foreach _srcfile, $(LOCAL_UT_FOR_SRC), $(eval $(call mkutrule,$(_srcfile),$1)))

  # restore parent's locals
  $(call pop,LOCAL_UT_LDFLAGS)
  $(call pop,MK_DEPS)
  $(call pop,LOCAL_NIGHTLY_UT_PATTERNS)
  $(call pop,LOCAL_UT_FOR_SRC)
  $(call pop,LOCAL_PATH)
  $(call pop,LOCAL_CXXFLAGS)
  $(call pop,LOCAL_CFLAGS)
  $(call pop,LOCAL_CPPFLAGS)
  $(call pop,LOCAL_INCLUDES)
  $(call pop,LOCAL_SRC_FILES)
  $(call pop,LOCAL_DEFINES)

endef

################################################################################
#----------------------
# Generates rules/recipes for source files listed in given submodule with given name
# arguments: $1 - Module name (TODO: eliminate it from the arguments - it's better to introduce it inside of included makefile)
#            $2 - submodule's makefile to be included
def-subsys = $(eval $(call _def-subsys,$(strip $1),$(strip $2)))


################################################################################
# From example at http://softwareswirl.blogspot.com/2009/10/gnu-make-trick-for-handling-long-lists.html
#-#------------------------------------------------------------------------------
# Macro for invoking a command on groups of 1000 words at a time
# (analogous to xargs(1)).  The macro invokes itself recursively
# until the list of words is depleted.
#
# Usage: $(call xargs,COMMAND,LIST)
#
# COMMAND should be a shell command to which the words will be
# appended as arguments in groups of 1000.
define xargs
  $(1) $(wordlist 1,50,$(2))
  $(if $(word 51,$(2)),$(call xargs,$(1),$(wordlist 51,$(words $(2)),$(2))))
endef


################################################################################
#----------------------
# Generates recipe to build static library from a bunch of object files
# Arguments:
#      $1 -- output library name
#      $2 -- space-separated list of object files
#
# NOTE: this is the default implementation.
#       It may be redefined for specific platforms in ptt-api-targets.mk
define create-static-library
  $(call xargs,$(AR) rsu $1 ,$2)
endef

################################################################################
#----------------------
# Merges two libraries into one.
# # Arguments:
# #      $1 -- first library name; also acts as an output library
# #      $2 -- second library name
# #
# # NOTE: this is the default implementation.
# #       It may be redefined for specific platforms in ptt-api-targets.mk
define merge-static-libraries
  mkdir -p $(dir $2)/tmp && \
  cd $(dir $2)/tmp && \
  rm -rf * && \
  $(AR) x $(2) && \
  $(AR) rsuv $(1) *.o
  rm -rf $(dir $2)/tmp
endef

###############################################################################
# intermediate function implementing codec list validation
define _validate-codecs
  $(eval _var:=$1)
  $(eval _codecs:=$2)
  $(eval _purpose:=$3)
  $(eval _comma_:= ,)
  $(eval _audio_codecs:=$(subst $(_comma_),:,$(_codecs)))
  $(eval _audio_codecs:=$(subst :, ,$(_audio_codecs)))
  $(eval _audio_codecs:=$(subst ;, ,$(_audio_codecs)))
  $(eval $(_var)=$(sort $(filter $(_KNOWN_AUDIO_CODECS),$(_audio_codecs))))
  $(eval _bad_$(_var)=$(sort $(filter-out $(_KNOWN_AUDIO_CODECS),$(subst :, ,$(_audio_codecs)))))
  ifneq ($(_bad_$(_var)),)
      $$(error Unknown audio codec(s) $(_bad_$(_var)) specified as $(_purpose))
  endif
endef

################################################################################
# Checks list of codecs for validity
# Arguments:
#  $1 -- final space-separated codec list variable name
#  $2 -- list of codecs to process
#  $3 -- codecs purpose messga to be used in error log message
# Uses:
#  KNOWN_AUDIO_CODECS to check codec validity
#
# Codecs can be separated by space, comma, colon or semicolon symbol.
# Repeated codecs names are acceptable.
# If list has unknown codec(s), make error will be raised on later stage.
# The main functionality is implemented in _validate-codecs that is evaluated.
define validate-codecs
  $(eval $(call _validate-codecs,$1,$2,$3))
endef
