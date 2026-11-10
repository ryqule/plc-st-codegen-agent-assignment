// Minimal ABI declarations for the STruC++ generated P02 translation.
// The verification runner keeps the generated function bodies unchanged and
// swaps only its C++ standard-library-heavy header for these field/type aliases.
typedef unsigned int IEC_DWORD;
typedef unsigned char IEC_USINT;
typedef int IEC_INT;
typedef bool IEC_BOOL;

inline IEC_DWORD SHL(IEC_DWORD value, IEC_INT shift) {
    return value << shift;
}

namespace strucpp {
class FB {
public:
    IEC_DWORD VALUE;
    IEC_BOOL HASCHANGED;
    IEC_BOOL HASRISINGEDGES;
    IEC_DWORD RISINGBITS;
    IEC_USINT NOOFRISINGBITS;
    IEC_BOOL HASFALLINGEDGES;
    IEC_DWORD FALLINGBITS;
    IEC_USINT NOOFFALLINGBITS;
    IEC_DWORD PREVVALUE;
    IEC_DWORD BITMASK;
    IEC_INT BITINDEX;
    IEC_BOOL ENO;
    FB();
    void operator()();
};
}
