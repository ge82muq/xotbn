

FRODOKEM_BAZEL_PATH = "//sw/otbn/code-snippets/FrodoKEM"

load("//rules:otbn.bzl", "otbn_binary")

package(default_visibility = ["//visibility:public"])

otbn_binary(
    name = "test_Decaps",
    srcs = ["test_Decaps.s",
        FRODOKEM_BAZEL_PATH + ":Decaps.s",
        FRODOKEM_BAZEL_PATH + ":shake.s",
        FRODOKEM_BAZEL_PATH + ":inverse_sampler.s",
        FRODOKEM_BAZEL_PATH + ":genA.s",
        FRODOKEM_BAZEL_PATH + ":mult_SA.s",
        FRODOKEM_BAZEL_PATH + ":mult_SB.s",
        FRODOKEM_BAZEL_PATH + ":pack.s",
        FRODOKEM_BAZEL_PATH + ":unpack.s",
        FRODOKEM_BAZEL_PATH + ":encode.s",
        FRODOKEM_BAZEL_PATH + ":decode.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_add.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:vector_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:scalar_prod.s",
        FRODOKEM_BAZEL_PATH + "/util:internal_vadd.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_Decaps.s",],
)

otbn_binary(
    name = "test_Encaps",
    srcs = ["test_Encaps.s",
        FRODOKEM_BAZEL_PATH + ":Encaps.s",
        FRODOKEM_BAZEL_PATH + ":shake.s",
        FRODOKEM_BAZEL_PATH + ":inverse_sampler.s",
        FRODOKEM_BAZEL_PATH + ":genA.s",
        FRODOKEM_BAZEL_PATH + ":mult_SA.s",
        FRODOKEM_BAZEL_PATH + ":mult_SB.s",
        FRODOKEM_BAZEL_PATH + ":pack.s",
        FRODOKEM_BAZEL_PATH + ":unpack.s",
        FRODOKEM_BAZEL_PATH + ":encode.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_add.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:vector_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:scalar_prod.s",
        FRODOKEM_BAZEL_PATH + "/util:internal_vadd.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_Encaps.s",],
)

otbn_binary(
    name = "test_KeyGen",
    srcs = ["test_KeyGen.s",
        FRODOKEM_BAZEL_PATH + ":KeyGen.s",
        FRODOKEM_BAZEL_PATH + ":gen_seedA.s",
        FRODOKEM_BAZEL_PATH + ":genA.s",
        FRODOKEM_BAZEL_PATH + ":shake.s",
        FRODOKEM_BAZEL_PATH + ":gen_prndstr.s",
        FRODOKEM_BAZEL_PATH + ":inverse_sampler.s",
        FRODOKEM_BAZEL_PATH + ":pack.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_KeyGen.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_add.s",
        FRODOKEM_BAZEL_PATH + "/util:vector_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:scalar_prod.s",
        FRODOKEM_BAZEL_PATH + "/util:internal_vadd.s",
        FRODOKEM_BAZEL_PATH + "/util:swapper.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",],
)

otbn_binary(
    name = "test_target_op",
    srcs = ["test_target_op.s",
        FRODOKEM_BAZEL_PATH + ":target_op.s",
        FRODOKEM_BAZEL_PATH + ":gen_seedA.s",
        FRODOKEM_BAZEL_PATH + ":genA.s",
        FRODOKEM_BAZEL_PATH + ":shake128.s",
        FRODOKEM_BAZEL_PATH + ":gen_prndstr.s",
        FRODOKEM_BAZEL_PATH + ":inverse_sampler.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_target_op.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:matrix_matrix_add.s",
        FRODOKEM_BAZEL_PATH + "/util:vector_matrix_mult.s",
        FRODOKEM_BAZEL_PATH + "/util:scalar_prod.s",
        FRODOKEM_BAZEL_PATH + "/util:internal_vadd.s",
        FRODOKEM_BAZEL_PATH + "/util:swapper.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",],
)


otbn_binary(
    name = "test_gen_seedA",
    srcs = ["test_gen_seedA.s",
        FRODOKEM_BAZEL_PATH + ":gen_seedA.s",
        FRODOKEM_BAZEL_PATH + ":shake128.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_gen_seedA.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",],
)


otbn_binary(
    name = "test_gen_prndstr",
    srcs = [
        "test_gen_prndstr.s",
        FRODOKEM_BAZEL_PATH + ":gen_prndstr.s",
        FRODOKEM_BAZEL_PATH + ":shake128.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_gen_prndstr.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",
    ],
)

otbn_binary(
    name = "test_inverse_sampler",
    srcs = [
        "test_inverse_sampler.s",
        FRODOKEM_BAZEL_PATH + ":inverse_sampler.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_inverse_sampler.s",
    ],
)

otbn_binary(
    name = "test_pack",
    srcs = [
        "test_pack.s",
        FRODOKEM_BAZEL_PATH + ":pack.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_pack.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",
    ],
)

otbn_binary(
    name = "test_unpack",
    srcs = [
        "test_unpack.s",
        FRODOKEM_BAZEL_PATH + ":unpack.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_unpack.s",
        FRODOKEM_BAZEL_PATH + "/util:wlen_equivalent.s",
    ],
)

otbn_binary(
    name = "test_encode",
    srcs = [
        "test_encode.s",
        FRODOKEM_BAZEL_PATH + ":encode.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_encode.s",
    ],
)

otbn_binary(
    name = "test_decode",
    srcs = [
        "test_decode.s",
        FRODOKEM_BAZEL_PATH + ":decode.s",
        FRODOKEM_BAZEL_PATH + "/data-auto:data_decode.s",
    ],
)


