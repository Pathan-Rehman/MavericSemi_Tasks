# alu3_pipeline timing constraints - 100 MHz target (shared by STA and the PD flow)
create_clock -name clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.1 [get_clocks clk]
set_clock_transition  0.1 [get_clocks clk]

set_input_delay  -clock clk -max 1.0 [get_ports {a b op valid_in}]
set_input_delay  -clock clk -min 0.2 [get_ports {a b op valid_in}]
set_input_delay  -clock clk -max 0.5 [get_ports rst_n]
set_input_delay  -clock clk -min 0.5 [get_ports rst_n]

set_output_delay -clock clk -max 1.0 [get_ports {result valid_out}]
set_output_delay -clock clk -min 0.2 [get_ports {result valid_out}]
