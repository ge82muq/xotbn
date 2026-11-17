#define wmask_low_ffff      w29
#define wresult             w15
#define warg0               w10

#define wtmp0               w0

.equ w31, bn0

/*
 * Name:    internal_vadd
 *
 * Description: 
 * - adds together internal 16-bit entries of wide register
 * - result is reduced modulo MOD
 *   
 * Flags: Clobbers FG0
 *
 * @param[in]  warg0: WREG whose entries are added together   
 * @param[out] wresult: holds result in the lowest 16-bit
 * clobbered registers: {}, {w0,w10,w15,w29}
 */

.section .text
.global internal_vadd
internal_vadd:

    bn.add        wtmp0, bn0, warg0 >> 16
    bn.addvm.16H  warg0, wtmp0, warg0

    bn.add        wtmp0, bn0, warg0 >> 32
    bn.addvm.16H  warg0, wtmp0, warg0 

    bn.add        wtmp0, bn0, warg0 >> 64
    bn.addvm.16H  warg0, wtmp0, warg0 

    bn.add        wtmp0, bn0, warg0 >> 128
    bn.addvm.16H  warg0, wtmp0, warg0

    bn.and wresult, warg0, wmask_low_ffff

ret