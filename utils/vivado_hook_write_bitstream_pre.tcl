open_project ../../cleissom_work_xnorator_core_0.xpr
set saif_name "detailed_power.saif"

open_run synth_1

set_operating_conditions -process typical
set_units -power mW

# Runs a post implementation functional simulation with the memory initialized with SRAMInitFile.
# Feeds clock (100mhz) and reset switch and records switching activity for 3ms.
# set_property top xnorator [current_fileset sim_1]
# launch_simulation -mode post-synthesis -type functional
# open_saif "$saif_name"
# log_saif [get_objects -r *]
# add_force {/xnorator/clk_i} -radix bin {1 0ns} {0 7ns} -repeat_every 15ns
# add_force {/xnorator/rst_ni} -radix bin {1 0ns}
# add_force {/xnorator/cfg_input_width} -radix dec {50 0ns}
# add_force {/xnorator/cfg_input_height} -radix dec {50 0ns}
# add_force {/xnorator/cfg_input_channel} -radix dec {50 0ns}
# add_force {/xnorator/cfg_output_channel} -radix dec {50 0ns}
# add_force {/xnorator/start_i} -radix bin {1 0ns}
# run 1ms
# close_saif

# open_run synth_1


# read_saif "../../cleissom_work_xnorator_core_0.sim/sim_1/synth/func/xsim/$saif_name" 
# read_saif "../../cleissom_work_xnorator_core_0.sim/sim_1/synth/func/xsim/$saif_name"  -strip_path xnorator

# create_clock -name sys_clk_pin -period 15.00 -add [get_ports clk_i];

report_utilization -hierarchical -hierarchical_depth 2 -file hierarchical_utilization.log
report_power -name {detailed_power_report} -verbose -file power_result.log -hierarchical_depth 20
report_timing_summary -max_paths 10 -file timing_summary.log
report_clock_networks -file clock_networks.log