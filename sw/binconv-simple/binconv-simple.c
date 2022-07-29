#include <stdint.h>

#include "../common/test-data.h"
#include "simple_system_common.h"

uint32_t w_in = 7;
uint32_t h_in = 7;
uint32_t c_in = 512;
uint32_t c_out = 512;
uint32_t ks = 3;

static inline uint32_t __popcount(uint32_t a) {
  uint32_t x = a;
  x = x - ((x >> 1) & 0x55555555);
  x = ((x >> 2) & 0x33333333) + (x & 0x33333333);
  x = (x + (x >> 4)) & 0x0F0F0F0F;
  x = (x + (x >> 16));
  return (x + (x >> 8)) & 0x0000003F;
}

int main(int argc, char **argv) {
  uint32_t index_o, index_w, index_i, popcount_res;
  uint32_t w_out = w_in - 2;
  uint32_t h_out = h_in - 2;
  uint32_t ic_len = w_in * h_in;
  uint32_t wc_len = ks * ks;
  uint32_t w_len = wc_len * c_out;
  uint32_t oc_len = (w_in - 2) * (h_in - 2);

  for (uint32_t j = 0; j < h_out; j++) {
    for (uint32_t i = 0; i < w_out; i++) {
      for (uint32_t oc = 0; oc < c_out; oc++) {
        for (uint32_t ic = 0; ic < c_in / 32; ic++) {
          for (uint32_t wj = 0; wj < ks; wj++) {
            for (uint32_t wi = 0; wi < ks; wi++) {
              index_i = (ic * ic_len) + (j * w_in) + (i + wi);
              index_o =
                  ((((oc >> 1) * oc_len) + (j * w_out) + i) << 1) + (oc % 2);
              index_w = (oc * w_len) + (ic * wc_len) + (wj * ks) + (i + wi);

              popcount_res = __popcount(~(weights[index_w] ^ input[index_i]));
              *(((uint16_t *)output) + index_o) += (2 * popcount_res - 32);
              // puthex(wi);
              // putchar(' ');
              // puthex(wj);
              // putchar(' ');
              // puthex(ic);
              // putchar(' ');
              // puthex(oc);
              // putchar(' ');
              // puthex(j);
              // putchar(' ');
              // puthex(i);
              // putchar(' ');
              // putchar('-');
              // putchar('-');
              // putchar('-');
              // putchar(' ');
              // puthex(index_i);
              // putchar(' ');
              // puthex(index_o);
              // putchar(' ');
              // puthex(index_w);
              // putchar('\n');
            }
          }
        }
      }
    }
  }

  // for (int i = 0; i < output_size; i++) {
  //   puthex(output[i]);
  //   putchar('\n');
  // }

  return 0;
}