#!/bin/env python3

from random import randint

# params to specify
iw = 7
ih = iw
ic = 512
oc = ic
padding = False
c_header_file = "sw/common/test-data.h"
input_mem_file = "input.vmem"
weight_mem_file = "weights.vmem"

# constants
ks = 3

# util functions


def int2hex(number, bits):
    """ Return the 2'complement hexadecimal representation of a number """
    if number < 0:
        return hex((1 << bits) + number)
    else:
        return hex(number)


ow = iw if padding else iw-2
oh = ih if padding else ih-2

input_size = iw*ih*int(ic/32)
weight_size = ks*ks*int(ic/32)*oc
output_size = ow*oh*int(oc/2)


def gen_c_array_text(name, str_array):
    data = []
    data.append(f'uint32_t {name}[] = {{')
    data += [(f"0x{str}" + ", ") for str in str_array]
    data.append('};\n')
    return '\n'.join(data)


def gen_c_empty_array_text(name, size):
    data = []
    data.append(f'uint32_t {name}[{size}] = {{}};')
    data.append(f'uint32_t output_size = {size};\n')
    return '\n'.join(data)


input_array_str = [f"{randint(0, 2**32-1):08X}" for x in range(0, input_size)]
weight_array_str = [f"{randint(0, 2**32-1):08X}"
                    for x in range(0, weight_size)]

with open(c_header_file, 'w') as f:
    input_text = gen_c_array_text("input", input_array_str)
    weight_text = gen_c_array_text("weights", weight_array_str)
    output_text = gen_c_empty_array_text("output", output_size)
    file_text = input_text + weight_text + output_text
    f.write(file_text)

with open(input_mem_file, 'w') as f:
    f.write('\n'.join(input_array_str) + '\n')
with open(weight_mem_file, 'w') as f:
    f.write('\n'.join(weight_array_str) + '\n')
