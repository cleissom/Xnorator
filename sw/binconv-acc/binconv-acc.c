#include <stdint.h>

#include "../common/test-data.h"
#include "simple_system_common.h"

uint32_t w_in = 9;
uint32_t h_in = 9;
uint32_t c_in = 512;
uint32_t c_out = 512;
uint32_t padding = 0;
uint32_t ks = 3;

int main(int argc, char **argv) {
  DEV_WRITE(XNORATOR_BASE + XNORATOR_INPUT_ADDR, input);
  DEV_WRITE(XNORATOR_BASE + XNORATOR_WEIGHT_ADDR, weights);
  DEV_WRITE(XNORATOR_BASE + XNORATOR_OUTPUT_ADDR, output);

  DEV_WRITE(XNORATOR_BASE + XNORATOR_INPUT_WIDTH, w_in);
  DEV_WRITE(XNORATOR_BASE + XNORATOR_INPUT_HEIGHT, h_in);
  DEV_WRITE(XNORATOR_BASE + XNORATOR_INPUT_CHANNEL, c_in);
  DEV_WRITE(XNORATOR_BASE + XNORATOR_OUPUT_CHANNEL, c_out);

  DEV_WRITE(XNORATOR_BASE + XNORATOR_PADDING, padding);
  DEV_WRITE(XNORATOR_BASE + XNORATOR_START, 1);

  while (1) {
    uint32_t test = DEV_READ(XNORATOR_BASE + XNORATOR_DONE, 0);

    if (test != 0) {
      // for (int i = 0; i < output_size; i++) {
      //   puthex(output[i]);
      //   putchar('\n');
      // }
      return 0;
    }
  }
  return 0;
}
