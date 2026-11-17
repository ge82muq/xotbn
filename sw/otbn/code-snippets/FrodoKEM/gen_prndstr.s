
.equ w31, bn0

#define xFRODO_N          x30
#define xaddr_free          x21


#define xresult         x15

#define xarg2           x12
#define xarg1           x11
#define xarg0           x10

#define xlen_msg            x7
#define xwlen_digest         x6
#define xaddr_msg_shake      x5

#define wseedSE_1       w7
#define wseedSE_0       w6
#define wCONST_5F       w5

#define wtmp2           w2
#define wtmp1           w1
#define wtmp0           w0

.equ x2, t0
.equ x3, t1

/*
 * Name:    gen_prnd_str
 *
 * Description: generates pseudorandom bit string.
 *
 */


/**
* This subroutine sends the KMAC the msg to be absorbed by SHAKE.
*
* clobbered registers: {x5,x6},{}
* clobbered registers subroutines: {},{}
*
*/
.section .text
.global ctx_gen_prndstr
ctx_gen_prndstr:

    bn.addi  wCONST_5F, bn0, 0x5F      

    li t0, 640
    bne t0, xFRODO_N, seclev_plus

    la      t0, seed_SE
    bn.lid  x0, 0(t0)
    bn.mov wseedSE_0, wtmp0               

    /* Concatenates input string as [w2]||w1||w0 = [seed_SE || 0x5F] which represents DMEM: 0x5F||seed_SE */

    bn.or  wtmp0, bn0, wseedSE_0 << 8
    bn.or  wtmp0, wtmp0, wCONST_5F         # w0 <= [seed_SE[30:0] || 0x5F]
    bn.rshi  wtmp1, bn0, wseedSE_0 >> 248      # w1 <= [00..00 || seed_SE[31]]

    /* Stores input string w1||w0 to be digested */

    bn.sid  x0, 0(xaddr_free++)
    li      t0, 1
    bn.sid  t0, 0(xaddr_free++)

    li t0, 64
    sub xaddr_msg_shake, xaddr_free, t0
    sub xaddr_free, xaddr_free, t0 # at this point is not free but it will be consumed subsequently by shake

    li xlen_msg, 33

    jal x0, set_ctx_shake

    seclev_plus: # n=976,1344
    la      t0, seed_SE

    bn.lid  x0, 0(t0++) # w0 <= seed_SE[:32]
    bn.mov wseedSE_0, wtmp0

    bn.lid x0, 0(t0) # w0 <= seed_SE[32:64]
    bn.mov wseedSE_1, wtmp0

    bn.or  wtmp0, bn0, wseedSE_0 << 8
    bn.or  wtmp0, wtmp0, wCONST_5F         # w0 <= [seed_SE_0[30:0] || 0x5F]
    bn.rshi  wtmp1, wseedSE_1, wseedSE_0 >> 248      # w1 <= [seed_SE_1[30:0] || seed_SE_0[31]]

    /* Stores input string w1||w0 to be digested */

    bn.sid  x0, 0(xaddr_free++)
    li      t0, 1
    bn.sid  t0, 0(xaddr_free++)

    li xlen_msg, 49

    li t0, 1344
    bne t0, xFRODO_N, free_addr

    bn.rshi  wtmp0, bn0, wseedSE_1 >> 248      # w0 <= [00..00 || seed_SE_1[31]]
    bn.sid x0, 0(xaddr_free++)

    li t0, 96
    sub xaddr_msg_shake, xaddr_free, t0
    sub xaddr_free, xaddr_free, t0 # at this point is not free but it will be consumed subsequently by shake

    li xlen_msg, 65
    
    jal x0, set_ctx_shake

    free_addr:
    li t0, 64
    sub xaddr_msg_shake, xaddr_free, t0
    sub xaddr_free, xaddr_free, t0 # at this point is not free but it will be consumed subsequently by shake

    /* initializes shake context */
    set_ctx_shake:

    add xarg0, xlen_msg, x0
    add xarg1, xaddr_msg_shake, x0
    li  xarg2, 1 # uses SHAKE256
    jal x1, ctx_shake
    
    ret

/**
* This subroutine generates the pseudorandom bit string. It ignores the first [xarg1] bytes from the digest.
* @param[in]  xarg0: length of pseudorandom bit string - bytes
* @param[in]  xarg1: offset digest - bytes
* @param[out] xarg2: ptr to output buffer
* clobbered registers: {}
* clobbered registers subroutines: {x16}
*/
.global gen_prndstr
gen_prndstr: 

    /* Computes nr of WLEN chunks to extract */
    add xarg0, xarg0, x0
    jal x1, wlen_equivalent
    add xwlen_digest, xresult, x0

    /* Shakes out prnd string */
    add xarg0, xwlen_digest, x0
    add xarg1, xarg1, x0 # formality to hold args calling convention
    add xarg2, xarg2, x0 # formality to hold args calling convention
    jal x1, squeeze_shake

    ret




