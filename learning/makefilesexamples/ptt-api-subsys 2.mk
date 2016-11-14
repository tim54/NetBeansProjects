LOCAL_PATH := $(call my-dir)

LOCAL_SRC_FILES := CallImpl.cpp                                      \
                   BargeCallSM.cpp                                   \
                   ChatCallSM.cpp                                    \
                   BaseCallState.cpp                                 \
                   CStateENDED.cpp                                   \
                   CStateINIT.cpp                                    \
                   CStateLISTENING.cpp                               \
                   CStateOPEN.cpp                                    \
                   CStateOPEN_GRANTED.cpp                            \
                   CStateTALKING.cpp                                 \
                   CStateWAITING_200_OK.cpp                          \
                   CStateWAITING_TRYING.cpp                          \
                   CStateWAITING_UNSOLICITED_FLOOR_GRANT.cpp         \
                   CStateWAITING_AUDIO_RECORDER_START.cpp            \
                   CStateWAITING_AUDIO_PLAYER_START.cpp              \
                   SicTimerHandler.cpp                               \
                   AlertCallImpl.cpp                                 \
                   AlertCallSM.cpp                                   \
                   CAlertStateINIT.cpp                               \
                   CStateWAITING_RINGING.cpp                         \
                   CStateWAITING_FOR_ANSWER.cpp                      \
                   #

LOCAL_UT_FOR_SRC := SicTimerHandler.cpp                              \
                    CallImpl.cpp                                     \
                    AlertCallImpl.cpp                                \
                    BaseCallState.cpp                                \
                    CStateINIT.cpp                                   \
                    CStateOPEN.cpp                                   \
                    CStateOPEN_GRANTED.cpp                           \
                    CStateLISTENING.cpp                              \
                    CStateTALKING.cpp                                \
                    CStateWAITING_200_OK.cpp                         \
                    CStateWAITING_TRYING.cpp                         \
                    CStateWAITING_UNSOLICITED_FLOOR_GRANT.cpp        \
                    CStateWAITING_AUDIO_RECORDER_START.cpp           \
                    CStateWAITING_AUDIO_PLAYER_START.cpp             \
                    CStateENDED.cpp                                  \
                    CAlertStateINIT.cpp                              \
                    CStateWAITING_FOR_ANSWER.cpp                     \
                    CStateWAITING_RINGING.cpp                        \
                    #

LOCAL_INCLUDES :=                                                 \
    $(LOCAL_PATH)/../include                                      \
    $(LOCAL_PATH)/../../fsm/include                               \
    $(LOCAL_PATH)/../../ptt-event/include                         \
    $(LOCAL_PATH)/../../ptt-ua-controller/include                 \
    $(LOCAL_PATH)/../../ptt-stack-adapter/include                 \
    $(LOCAL_PATH)/../../common/include                            \
    $(LOCAL_PATH)/../../ptt-timer/include                         \
    $(LOCAL_PATH)/../../../api/include                            \
    $(LOCAL_PATH)/../../../api-impl/include                       \
    $(LOCAL_PATH)/../../../audio_xface/include                    \
    $(LOCAL_PATH)/../../contacts-manager/include
    #
