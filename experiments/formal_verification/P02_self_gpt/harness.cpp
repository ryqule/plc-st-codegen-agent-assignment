#include "P02_cbmc_stub.hpp"
// CBMC harness for an STruC++ translation of a generated P02 function block.
// The ST source is translated separately; this harness checks two arbitrary
// consecutive 32-bit transitions against the P02 edge/count specification.
extern "C" unsigned int __CPROVER_nondet_uint(void);
extern "C" void __CPROVER_assert(bool condition, const char *description);
#define assert(condition) __CPROVER_assert((condition), #condition)

static unsigned int popcount32(unsigned int value) {
    unsigned int count = 0;
    for (unsigned int bit = 0; bit < 32; ++bit) {
        count += (value >> bit) & 1U;
    }
    return count;
}

static void check_transition(strucpp::FB &fb, unsigned int previous,
                             unsigned int current) {
    fb.VALUE = static_cast<IEC_DWORD>(current);
    fb();

    const unsigned int rising = current & ~previous;
    const unsigned int falling = previous & ~current;
    assert(fb.RISINGBITS == rising);
    assert(fb.FALLINGBITS == falling);
    assert(fb.HASCHANGED == (current != previous));
    assert(fb.HASRISINGEDGES == (rising != 0U));
    assert(fb.HASFALLINGEDGES == (falling != 0U));
    assert(fb.NOOFRISINGBITS == popcount32(rising));
    assert(fb.NOOFFALLINGBITS == popcount32(falling));
    assert(fb.PREVVALUE == current);
}

int main() {
    strucpp::FB fb;
    const unsigned int first_previous = __CPROVER_nondet_uint();
    const unsigned int first_current = __CPROVER_nondet_uint();
    fb.PREVVALUE = static_cast<IEC_DWORD>(first_previous);
    check_transition(fb, first_previous, first_current);

    const unsigned int second_current = __CPROVER_nondet_uint();
    check_transition(fb, first_current, second_current);
    return 0;
}
