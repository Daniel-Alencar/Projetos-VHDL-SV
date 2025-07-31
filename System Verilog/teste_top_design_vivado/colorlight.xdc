# System clock (xtal 25 MHz)
set_property -dict {PACKAGE_PIN K4 IOSTANDARD LVCMOS33} [get_ports dev_clk]; #IO_L13P_T2_MRCC_35    xtal_25_MHz

# Board LED D2
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports led]; #IO_L17P_T2_16    LED_D2

# UART
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports tx]; #IO_L3P_T0_DQS_34   P5_16
set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports rx]; #IO_L16P_T2_35      P5_15