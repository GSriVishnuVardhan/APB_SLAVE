# GTKWave helper — load FST and add APB signals (Verilator hierarchy)
gtkwave::loadFile apb_wave.fst
gtkwave::addSignalsFromList {
    tb_apb_wave.vif.pclk
    tb_apb_wave.vif.rst_n
    tb_apb_wave.vif.psel
    tb_apb_wave.vif.penable
    tb_apb_wave.vif.pwrite
    tb_apb_wave.vif.paddr
    tb_apb_wave.vif.pwdata
    tb_apb_wave.vif.prdata
    tb_apb_wave.vif.pready
    tb_apb_wave.vif.pslverr
    tb_apb_wave.dut.num_wait_cycles
}
