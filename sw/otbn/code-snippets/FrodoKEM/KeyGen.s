/*
* High Performance Implementation for Key Generation 
*
* @param[in]  xarg0: t_A parameter
* @param[in]  xarg1: security level - n
*
*/

/***
* GPR AND WDR CONVENTION 
* {x0,x1}   : zero and link register
* {x2-x4}   : tmp
* {x5-x9}   : subroutines
* {x10-x14} : args subroutines
* {x15}     : result
* {x16-x19} : subroutines / main routine
* {x20-x31} : main routine
* {w0-w4}   : wtmp
* {w5-w9}   : subroutines
* {w10-w14} : wargs subroutines
* {w15}     : wresult
* {w16-w19} : subroutines
* {w20-w31} : main routine
*
* Subroutines should state clobbered registers. [w]Tmp,x0,x1,args,results,gl.masks may be omitted. Its usage should be assumed by higher routines. 
* It is the responsibility of a subroutine to update xaddr_free that points to the next free space in memory. This ptr should only point at the boundary between data and "infinite" free space. If not updated, data is considered irrelevant and may be overwritten. 
***/

/* lengths in bytes */

#define LEN_A    16

/* aliases registers */

.equ w31, bn0
#define wones               w30
#define wmask_low_ffff      w29
#define wmask_high_ffff     w28
#define wseedA              w27
#define wctr_Agen           w26
#define wresult             w15

#define wtmp0               w0

#define xctr_Arows          x31
#define xFRODO_N            x30
#define xt_A                x29
#define xaddr_matrix_B      x28
#define xaddr_out_mult      x27
#define xaddr_matrix_A      x26
#define xaddr_buf_sampled   x25
#define idx_wresult         x24  

#define xaddr_pubkey        x22
#define xaddr_free          x21
#define xaddr_prndstr       x20

/* x16-x19 used by subroutines */

#define xresult         x15
#define xarg4           x14
#define xarg3           x13
#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

.equ x2, t0
.equ x3, t1
.equ x4, t2

.section .text
.global KeyGen
KeyGen:

    /***************************** 
    * Setup:
    * Parameters, constants, masks 
    *****************************/
    add xt_A, xarg0, x0 


    #if (FRODO_N == 640)
    li xFRODO_N, 640
    #elif (FRODO_N == 976)
    li xFRODO_N, 976
    #else
    li xFRODO_N, 1344
    #endif

    bn.xor  bn0, bn0, bn0
    bn.mov wctr_Agen, bn0

    li idx_wresult, 15

    /* Masks */
    bn.subi wones, bn0, 1            
    bn.or   wmask_low_ffff, bn0, wones >> 240   
    bn.or   wmask_high_ffff, bn0, wones << 240   

    /* Since for security levels n={976,1344} the modulo is 2^16, no modulo reduction is needed since all entries are automatically truncated to 16-bit */
    bn.wsrw MOD, bn0

    li t0, 640
    bne t0, xFRODO_N, skip_modulo_setup
    /* set modulo FRODO_Q in WDR MOD = 2^15 */
    bn.addi wtmp0, bn0, 1
    loopi 15, 1
        bn.add wtmp0, wtmp0, wtmp0 
    bn.wsrw MOD, wtmp0

    skip_modulo_setup:
    /***************************/

    /* Control */
    li  xctr_Arows, 0

    /* 
    * Generation of pseudorandom bit string  
    */
    la      xaddr_free, addr_free

    jal     x1, ctx_gen_prndstr

    add     xaddr_prndstr, xaddr_free, x0

    slli t0, xFRODO_N, 3 # n*nbar = n*8
    slli t0, t0, 2 # 4*n*nbar = 32*n*nbar / 8 bytes

    add     xarg0, t0, x0
    li      xarg1, 0
    add     xarg2, xaddr_prndstr, x0
    jal     x1, gen_prndstr 

    /* 
    * Sample matrides S_T, E 
    */
    add     xaddr_buf_sampled, xaddr_prndstr, x0

    slli    t0, xFRODO_N, 3 # n*nbar = n*8
    slli    t0, t0, 2 # 4*n*nbar = 32*n*nbar / 8 bytes
    add     xarg0, t0, x0
    jal     x1, wlen_equivalent

    add     xarg0, xaddr_prndstr, x0
    add     xarg1, xresult, x0 
    add     xarg2, xaddr_buf_sampled, x0
    jal     x1, inverse_sampler

    /* Generate seed_A */

    jal     x1, gen_seedA

    /******* B = AS *******/
    add     xaddr_matrix_B, xaddr_free, x0

    add     xaddr_out_mult, xaddr_matrix_B, x0

    /* reserve space for B */
    slli    t0, xFRODO_N, 4 # n*nbar*2 = n*8*2 = LEN_MATRIX_B bytes
    add     xaddr_free, xaddr_free, t0
    /*---------------------*/

    add     xaddr_matrix_A, xaddr_free, x0

    multiply_on_the_fly:
        
        add xarg0, xt_A, x0
        add xarg1, xaddr_matrix_A, x0    
        jal x1, genA

        add xarg0, xaddr_matrix_A, x0
        add xarg1, xt_A, x0
        add xarg2, xFRODO_N, x0
        add xarg3, xaddr_buf_sampled, x0
        add xarg4, xaddr_out_mult, x0
        jal x1, matrix_matrix_mult # A[:t_A]*S

        /* increase output address mult */
        loop xt_A, 1
            addi xaddr_out_mult, xaddr_out_mult, 16 # FRODO_NBAR*2 bytes per B[row]

        /* free used space from A */
        add xaddr_free, xaddr_matrix_A, x0
        
        add xctr_Arows, xctr_Arows, xt_A
        bne xFRODO_N, xctr_Arows, multiply_on_the_fly

    /***********************/

    /******* B = B + E *******/
    slli    t0, xFRODO_N, 4 # n*nbar*2 = n*8*2
    add     xarg0, t0, x0
    jal     x1, wlen_equivalent
    add     xarg2, xresult, x0

    add     xarg0, xaddr_matrix_B, x0

    slli    t0, xFRODO_N, 3 # n*nbar = n*8
    slli    t0, t0, 2 # 4*n*nbar = 32*n*nbar / 8 bytes
    srli    t0, t0, 1 # 4*n*nbar/2
    add     xarg1, xaddr_buf_sampled, t0 # offset to matrix E

    jal     x1, matrix_matrix_add

    /* Pack matrix B in-place */
    slli    xarg0, xFRODO_N, 4 # n*nbar*2 = n*8*2 = LEN_MATRIX_B bytes
    add     xarg1, xaddr_matrix_B, x0
    add     xarg2, xaddr_matrix_B, x0
    jal     x1, pack

    /**** Construct pubkey = seedA || b ****/

    add xaddr_pubkey, xaddr_matrix_B, x0

    add t0, xaddr_pubkey, x0    

    bn.or wresult, bn0, wseedA << 128

    bn.lid x0, 0(t0) # wtmp0 <= b[:256]

    slli    t1, xFRODO_N, 4 # n*nbar*2 = n*8*2 = LEN_MATRIX_B bytes
    li      t2, 640
    bne     t2, xFRODO_N, skip_size_reduction
    sub     t1, t1, xFRODO_N # size of compressed matrix
    skip_size_reduction:
    srli    t1, t1, 5 # size of compressed matrix in blocks of WLEN
    loop t1, 5 
        bn.rshi wresult, wtmp0, wresult >> 128
        bn.sid idx_wresult, 0(t0++)
        bn.or wtmp0, bn0, wtmp0 >> 128
        bn.or wresult, bn0, wtmp0 << 128
        bn.lid x0, 0(t0)
    bn.or wresult, bn0, wresult >> 128
    bn.sid idx_wresult, 0(t0++)

    /**** Hash pubkey = seedA || b ****/
    li      t0, LEN_A
    slli    t1, t1, 5 # back to bytes
    add     xarg0, t0, t1
    add     xarg1, xaddr_pubkey, x0
    li      xarg2, 1 # uses SHAKE256 if higher seclev
    jal     x1, ctx_shake

    li      xarg0, 1
    li      xarg1, 0
    la      xarg2, pkh
    jal     x1, squeeze_shake

ret

