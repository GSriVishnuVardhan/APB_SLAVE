// Custom Verilator main — opens FST trace for GTKWave (used by run_wave.sh).
#include "verilated.h"
#include "Vtb_apb_wave.h"
#include "verilated_fst_c.h"

vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv, char**) {
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->traceEverOn(true);
    contextp->threads(1);
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vtb_apb_wave> topp{new Vtb_apb_wave{contextp.get()}};

    VerilatedFstC tfp;
    topp->trace(&tfp, 99);
    tfp.open("apb_wave.fst");

    while (VL_LIKELY(!contextp->gotFinish())) {
        topp->eval();
        if (!topp->eventsPending())
            break;
        contextp->time(topp->nextTimeSlot());
        main_time = contextp->time();
        tfp.dump(main_time);
    }

    topp->final();
    tfp.close();
    return 0;
}
