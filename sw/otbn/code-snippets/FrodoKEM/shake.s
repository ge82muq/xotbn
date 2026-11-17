/* KMAC STATUS */
# Bit 0: Done
# Bit 1: Ready
# Bit 2: Error

/* KMAC CFG */
# Bit 0 - 1:  SHA3 Mode:
#  'b00: SHA3
#  'b10: Shake
#  'b11: CShake
# Bit 2 - 4:  Keccak Strength:
#  'b000: L128
#  'b001: L224
#  'b010: L256
#  'b011: L384
#  'b100: L512
# Bit 5 - 7:  Message Length Bytes 
# Bit 8 - 15: Message Length in 64-bit words


/* Index of the Keccak command special register. */
#define KECCAK_CFG_REG    0x7d9
#define KECCAK_DIGEST_REG 0xA
#define KECCAK_MSG_REG    0x9
/* Config to start a SHAKE-128 operation. */
#define SHAKE_CFG      0x2
#define SHAKE128_STRENGTH       0x0
#define SHAKE256_STRENGTH       0x2

.equ x2, t0
.equ x3, t1
.equ x4, t2

#define xaddr_free        x21

/* we avoid using low registers because this subroutine is called the most by other subroutines */
#define xctr_offset       x16

#define xarg2             x12
#define xarg1             x11
#define xarg0             x10

#define wtmp0             w0

/*
 * Name:    shake
 *
 * Description: This function performs a SHAKE-{128,256} operation using the KMAC unit.
 *
 * Flags: Clobbers FG0
 *
 * 
 */


.section .text

/**
* This routine fills the KMAC_MSG register with the message
* @param[in]  xarg0: message length (bytes)
* @param[in]  xarg1: ptr message
* @param[in]  xarg2: flag for generation of matrix A. Values: 0: genA, 1: else
*
* clobbered registers: {},{}
*/
.global ctx_shake
ctx_shake:

#if (FRODO_N == 640)
li t0, SHAKE128_STRENGTH
#else
li t0, SHAKE256_STRENGTH
#endif

/* force SHAKE128 for generating matrix A */
bne x0, xarg2, set_keccak_cfg_reg
li t0, SHAKE128_STRENGTH

set_keccak_cfg_reg:

slli t0, t0, 2
li   t1, SHAKE_CFG
or   t0, t0, t1
slli t1, xarg0, 5
or   t0, t0, t1

csrrw x0, KECCAK_CFG_REG, t0

# Calculate nr. of WLEN writes to KMAC MSG reg
srli t2, xarg0, 5
andi t0, xarg0, 0x1F
beq  t0, x0, skip_additional_kmac_msg_write
addi t2, t2, 1 # number of WLEN writes to KMAC MSG reg

skip_additional_kmac_msg_write:
slli t2, t2, 5 # nr of writes set back to bytes

li t1, 0 # bytes written
write_to_kmac_msg:
    bn.lid x0, 0(xarg1++)
    bn.wsrw KECCAK_MSG_REG, wtmp0 # Write to KMAC MSG reg => FIFO starts
    addi t1, t1, 32
    bne t2, t1, write_to_kmac_msg

ret

/**
* This routine squeezes out [xarg0] WLEN data and ignores [xarg1] bytes of the digest before storing at [xarg2]. The [xarg1] bytes to ignore should be a multiple of 32.
* @param[in]  xarg0: nr of WLEN chunks to digest 
* @param[in]  xarg1: offset digest - bytes
* @param[out] xarg2: ptr to output buffer
*
* clobbered registers: {x16,x21},{}
*/
.global squeeze_shake
squeeze_shake:

add xctr_offset, x0, x0
li  t2, 1
# Read KMAC DIGEST as many times as required
loop xarg0, 6 
    bn.wsrr wtmp0, KECCAK_DIGEST_REG
    addi    xctr_offset, xctr_offset, 32
    sub     t1, xarg1, xctr_offset
    srli    t1, t1, 31 # MSb
    beq     t2, t1, store_digest
    branch_back:
    nop
ret

store_digest: 
    bn.sid  x0, 0(xarg2++)
    addi    xaddr_free, xaddr_free, 32
    jal     x0, branch_back



