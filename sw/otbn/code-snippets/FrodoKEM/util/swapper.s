#define wmask_high_ffff     w28

#define wresult             w15
#define warg0               w10

#define wto_swap            w5
#define wtmp0               w0


.equ w31, bn0
.equ x2, t0
.equ x3, t1

/**
* Routine
* Description: swaps all 16-bit elements inside a WDR to LSB format
* [a|b|...|c|d] -> [d|c|...|b|a]
*
* @param[in]  warg0: WDR to be swapped
* @param[out] wresult: swapped register
* clobbered registers: {x2,x3}, {w0,w5,w10,w15,w28}
*/

# t0 <- ctr swaps
# t1 <- nr of swaps

.section .text 
.global swapper
swapper:

    bn.mov wto_swap, warg0

    add t0, x0, x0
    li  t1, 16

    swap:
        bn.and wtmp0, wto_swap, wmask_high_ffff
        bn.or  wtmp0, bn0, wtmp0 >> 240
        bn.or  wto_swap, bn0, wto_swap << 16
        
        bne x0, t0, shift_
        bn.mov wresult, wtmp0
        addi t0, t0, 1
        beq x0, x0, swap
        
        shift_:
            loop t0, 1
                bn.or wtmp0, bn0, wtmp0 << 16
            bn.or wresult, wresult, wtmp0
        addi t0, t0, 1
        bne t1, t0, swap

    ret