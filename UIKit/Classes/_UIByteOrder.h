#include <inttypes.h>
#include <stddef.h>
#if GNUSTEP
inline uint16_t OSReadLittleInt16(
    volatile void* base,
    size_t offset
)
{
    // FIXME-GNUstep: Assumes we're running on a little-endian system
    return ((uint16_t*)base)[offset/sizeof(uint16_t)];
}

inline uint32_t OSReadLittleInt32(
    volatile void* base,
    size_t offset
)
{
    // FIXME-GNUstep: Assumes we're running on a little-endian system
    return ((uint32_t*)base)[offset/sizeof(uint32_t)];
}

inline uint64_t OSReadLittleInt64(
    volatile void* base,
    size_t offset
)
{
    // FIXME-GNUstep: Assumes we're running on a little-endian system
    return ((uint64_t*)base)[offset/sizeof(uint64_t)];
}
#endif