## System clock (xtal 25 MHz)

# IO_L13P_T2_MRCC_35 - xtal_25_MHz

set_property -dict {PACKAGE_PIN K4 IOSTANDARD LVCMOS33} [get_ports pixclk];

#create_clock -name dev_clk -period 40.000 [get_ports dev_clk]





# HDMI

#IO_L11N_T1_SRCC_34 - HCK_N

set_property -dict {PACKAGE_PIN AA4 IOSTANDARD LVCMOS33} [get_ports TMDSn_clock];

#IO_L10N_T1_34 - HCK_P

set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS33} [get_ports TMDSp_clock];

#IO_L10P_T1_34 - HD0_N

set_property -dict {PACKAGE_PIN AA5 IOSTANDARD LVCMOS33} [get_ports TMDSn[0]];

#IO_L20N_T3_34 - HD0_P

set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS33} [get_ports TMDSp[0]];

#IO_L23N_T3_34 - HD1_N

set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS33} [get_ports TMDSn[1]];

#IO_L20P_T3_34 - HD1_P

set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS33} [get_ports TMDSp[1]];

#IO_L23P_T3_34 - HD2_N

set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS33} [get_ports TMDSn[2]];

#IO_L19N_T3_VREF_34 - HD2_P

set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports TMDSp[2]];