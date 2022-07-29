#!/bin/env python3

import numpy as np

# params to specify
iw = 7
ih = iw
ic = 64
oc = 64
padding = False
input_mem_file = "input.vmem"
weight_mem_file = "weights.vmem"
output_mem_file = "output-script.vmem"

# constants
ks = 3


# util functions
def hex2int(i):
    return int(i, 16)


def popcount(i):
    return sum(b == '1' for b in i)


def normalize(i):
    return (i*2) - 32


def int2hex16b(number):
    """ Return the 2'complement hexadecimal representation of a number """
    if number < 0:
        return f'{(1 << 16) + number:04X}'
    else:
        return f'{number:04X}'


hex2int_vec = np.vectorize(hex2int)
popcount_vec = np.vectorize(popcount)
normalize_vec = np.vectorize(normalize)
bin_repr_vec = np.vectorize(lambda x: np.binary_repr(
    x, width=32)[-32:])  # enforce width
hex_and_merge_str_vec = np.vectorize(lambda a, b: int2hex16b(a)+int2hex16b(b))


def binconv(a, b):
    x = np.bitwise_xor(hex2int_vec(a), hex2int_vec(b))
    y = np.bitwise_not(x)
    z = bin_repr_vec(y)
    return normalize_vec(popcount_vec(z)).sum()


input = []
with open(input_mem_file) as f:
    input = [line[:-1] for line in f.readlines()]

weight = []
with open(weight_mem_file) as f:
    weight = [line[:-1] for line in f.readlines()]

input_matrix = np.reshape(
    input[:iw*ih*int(ic/32)], (iw, ih, int(ic/32)), order='F')
weight_matrix = np.reshape(
    weight[:ks*ks*int(ic/32)*oc], (ks, ks, int(ic/32), oc), order='F')


if padding:
    oh = ih
    ow = iw

    vertical_fill = np.array(
        ["0" for i in range(0, (iw+2)*int(ic/32))]).reshape((iw+2, 1, int(ic/32)))
    horizontal_fill = np.array(
        ["0" for i in range(0, ih*int(ic/32))]).reshape((1, ih, int(ic/32)))
    hpadded_matrix = np.concatenate(
        (horizontal_fill, input_matrix, horizontal_fill), axis=0)
    padded_matrix = np.concatenate(
        (vertical_fill, hpadded_matrix, vertical_fill), axis=1)
    input_matrix = padded_matrix
else:
    oh = ih-2
    ow = iw-2


out = []
for n in range(0, oc):
    for j in range(0, oh):
        for i in range(0, ow):
            out.append(
                binconv(input_matrix[i:i+ks, j:j+ks, :], weight_matrix[:, :, :, n]))

out_matrix = np.reshape(out, (ow, oh, oc),  order='F')

output_array_hex = hex_and_merge_str_vec(
    out_matrix[:, :,  1::2], out_matrix[:, :,  0::2])

with open(output_mem_file, 'w') as f:
    f.write('\n'.join(output_array_hex.reshape(-1, order='F')) + '\n')
