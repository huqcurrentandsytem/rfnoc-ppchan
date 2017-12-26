include $(RFNOC_PPCHAN_DIR)/ip/channelizer_c_counter_binary_v12_0_i0/Makefile.inc
include $(RFNOC_PPCHAN_DIR)/ip/channelizer_c_counter_binary_v12_0_i1/Makefile.inc
include $(RFNOC_PPCHAN_DIR)/ip/channelizer_fir_compiler_v7_2_i0/Makefile.inc
include $(RFNOC_PPCHAN_DIR)/ip/channelizer_xfft_v9_0_i0/Makefile.inc


LIB_IP_XCI_SRCS += $(abspath \
$(A1_SRCS) \
$(A2_SRCS) \
$(A3_SRCS) \
$(A4_SRCS) \
)

LIB_IP_SYNTH_OUTPUTS = += $(abspath \
$(A1_OUTS) \
$(A2_OUTS) \
$(A3_OUTS) \
$(A4_OUTS) \
)


