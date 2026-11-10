#ifndef P02_CBMC_STUB_HPP
#define P02_CBMC_STUB_HPP
typedef bool IEC_BOOL;
typedef unsigned int IEC_DWORD;
typedef unsigned char IEC_USINT;
namespace strucpp {
class FB_DUALWORDEDGEDETECTION {
public:
    // Inputs
    IEC_DWORD VALUE;
    // Outputs
    IEC_BOOL HASCHANGED;
    IEC_BOOL HASRISINGEDGES;
    IEC_DWORD RISINGBITS;
    IEC_USINT NOOFRISINGBITS;
    IEC_BOOL HASFALLINGEDGES;
    IEC_DWORD FALLINGBITS;
    IEC_USINT NOOFFALLINGBITS;
    // Local variables
    IEC_DWORD PREVVALUE;

    // Implicit IEC 61131-3 ENO pin (mirrors EN)
    IEC_BOOL ENO = true;

    // Constructor
    FB_DUALWORDEDGEDETECTION();

    // Execute function block
    void operator()();
};
IEC_USINT COUNTSETBITS(IEC_DWORD X);
}
#endif
