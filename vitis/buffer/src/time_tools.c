#include "xtime_l.h"
#include "time_tools.h"
uint64_t get_time_us(void)
{
	XTime t;

	XTime_GetTime(&t);
	return (uint64_t)t * 1000000U / COUNTS_PER_SECOND;
}

uint64_t get_time_ms(void)
{
	return get_time_us() / 1000U;
}

